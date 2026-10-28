import Foundation
import SwiftUI

/// Flash Modes matching MGC 9.8
public enum FlashMode: String, CaseIterable, Identifiable {
    case off = "Off"
    case auto = "Auto"
    case on = "On"
    public var id: String { rawValue }
    public var iconName: String {
        switch self {
        case .off: return "bolt.slash.fill"
        case .auto: return "bolt.badge.a.fill"
        case .on: return "bolt.fill"
        }
    }
}

/// Timer Modes matching MGC 9.8
public enum TimerMode: String, CaseIterable, Identifiable {
    case off = "Off"
    case threeSec = "3s"
    case tenSec = "10s"
    public var id: String { rawValue }
    public var seconds: Int {
        switch self {
        case .off: return 0
        case .threeSec: return 3
        case .tenSec: return 10
        }
    }
}

/// Aspect Ratios matching MGC 9.8
public enum CameraAspectRatio: String, CaseIterable, Identifiable {
    case fourThree = "4:3"
    case sixteenNine = "16:9"
    public var id: String { rawValue }
}

/// RAW capture options
public enum RawOption: String, CaseIterable, Identifiable {
    case jpegOnly = "JPEG"
    case rawPlusJpeg = "RAW + JPEG"
    public var id: String { rawValue }
}

/// Camera Modes in MGC 9.8 Bottom Carousel
public enum MGCMode: String, CaseIterable, Identifiable {
    case nightSight = "NIGHT SIGHT"
    case portrait = "PORTRAIT"
    case photo = "PHOTO"
    case video = "VIDEO"
    case cinematic = "CINEMATIC"
    public var id: String { rawValue }
}

/// Defines the HDR+ processing mode matching Google Camera / MGC 9.8
public enum HDRPlusMode: String, CaseIterable, Identifiable {
    case off = "HDR+ OFF"
    case auto = "HDR+ AUTO"        // 5-7 frames fast burst (MGC standard)
    case enhanced = "HDR+ ENHANCED" // 9-12 frames deep dynamic range
    case nightSight = "NIGHT SIGHT" // 15 frames with MGC motion tracking
    
    public var id: String { rawValue }
    
    public var frameCount: Int {
        switch self {
        case .off: return 1
        case .auto: return 5
        case .enhanced: return 9
        case .nightSight: return 15
        }
    }
    
    public var exposureBiasEV: Float {
        switch self {
        case .off: return 0.0
        case .auto: return -1.0
        case .enhanced: return -1.5
        case .nightSight: return -0.5
        }
    }
}

/// Central State Model for MGC 9.8 Camera App (iPhone 15 Plus)
public class CameraSettings: ObservableObject {
    // Current Active Mode in Carousel
    @Published public var currentMode: MGCMode = .photo
    
    // Quick Settings Drawer Toggles
    @Published public var hdrMode: HDRPlusMode = .auto
    @Published public var flashMode: FlashMode = .off
    @Published public var timerMode: TimerMode = .off
    @Published public var aspectRatio: CameraAspectRatio = .fourThree
    @Published public var rawOption: RawOption = .rawPlusJpeg
    @Published public var motionPhotos: Bool = false
    
    // Zoom Level (iPhone 15 Plus: 0.5x Ultra-wide, 1.0x Wide 48MP, 2.0x Lossless Crop)
    @Published public var zoomFactor: CGFloat = 1.0
    
    // MGC Dual Exposure Viewfinder Sliders
    @Published public var exposureCompensation: Float = 0.0 // EV Shift
    @Published public var shadowIntensity: Float = 0.5      // MGC Shadow tone factor
    
    // MGC ColorTune & CCT White Balance (From Lcom/ColorTune;)
    @Published public var colorTemperatureK: Float = 5350   // 5350K neutral daylight
    @Published public var tintBias: Float = -4.5            // -4.5 cancels iPhone warm/yellow tint
    @Published public var saturationMultiplier: Float = 1.05 // Natural punchy colors
    
    // MGC SharpTuning Parameters (From Lcom/RamPatcher;)
    @Published public var microContrastAmount: Float = 0.38 // Detail enhancement
    @Published public var sharpnessRadius: Float = 2.5
    @Published public var dehazeStrength: Float = 0.15
    
    // MGC 17-Point Tone Spline Knots (BSG defaults extracted from APK):
    @Published public var toneKnots: [Float] = [
        0.000000, 0.011702, 0.050024, 0.105074, 0.172196,
        0.250352, 0.337275, 0.428220, 0.520811, 0.609123,
        0.689614, 0.763617, 0.827763, 0.884501, 0.932369,
        0.971942, 1.000000
    ]
    
    // UI Drawer state
    @Published public var isQuickSettingsOpen: Bool = false
    @Published public var isMGCPreferencesOpen: Bool = false
    
    // Capture and Processing state
    @Published public var isProcessing: Bool = false
    @Published public var processingProgress: Float = 0.0
    @Published public var capturedThumbnail: Data? = nil
    @Published public var shutterSoundEnabled: Bool = true
    @Published public var gridEnabled: Bool = false
    
    public init() {}
}
