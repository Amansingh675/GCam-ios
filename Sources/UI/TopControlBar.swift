import SwiftUI

/// Top status and quick-toggle controls bar matching Google Pixel Camera / MGC 9.8
public struct TopControlBar: View {
    @ObservedObject var settings: CameraSettings
    
    public init(settings: CameraSettings) {
        self.settings = settings
    }
    
    public var body: some View {
        HStack {
            // Flash Indicator
            Button(action: {
                cycleFlash()
            }) {
                Image(systemName: settings.flashMode.iconName)
                    .foregroundColor(settings.flashMode == .off ? .white : .yellow)
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            // Center Dropdown Pill (Opens Google Camera Quick Settings Sheet)
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    settings.isQuickSettingsOpen.toggle()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .rotationEffect(.degrees(settings.isQuickSettingsOpen ? 180 : 0))
                    
                    Text(settings.hdrMode.rawValue)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                    
                    if settings.timerMode != .off {
                        Text("• \(settings.timerMode.rawValue)")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.yellow)
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.60))
                )
                .overlay(
                    Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
            }
            
            Spacer()
            
            // Settings Gear Icon (Opens BSG MGC Preferences directly)
            Button(action: {
                settings.isMGCPreferencesOpen = true
            }) {
                Image(systemName: "gearshape.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }
    
    private func cycleFlash() {
        switch settings.flashMode {
        case .off: settings.flashMode = .auto
        case .auto: settings.flashMode = .on
        case .on: settings.flashMode = .off
        }
    }
}
