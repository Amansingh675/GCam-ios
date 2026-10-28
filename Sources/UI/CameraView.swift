import SwiftUI

/// Complete MGC 9.8 Camera Viewfinder for iPhone 15 Plus
public struct CameraView: View {
    @StateObject private var settings = CameraSettings()
    @StateObject private var cameraManager = CameraManager.shared
    
    @State private var showDualSliders: Bool = false
    @State private var focusPoint: CGPoint? = nil
    @State private var sliderDismissTask: DispatchWorkItem? = nil
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            // 1. Live Camera Viewfinder
            if cameraManager.permissionGranted {
                ZStack {
                    CameraPreviewView(session: cameraManager.captureSession)
                        .aspectRatio(settings.aspectRatio == .fourThree ? 3.0/4.0 : 9.0/16.0, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                        // Grid Overlay
                        .overlay(
                            Group {
                                if settings.gridEnabled {
                                    GridOverlay()
                                        .clipShape(RoundedRectangle(cornerRadius: 24))
                                }
                            }
                        )
                    
                    // Zoom Switcher (.5, 1x, 2) floating at bottom of viewfinder
                    VStack {
                        Spacer()
                        ZoomControlBar(settings: settings) { factor in
                            cameraManager.setZoomFactor(factor)
                        }
                        .padding(.bottom, 16)
                    }
                }
                .padding(.top, 48)
                .padding(.bottom, 140)
                .onTapGesture { location in
                    handleViewfinderTap(at: location)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("Camera Access Required")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Please grant camera permission in iOS Settings to run MGC HDR+.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
            
            // 2. Focus Reticle on Tap (Pulsing Yellow Circle with Ticks)
            if let point = focusPoint {
                FocusIndicatorView()
                    .position(point)
                    .transition(.opacity)
            }
            
            // 3. MGC Dual Exposure Sliders (Brightness EV + Shadow Contrast)
            if showDualSliders {
                DualExposureSlider(settings: settings, isVisible: $showDualSliders)
                    .padding(.bottom, 160)
            }
            
            // 4. Overlays & Top/Bottom Bars
            VStack {
                // Top Control Bar
                TopControlBar(settings: settings)
                
                Spacer()
                
                // Processing Status Badge ("Hold still... Processing HDR+")
                if settings.isProcessing {
                    HStack(spacing: 8) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                        
                        Text(settings.hdrMode == .nightSight ? "Night Sight: Hold still..." : "Processing HDR+ (Metal Fusion)...")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(Color.black.opacity(0.75))
                    )
                    .overlay(
                        Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                // Bottom Mode Carousel (NIGHT SIGHT | PORTRAIT | PHOTO | VIDEO | CINEMATIC)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 24) {
                        ForEach(MGCMode.allCases) { mode in
                            Button(action: {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                    settings.currentMode = mode
                                    if mode == .nightSight {
                                        settings.hdrMode = .nightSight
                                    } else {
                                        settings.hdrMode = .auto
                                    }
                                }
                            }) {
                                Text(mode.rawValue)
                                    .font(.system(size: 13, weight: settings.currentMode == mode ? .bold : .medium, design: .rounded))
                                    .foregroundColor(settings.currentMode == mode ? Color(red: 0.95, green: 0.82, blue: 0.40) : .white.opacity(0.6))
                                    .padding(.vertical, 6)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 10)
                
                // Shutter Button Bar (Gallery Thumbnail | Shutter Arc | Flip)
                ShutterButton(settings: settings) {
                    cameraManager.captureHDRPlus(settings: settings)
                }
            }
            
            // 5. Swipe-Down Quick Settings Drawer
            if settings.isQuickSettingsOpen {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            settings.isQuickSettingsOpen = false
                        }
                    }
                
                VStack {
                    QuickSettingsDrawer(settings: settings, isPresented: $settings.isQuickSettingsOpen)
                    Spacer()
                }
            }
        }
        .statusBar(hidden: true)
        .sheet(isPresented: $settings.isMGCPreferencesOpen) {
            MGCPreferencesView(settings: settings)
        }
    }
    
    // Tap to focus, expose, and display dual sliders
    private func handleViewfinderTap(at location: CGPoint) {
        focusPoint = location
        cameraManager.focusAndExpose(at: location)
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            showDualSliders = true
        }
        
        // Auto-dismiss focus ring
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeOut(duration: 0.3)) {
                focusPoint = nil
            }
        }
        
        // Auto-dismiss sliders after 5 seconds
        sliderDismissTask?.cancel()
        let task = DispatchWorkItem {
            withAnimation(.easeOut(duration: 0.4)) {
                showDualSliders = false
            }
        }
        sliderDismissTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: task)
    }
}

/// 3x3 Rule of Thirds Grid Overlay
struct GridOverlay: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            Path { path in
                // Horizontal lines
                path.move(to: CGPoint(x: 0, y: h / 3))
                path.addLine(to: CGPoint(x: w, y: h / 3))
                path.move(to: CGPoint(x: 0, y: 2 * h / 3))
                path.addLine(to: CGPoint(x: w, y: 2 * h / 3))
                
                // Vertical lines
                path.move(to: CGPoint(x: w / 3, y: 0))
                path.addLine(to: CGPoint(x: w / 3, y: h))
                path.move(to: CGPoint(x: 2 * w / 3, y: 0))
                path.addLine(to: CGPoint(x: 2 * w / 3, y: h))
            }
            .stroke(Color.white.opacity(0.25), lineWidth: 0.8)
        }
    }
}

/// Minimalist GCam Focus Ring with Tick Marks
struct FocusIndicatorView: View {
    @State private var isPulsing: Bool = false
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.yellow.opacity(0.9), lineWidth: 1.5)
                .frame(width: isPulsing ? 64 : 76, height: isPulsing ? 64 : 76)
            
            // Four tick marks
            ForEach(0..<4) { i in
                Rectangle()
                    .fill(Color.yellow)
                    .frame(width: 1.5, height: 6)
                    .offset(y: -36)
                    .rotationEffect(.degrees(Double(i) * 90))
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) {
                isPulsing = true
            }
        }
    }
}

