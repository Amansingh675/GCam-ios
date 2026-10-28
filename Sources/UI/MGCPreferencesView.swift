import SwiftUI

/// Complete MGC 9.8 / BSG Preferences Screen with RAM Patcher & ColorTune
public struct MGCPreferencesView: View {
    @ObservedObject var settings: CameraSettings
    @Environment(\.presentationMode) var presentationMode
    
    public init(settings: CameraSettings) {
        self.settings = settings
    }
    
    public var body: some View {
        NavigationView {
            Form {
                // Section 1: BSG MGC RAM Patcher (Libpatcher)
                Section(header: Label("BSG RAM Patcher (Libpatcher)", systemImage: "cpu.fill")) {
                    NavigationLink(destination: ToneCurveEditorView(settings: settings)) {
                        HStack {
                            Image(systemName: "waveform.path")
                                .foregroundColor(.yellow)
                            Text("17-Point Tone Curve Spline")
                            Spacer()
                            Text("MGC Standard")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("SharpTuning (Micro-Contrast)")
                            Spacer()
                            Text(String(format: "%.2f", settings.microContrastAmount))
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $settings.microContrastAmount, in: 0.1...0.8, step: 0.02)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Sharpness Radius")
                            Spacer()
                            Text(String(format: "%.1f px", settings.sharpnessRadius))
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $settings.sharpnessRadius, in: 1.0...4.0, step: 0.1)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Dehaze Filter")
                            Spacer()
                            Text(String(format: "%.2f", settings.dehazeStrength))
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $settings.dehazeStrength, in: 0.0...0.5, step: 0.05)
                    }
                }
                
                // Section 2: MGC ColorTune (CCT & Transform)
                Section(header: Label("MGC ColorTune (CCT & Saturation)", systemImage: "paintpalette.fill")) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Color Temperature (CCT)")
                            Spacer()
                            Text("\(Int(settings.colorTemperatureK)) K")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $settings.colorTemperatureK, in: 4500...6500, step: 50)
                        Text("Daylight baseline neutralizes iPhone warm yellow cast.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Tint Bias (Magenta vs Green)")
                            Spacer()
                            Text(String(format: "%+.1f", settings.tintBias))
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $settings.tintBias, in: -10.0...10.0, step: 0.5)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Saturation Multiplier")
                            Spacer()
                            Text(String(format: "%.2fx", settings.saturationMultiplier))
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $settings.saturationMultiplier, in: 0.8...1.4, step: 0.02)
                    }
                }
                
                // Section 3: Computational HDR+ Frame Burst
                Section(header: Label("HDR+ Frame Burst (A16 Bionic)", systemImage: "square.stack.3d.down.right.fill")) {
                    HStack {
                        Text("HDR+ Auto Burst")
                        Spacer()
                        Text("\(HDRPlusMode.auto.frameCount) Frames (Zero Shutter Lag)")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    HStack {
                        Text("HDR+ Enhanced Burst")
                        Spacer()
                        Text("\(HDRPlusMode.enhanced.frameCount) Frames (Deep Dynamic Range)")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    HStack {
                        Text("Night Sight Burst")
                        Spacer()
                        Text("\(HDRPlusMode.nightSight.frameCount) Frames (Motion Tracked)")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                
                // Section 4: General Settings
                Section(header: Text("General")) {
                    Toggle("Camera Shutter Sounds", isOn: $settings.shutterSoundEnabled)
                    Toggle("Grid (Rule of Thirds)", isOn: $settings.gridEnabled)
                    
                    HStack {
                        Text("Device Interface")
                        Spacer()
                        Text("Pixel 9 Pro (iPhone 15 Plus Tuned)")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    
                    HStack {
                        Text("Sensor Resolution")
                        Spacer()
                        Text("48MP Quad-Bayer (Main 24mm f/1.6)")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                
                // Section 5: About MGC
                Section(header: Text("About")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Google Camera 9.8 (MGC Port)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("Reverse-engineered from MGC_9.8.102_V0_MGC_gcamapk.io.apk for Apple iPhone 15 Plus.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("MGC Settings")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .preferredColorScheme(.dark)
    }
}

/// Visual 17-Point Spline Knot Inspector
struct ToneCurveEditorView: View {
    @ObservedObject var settings: CameraSettings
    
    var body: some View {
        List {
            Section(header: Text("17-Point Tone Curve Graph")) {
                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height
                    
                    Path { path in
                        for (i, val) in settings.toneKnots.enumerated() {
                            let x = (CGFloat(i) / 16.0) * w
                            let y = (1.0 - CGFloat(val)) * h
                            if i == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(Color.yellow, lineWidth: 2.5)
                }
                .frame(height: 180)
                .background(Color.black.opacity(0.3))
                .cornerRadius(12)
                .padding(.vertical, 8)
                
                Text("Exact 17 knots extracted from MGC RamPatcher (`tone0` to `tone16`). Deep shadows remain low while highlights compress smoothly.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section(header: Text("Knot Values")) {
                ForEach(0..<settings.toneKnots.count, id: \.self) { i in
                    HStack {
                        Text("tone\(i)")
                            .font(.system(.body, design: .monospaced))
                        Spacer()
                        Text(String(format: "%.6f", settings.toneKnots[i]))
                            .foregroundColor(.yellow)
                            .font(.system(.body, design: .monospaced))
                    }
                }
            }
        }
        .navigationTitle("Tone Curve")
    }
}
