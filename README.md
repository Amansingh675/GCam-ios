# GCam for iOS (iPhone 15 Plus) - Calibrated with MGC 9.8 (BSG)

A native iOS computational photography app replicating **Google Camera 9.8 (MGC / BSG)** pipeline, exact tone curves, and ColorTune color science for the **iPhone 15 Plus** (Apple A16 Bionic 48MP Quad-Bayer sensor).

---

## 🔍 Reverse-Engineered Tuning from `MGC_9.8.102_V0_MGC_gcamapk.io.apk`

The color science and computational algorithms in this project are calibrated directly from the disassembled Dalvik bytecode and native shaders of BSG's MGC 9.8 APK:

### 1. Exact 17-Point Tone Curve Spline
Google Camera's proprietary tone curve extracted from `Lcom/RamPatcher;` (`dG9uZTB` to `dG9uZTE2`):
| Knot | Value | Description |
| :--- | :--- | :--- |
| **tone0** | `0.000000` | Anchored absolute black point (no gray/washed-out shadows) |
| **tone1** | `0.011702` | Low shadow compression |
| **tone2** | `0.050024` | Shadow gradient start |
| **tone3** | `0.105074` | Deep shadow tone |
| **tone4** | `0.172196` | Mid-shadow lift |
| **tone5** | `0.250352` | Low midtone |
| **tone6** | `0.337275` | Midtone contrast knee |
| **tone7** | `0.428220` | Midtone rise |
| **tone8** | `0.520811` | Center luminance point |
| **tone9** | `0.609123` | High midtone |
| **tone10** | `0.689614` | Highlight shoulder |
| **tone11** | `0.763617` | Highlight roll-off start |
| **tone12** | `0.827763` | Soft-knee highlight compression |
| **tone13** | `0.884501` | Sky preservation zone |
| **tone14** | `0.932369` | Near-white compression |
| **tone15** | `0.971942` | Highlight retention |
| **tone16** | `1.000000` | Specular white peak |

Evaluated on GPU using **Cubic Catmull-Rom Hermite Splines** in `GCamShaders.metal`.

### 2. MGC ColorTune Calibration Matrix (CCM)
Extracted from `Lcom/ColorTune;` (`pref_customCCT1`–`9` and `pref_satCCT`):
* Neutralizes iPhone 15's default warm/yellow skin cast.
* Calibrated daylight illuminant at **5350K** with **-4.5 magenta tint bias**.
* Preserves true deep blues in sky and natural emerald greens in foliage without oversaturation.

### 3. SharpTuning Micro-Contrast
* Calibrated from `SharpTuningDetails` and `BracketedSharpnessThreshold`.
* Laplacian high-pass filter with noise thresholding (`smoothstep(0.012, 0.14, highPassMag)`) to deliver crisp textures without artificial edge halos.

---

## 📁 Project Structure

```
GCam-iOS/
├── MGC_9.8.102_V0_MGC_gcamapk.io.apk  # Reference BSG GCam APK
├── Package.swift                       # Swift Package manifest (iOS 17+)
├── Info.plist                          # Camera & Photo Library permissions
├── Sources/
│   ├── GCamApp.swift                   # App main entry
│   ├── Models/
│   │   └── CameraSettings.swift        # MGC calibrated state and knots
│   ├── Core/
│   │   ├── CameraManager.swift         # AVCaptureSession, RAW burst buffer
│   │   └── HDRFusionEngine.swift       # Metal multi-frame fusion engine
│   ├── Shaders/
│   │   └── GCamShaders.metal           # MGC 17-point spline & ColorTune kernels
│   └── UI/
│       ├── CameraView.swift            # Main viewfinder with tap-to-focus
│       ├── CameraPreviewView.swift     # Native AVCaptureVideoPreviewLayer
│       ├── DualExposureSlider.swift    # MGC Brightness & Shadow sliders
│       ├── TopControlBar.swift         # HDR+ mode pill & tuning modal
│       └── ShutterButton.swift         # Shutter with radial progress animation
└── README.md
```

---

## 🚀 Running on iPhone 15 Plus

1. Open Xcode on your Mac.
2. Create a new iOS App project (Swift & SwiftUI) or open `GCam-iOS`.
3. Add the `Sources`, `Shaders`, and `Info.plist` files.
4. Plug in your iPhone 15 Plus via USB-C.
5. Set Developer Mode to ON under **Settings > Privacy & Security > Developer Mode**.
6. Press **Cmd + R** to build and run!
