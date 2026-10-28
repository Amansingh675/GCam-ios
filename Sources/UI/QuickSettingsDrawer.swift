import SwiftUI

/// Google Camera 9.8 Swipe-Down Quick Settings Sheet (Material 3)
public struct QuickSettingsDrawer: View {
    @ObservedObject var settings: CameraSettings
    @Binding var isPresented: Bool
    
    public init(settings: CameraSettings, isPresented: Binding<Bool>) {
        self.settings = settings
        self._isPresented = isPresented
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            // Drag handle
            Capsule()
                .fill(Color.white.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 10)
            
            VStack(spacing: 16) {
                // 1. Flash Row
                HStack {
                    Label("Flash", systemImage: "bolt.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    HStack(spacing: 6) {
                        ForEach(FlashMode.allCases) { mode in
                            PillOptionButton(
                                title: mode.rawValue,
                                isSelected: settings.flashMode == mode,
                                action: { settings.flashMode = mode }
                            )
                        }
                    }
                }
                
                Divider().background(Color.white.opacity(0.1))
                
                // 2. HDR+ Mode Row
                HStack {
                    Label("HDR+ Mode", systemImage: "camera.metering.matrix")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    HStack(spacing: 6) {
                        ForEach([HDRPlusMode.off, HDRPlusMode.auto, HDRPlusMode.enhanced]) { mode in
                            PillOptionButton(
                                title: mode == .enhanced ? "Enhanced" : (mode == .auto ? "Auto" : "Off"),
                                isSelected: settings.hdrMode == mode,
                                action: { settings.hdrMode = mode }
                            )
                        }
                    }
                }
                
                Divider().background(Color.white.opacity(0.1))
                
                // 3. RAW / DNG Row
                HStack {
                    Label("RAW / DNG", systemImage: "doc.viewfinder.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    HStack(spacing: 6) {
                        ForEach(RawOption.allCases) { opt in
                            PillOptionButton(
                                title: opt.rawValue,
                                isSelected: settings.rawOption == opt,
                                action: { settings.rawOption = opt }
                            )
                        }
                    }
                }
                
                Divider().background(Color.white.opacity(0.1))
                
                // 4. Timer Row
                HStack {
                    Label("Timer", systemImage: "timer")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    HStack(spacing: 6) {
                        ForEach(TimerMode.allCases) { mode in
                            PillOptionButton(
                                title: mode.rawValue,
                                isSelected: settings.timerMode == mode,
                                action: { settings.timerMode = mode }
                            )
                        }
                    }
                }
                
                Divider().background(Color.white.opacity(0.1))
                
                // 5. Ratio Row
                HStack {
                    Label("Ratio", systemImage: "aspectratio.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    HStack(spacing: 6) {
                        ForEach(CameraAspectRatio.allCases) { ratio in
                            PillOptionButton(
                                title: ratio.rawValue,
                                isSelected: settings.aspectRatio == ratio,
                                action: { settings.aspectRatio = ratio }
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            
            // "More Settings" Pill (Opens BSG MGC Preferences)
            Button(action: {
                withAnimation {
                    isPresented = false
                    settings.isMGCPreferencesOpen = true
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 15))
                    Text("More settings")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(red: 0.90, green: 0.88, blue: 0.82)) // M3 subtle beige/gold
                )
                .padding(.horizontal, 20)
                .padding(.top, 4)
            }
            .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.13)) // Material 3 Surface Dark
                .shadow(color: .black.opacity(0.6), radius: 20, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal, 12)
        .padding(.top, 48)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

/// Material 3 Pill Option Button
struct PillOptionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let gen = UIImpactFeedbackGenerator(style: .light)
            gen.impactOccurred()
            action()
        }) {
            Text(title)
                .font(.system(size: 12, weight: isSelected ? .bold : .medium, design: .rounded))
                .foregroundColor(isSelected ? .black : .white.opacity(0.8))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.white : Color.white.opacity(0.12))
                )
        }
    }
}
