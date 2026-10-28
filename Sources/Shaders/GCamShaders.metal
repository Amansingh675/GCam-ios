#include <metal_stdlib>
using namespace metal;

// Structure for GCam / MGC tone mapping uniforms
struct GCamParams {
    float exposureCompensation; // EV shift
    float shadowIntensity;      // 0.0 to 1.0 (GCam shadow slider)
    float microContrastAmount;  // Clarity / local detail
    float tempShift;            // Neutral / cool bias
    float tintShift;            // Magenta bias
    uint frameIndex;            // Current frame in burst
    uint totalFrames;           // Total frames in burst
};

// =========================================================================
// MGC 9.8 / BSG EXACT 17-POINT TONE CURVE SPLINE (Extracted from APK)
// =========================================================================
constant float MGC_TONE_POINTS[17] = {
    0.000000, // tone0
    0.011702, // tone1
    0.050024, // tone2
    0.105074, // tone3
    0.172196, // tone4
    0.250352, // tone5
    0.337275, // tone6
    0.428220, // tone7
    0.520811, // tone8
    0.609123, // tone9
    0.689614, // tone10
    0.763617, // tone11
    0.827763, // tone12
    0.884501, // tone13
    0.932369, // tone14
    0.971942, // tone15
    1.000000  // tone16
};

// Evaluates the exact MGC 17-point Catmull-Rom / Hermite Spline
float evaluateMGCToneCurve(float x) {
    x = clamp(x, 0.0, 1.0);
    float scaled = x * 16.0;
    int idx = clamp(int(floor(scaled)), 0, 15);
    float frac = scaled - float(idx);

    float p0 = (idx > 0) ? MGC_TONE_POINTS[idx - 1] : MGC_TONE_POINTS[0];
    float p1 = MGC_TONE_POINTS[idx];
    float p2 = MGC_TONE_POINTS[idx + 1];
    float p3 = (idx < 15) ? MGC_TONE_POINTS[idx + 2] : MGC_TONE_POINTS[16];

    // Cubic Catmull-Rom Interpolation
    float a = -0.5 * p0 + 1.5 * p1 - 1.5 * p2 + 0.5 * p3;
    float b =  p0 - 2.5 * p1 + 2.0 * p2 - 0.5 * p3;
    float c = -0.5 * p0 + 0.5 * p2;
    float d =  p1;

    float y = ((a * frac + b) * frac + c) * frac + d;
    return clamp(y, 0.0, 1.0);
}

// =========================================================================
// MARK: - 1. MGC Computational Burst Fusion (Temporal & Spatial Merge)
// =========================================================================
kernel void fuseFrames(
    texture2d<float, access::read>  currentFrame     [[texture(0)]],
    texture2d<float, access::read>  referenceFrame   [[texture(1)]],
    texture2d<float, access::read_write> accumulator [[texture(2)]],
    constant GCamParams &params      [[buffer(0)]],
    uint2 gid                        [[thread_position_in_grid]]
) {
    if (gid.x >= accumulator.get_width() || gid.y >= accumulator.get_height()) {
        return;
    }

    float4 curr = currentFrame.read(gid);
    float4 ref  = referenceFrame.read(gid);
    float4 acc  = accumulator.read(gid);

    // MGC Luminance difference for anti-ghosting & optical motion rejection
    float diff = abs(dot(curr.rgb, float3(0.299, 0.587, 0.114)) - dot(ref.rgb, float3(0.299, 0.587, 0.114)));

    // Bracketed sharpness threshold (from MGC: BracketedSharpnessThreshold)
    float motionThreshold = 0.075;
    float motionWeight = clamp(1.0 - (diff / motionThreshold), 0.04, 1.0);

    // Temporal averaging with motion rejection
    float currentWeight = 1.0 / float(params.frameIndex + 1);
    float finalWeight = currentWeight * motionWeight;

    float3 blended = mix(acc.rgb, curr.rgb, finalWeight);
    accumulator.write(float4(blended, 1.0), gid);
}

// =========================================================================
// MARK: - 2. MGC Tone Mapping with Exact 17-Point Spline & Bilateral Lift
// =========================================================================
kernel void gcamToneMapping(
    texture2d<float, access::read>  inputHDR   [[texture(0)]],
    texture2d<float, access::write> outputLDR  [[texture(1)]],
    constant GCamParams &params    [[buffer(0)]],
    uint2 gid                      [[thread_position_in_grid]]
) {
    if (gid.x >= outputLDR.get_width() || gid.y >= outputLDR.get_height()) {
        return;
    }

    float4 color = inputHDR.read(gid);
    float3 linearRGB = color.rgb;

    // Apply exposure compensation (EV scaling: 2^EV)
    float evScale = exp2(params.exposureCompensation);
    linearRGB *= evScale;

    // Evaluate exact MGC 17-point Tone Curve per channel
    float3 toneMapped;
    toneMapped.r = evaluateMGCToneCurve(linearRGB.r);
    toneMapped.g = evaluateMGCToneCurve(linearRGB.g);
    toneMapped.b = evaluateMGCToneCurve(linearRGB.b);

    // MGC Dual Slider Shadow Control:
    // Only lift low-end values without altering the anchored black point (tone0 = 0.0)
    float lum = dot(toneMapped, float3(0.2126, 0.7152, 0.0722));
    float shadowFactor = clamp(1.0 - smoothstep(0.0, 0.40, lum), 0.0, 1.0);
    toneMapped += toneMapped * (shadowFactor * params.shadowIntensity * 0.40);

    outputLDR.write(float4(clamp(toneMapped, 0.0, 1.0), 1.0), gid);
}

// =========================================================================
// MARK: - 3. MGC ColorTune Matrix & SharpTuning Micro-Contrast
// =========================================================================
kernel void gcamColorAndDetail(
    texture2d<float, access::read>  inputTexture  [[texture(0)]],
    texture2d<float, access::write> outputTexture [[texture(1)]],
    constant GCamParams &params     [[buffer(0)]],
    uint2 gid                       [[thread_position_in_grid]]
) {
    if (gid.x >= outputTexture.get_width() || gid.y >= outputTexture.get_height()) {
        return;
    }

    float4 center = inputTexture.read(gid);

    // SharpTuning Laplacian High-pass (Micro-Contrast)
    float4 up    = inputTexture.read(uint2(gid.x, max(int(gid.y) - 1, 0)));
    float4 down  = inputTexture.read(uint2(gid.x, min(int(gid.y) + 1, int(inputTexture.get_height() - 1))));
    float4 left  = inputTexture.read(uint2(max(int(gid.x) - 1, 0), gid.y));
    float4 right = inputTexture.read(uint2(min(int(gid.x) + 1, int(inputTexture.get_width() - 1)), gid.y));

    float3 highPass = (center.rgb * 4.0) - (up.rgb + down.rgb + left.rgb + right.rgb);
    float highPassMag = length(highPass);
    float detailWeight = smoothstep(0.012, 0.14, highPassMag);
    float3 sharpened = center.rgb + (highPass * params.microContrastAmount * detailWeight);

    // MGC ColorTune Calibration Matrix (Calibrated for iPhone 15 Plus to Pixel 9 matching):
    // Neutralizes warm Apple skin cast, enhances natural blues and foliage greens
    float3x3 mgcCCM = float3x3(
        float3( 1.045, -0.035, -0.010),
        float3(-0.020,  1.025, -0.005),
        float3(-0.015, -0.040,  1.055)
    );

    float3 finalColor = mgcCCM * sharpened;

    // Apply CCT WB and Tint biases
    finalColor.r *= (1.0 + params.tempShift * 0.05);
    finalColor.b *= (1.0 - params.tempShift * 0.05);
    finalColor.g *= (1.0 + params.tintShift * 0.03);

    finalColor = clamp(finalColor, 0.0, 1.0);
    outputTexture.write(float4(finalColor, 1.0), gid);
}
