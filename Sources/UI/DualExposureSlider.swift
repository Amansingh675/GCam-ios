import SwiftUI

/// Google Camera Signature Dual Exposure Sliders
/// 1. Top slider: Overall Scene Brightness (EV Compensation)
/// 2. Bottom slider: Shadows / Contrast (Black point lift)
public struct DualExposureSlider: View {
    @ObservedObject var settings: CameraSettings
    @Binding var isVisible: Bool
    
    public init(settings: CameraSettings, isVisible: Binding<Bool>) {
        self.settings = settings
        self._isVisible = isVisible
    }
    
    public var body: some View {
        HStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 28) {
                // 1. Brightness Slider (EV)
                VStack(spacing: 8) {
                    Image(systemName: "sun.max.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 15, weight: .bold))
                    
                    CustomVerticalSlider(
                        value: $settings.exposureCompensation,
                        range: -2.0...2.0,
                        step: 0.1
                    )
                    .frame(width: 36, height: 130)
                    
                    Text(String(format: "%+.1f EV", settings.exposureCompensation))
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                }
                
                // 2. Shadows / Tone Mapping Contrast Slider
                VStack(spacing: 8) {
                    Image(systemName: "shadow")
                        .foregroundColor(.cyan)
                        .font(.system(size: 15, weight: .bold))
                    
                    CustomVerticalSlider(
                        value: $settings.shadowIntensity,
                        range: 0.0...1.0,
                        step: 0.05
                    )
                    .frame(width: 36, height: 130)
                    
                    Text(String(format: "%.0f%%", settings.shadowIntensity * 100))
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.black.opacity(0.65))
                    .blur(radius: 0.5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .padding(.trailing, 16)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}

/// Minimalist vertical slider mimicking Google Camera's tactile slider
struct CustomVerticalSlider: View {
    @Binding var value: Float
    let range: ClosedRange<Float>
    let step: Float
    
    var body: some View {
        GeometryReader { geo in
            let height = geo.size.height
            let percentage = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
            
            ZStack(alignment: .bottom) {
                // Background Track
                Capsule()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 4)
                
                // Active Fill
                Capsule()
                    .fill(Color.white)
                    .frame(width: 4, height: max(height * percentage, 4))
                
                // Drag Thumb Handle
                Circle()
                    .fill(Color.white)
                    .frame(width: 22, height: 22)
                    .shadow(color: .black.opacity(0.4), radius: 4, y: 2)
                    .offset(y: -height * percentage + 11)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let locationY = max(0, min(height, height - gesture.location.y))
                        let newPercent = Float(locationY / height)
                        let rawValue = range.lowerBound + newPercent * (range.upperBound - range.lowerBound)
                        value = round(rawValue / step) * step
                    }
            )
        }
    }
}
