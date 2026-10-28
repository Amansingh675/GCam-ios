import SwiftUI

/// Google Camera 9.8 Zoom Switcher for iPhone 15 Plus: .5x, 1x, 2x (Lossless In-Sensor Zoom)
public struct ZoomControlBar: View {
    @ObservedObject var settings: CameraSettings
    let onZoomSelected: (CGFloat) -> Void
    
    let zoomLevels: [(title: String, factor: CGFloat)] = [
        (".5", 0.5),
        ("1x", 1.0),
        ("2", 2.0)
    ]
    
    public init(settings: CameraSettings, onZoomSelected: @escaping (CGFloat) -> Void) {
        self.settings = settings
        self.onZoomSelected = onZoomSelected
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            ForEach(zoomLevels, id: \.title) { zoom in
                let isSelected = abs(settings.zoomFactor - zoom.factor) < 0.1
                
                Button(action: {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) {
                        settings.zoomFactor = zoom.factor
                        triggerHapticFeedback()
                        onZoomSelected(zoom.factor)
                    }
                }) {
                    Text(zoom.title)
                        .font(.system(size: isSelected ? 13 : 12, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? .black : .white)
                        .frame(width: isSelected ? 36 : 30, height: isSelected ? 36 : 30)
                        .background(
                            Circle()
                                .fill(isSelected ? Color.white : Color.clear)
                        )
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.55))
        )
        .overlay(
            Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.8)
        )
    }
    
    private func triggerHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}
