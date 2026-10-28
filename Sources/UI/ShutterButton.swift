import SwiftUI

/// GCam Signature Shutter Button with Circular Progress & Burst Animation
public struct ShutterButton: View {
    @ObservedObject var settings: CameraSettings
    let onCapture: () -> Void
    
    public init(settings: CameraSettings, onCapture: @escaping () -> Void) {
        self.settings = settings
        self.onCapture = onCapture
    }
    
    public var body: some View {
        HStack(spacing: 40) {
            // 1. Last Captured Photo Thumbnail
            Group {
                if let data = settings.capturedThumbnail, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 52, height: 52)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: 2))
                } else {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 52, height: 52)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.white.opacity(0.6))
                        )
                }
            }
            .frame(width: 60)
            
            // 2. Main Shutter Button with Radial Progress
            ZStack {
                // Background Outer Ring
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 4)
                    .frame(width: 82, height: 82)
                
                // Progress Arc during Burst & Metal Stacking
                if settings.isProcessing {
                    Circle()
                        .trim(from: 0.0, to: CGFloat(settings.processingProgress))
                        .stroke(
                            LinearGradient(
                                colors: [.cyan, .yellow, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 4.5, lineCap: .round)
                        )
                        .frame(width: 82, height: 82)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.1), value: settings.processingProgress)
                }
                
                // Inner Shutter Button
                Button(action: {
                    guard !settings.isProcessing else { return }
                    triggerHapticFeedback()
                    onCapture()
                }) {
                    Circle()
                        .fill(settings.isProcessing ? Color.gray.opacity(0.8) : Color.white)
                        .frame(
                            width: settings.isProcessing ? 60 : 68,
                            height: settings.isProcessing ? 60 : 68
                        )
                        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: settings.isProcessing)
                }
                .disabled(settings.isProcessing)
            }
            
            // 3. Camera Switcher / Mode Placeholder
            Button(action: {}) {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 52, height: 52)
                    .overlay(
                        Image(systemName: "camera.rotate.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                    )
            }
            .frame(width: 60)
        }
        .padding(.bottom, 24)
    }
    
    private func triggerHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
}
