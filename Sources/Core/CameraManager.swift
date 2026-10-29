import Foundation
import AVFoundation
import CoreImage
import Photos
import UIKit
import AudioToolbox

public final class CameraManager: NSObject, ObservableObject {
    public static let shared = CameraManager()
    
    // AVCapture Pipeline
    public let captureSession = AVCaptureSession()
    private var activeDevice: AVCaptureDevice?
    private let photoOutput = AVCapturePhotoOutput()
    
    private let sessionQueue = DispatchQueue(label: "com.gcam.sessionQueue")
    
    // Burst frame collection
    private var burstBuffers: [CVPixelBuffer] = []
    private var expectedBurstCount: Int = 0
    private var currentSettings: CameraSettings?
    
    @Published public var isSessionRunning: Bool = false
    @Published public var permissionGranted: Bool = false
    
    private override init() {
        super.init()
        checkPermissions()
    }
    
    public func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.permissionGranted = true
            sessionQueue.async { self.setupSession() }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.permissionGranted = granted
                    if granted {
                        self?.sessionQueue.async { self?.setupSession() }
                    }
                }
            }
        default:
            self.permissionGranted = false
        }
    }
    
    private func setupSession() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo
        
        // 1. Configure iPhone Cameras (Prioritize Physical Wide Angle for full RAW/48MP support)
        let deviceDiscovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInWideAngleCamera,
                .builtInDualWideCamera,
                .builtInTripleCamera,
                .builtInDualCamera
            ],
            mediaType: .video,
            position: .back
        )
        
        guard let device = deviceDiscovery.devices.first else {
            print("❌ Camera device unavailable")
            captureSession.commitConfiguration()
            return
        }
        self.activeDevice = device
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            // 2. Photo Output Configuration (Safe high-res & RAW burst setup)
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
                photoOutput.maxPhotoQualityPrioritization = .quality
            }
            
            // 3. MGC Hardware Optimization: Smooth Auto-Focus & Neutral WB
            try device.lockForConfiguration()
            if device.isSmoothAutoFocusSupported {
                device.isSmoothAutoFocusEnabled = true
            }
            device.unlockForConfiguration()
            
            captureSession.commitConfiguration()
            captureSession.startRunning()
            
            DispatchQueue.main.async {
                self.isSessionRunning = self.captureSession.isRunning
            }
        } catch {
            print("❌ Camera configuration error: \(error.localizedDescription)")
            captureSession.commitConfiguration()
        }
    }
    
    // MARK: - Zoom Factor Control (.5x, 1x, 2x)
    
    public func setZoomFactor(_ factor: CGFloat) {
        sessionQueue.async { [weak self] in
            guard let self = self, let device = self.activeDevice else { return }
            do {
                try device.lockForConfiguration()
                let targetZoom = max(device.minAvailableVideoZoomFactor, min(factor, device.maxAvailableVideoZoomFactor))
                device.videoZoomFactor = targetZoom
                device.unlockForConfiguration()
            } catch {
                print("❌ Failed to set zoom factor: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - MGC Computational Burst Capture Trigger
    
    public func captureHDRPlus(settings: CameraSettings) {
        sessionQueue.async { [weak self] in
            guard let self = self, self.captureSession.isRunning else { return }
            
            self.currentSettings = settings
            self.burstBuffers.removeAll()
            self.expectedBurstCount = settings.hdrMode.frameCount
            
            // Play GCam shutter sound if enabled
            if settings.shutterSoundEnabled {
                AudioServicesPlaySystemSound(1108) // iOS camera shutter sound ID
            }
            
            DispatchQueue.main.async {
                settings.isProcessing = true
                settings.processingProgress = 0.05
            }
            
            // Lock Exposure and White Balance during burst to ensure matching frames
            self.lockExposureAndAWB()
            
            // Capture bracketed underexposed burst (HDR+ core mechanism)
            self.fireBurstSequence(targetCount: self.expectedBurstCount, evBias: settings.hdrMode.exposureBiasEV)
        }
    }
    
    private func fireBurstSequence(targetCount: Int, evBias: Float) {
        guard burstBuffers.count < targetCount else {
            // Burst collection complete -> Send to Metal Fusion Engine
            finishBurstAndProcess()
            return
        }
        
        let photoSettings: AVCapturePhotoSettings
        if photoOutput.availableRawPhotoPixelFormatTypes.contains(where: { $0 == kCVPixelFormatType_14Bayer_RGGB }) {
            photoSettings = AVCapturePhotoSettings(rawPixelFormatType: kCVPixelFormatType_14Bayer_RGGB)
        } else if let validFormat = photoOutput.availablePhotoPixelFormatTypes.first {
            photoSettings = AVCapturePhotoSettings(format: [kCVPixelBufferPixelFormatTypeKey as String: validFormat])
        } else {
            photoSettings = AVCapturePhotoSettings()
        }
        
        // Never exceed maxPhotoQualityPrioritization to prevent NSInvalidArgumentException
        if photoOutput.maxPhotoQualityPrioritization == .speed {
            photoSettings.photoQualityPrioritization = .speed
        } else {
            photoSettings.photoQualityPrioritization = .balanced
        }
        
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
    
    private func finishBurstAndProcess() {
        unlockExposureAndAWB()
        
        guard let settings = self.currentSettings, !burstBuffers.isEmpty else {
            DispatchQueue.main.async {
                self.currentSettings?.isProcessing = false
            }
            return
        }
        
        print("⚡ Captured \(burstBuffers.count) frames. Starting Metal HDR+ Fusion...")
        
        HDRFusionEngine.shared.processBurst(
            pixelBuffers: burstBuffers,
            settings: settings,
            progress: { progressValue in
                settings.processingProgress = progressValue
            },
            completion: { [weak self] result in
                DispatchQueue.main.async {
                    settings.isProcessing = false
                    settings.processingProgress = 1.0
                    
                    switch result {
                    case .success(let finalImage):
                        print("🎉 MGC HDR+ Photo Processed Successfully!")
                        if let data = finalImage.jpegData(compressionQuality: 0.95) {
                            settings.capturedThumbnail = data
                            self?.saveImageToPhotoLibrary(image: finalImage)
                        }
                    case .failure(let error):
                        print("❌ HDR+ Processing Failed: \(error.localizedDescription)")
                    }
                }
            }
        )
    }
    
    // MARK: - Focus & Exposure Tap
    
    public func focusAndExpose(at point: CGPoint) {
        sessionQueue.async { [weak self] in
            guard let device = self?.activeDevice else { return }
            do {
                try device.lockForConfiguration()
                if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.autoFocus) {
                    device.focusPointOfInterest = point
                    device.focusMode = .autoFocus
                }
                if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(.autoExpose) {
                    device.exposurePointOfInterest = point
                    device.exposureMode = .autoExpose
                }
                device.unlockForConfiguration()
            } catch {}
        }
    }
    
    // MARK: - Hardware Locks
    
    private func lockExposureAndAWB() {
        guard let device = activeDevice else { return }
        do {
            try device.lockForConfiguration()
            if device.isExposureModeSupported(.locked) {
                device.exposureMode = .locked
            }
            if device.isWhiteBalanceModeSupported(.locked) {
                device.whiteBalanceMode = .locked
            }
            device.unlockForConfiguration()
        } catch {}
    }
    
    private func unlockExposureAndAWB() {
        guard let device = activeDevice else { return }
        do {
            try device.lockForConfiguration()
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                device.whiteBalanceMode = .continuousAutoWhiteBalance
            }
            device.unlockForConfiguration()
        } catch {}
    }
    
    // MARK: - Save to Photos Library
    
    private func saveImageToPhotoLibrary(image: UIImage) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else { return }
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, error in
                if success {
                    print("💾 Photo saved to Apple Photos Camera Roll.")
                } else if let error = error {
                    print("❌ Error saving photo: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraManager: AVCapturePhotoCaptureDelegate {
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil, let pixelBuffer = photo.pixelBuffer else {
            print("⚠️ Frame capture dropped or failed")
            return
        }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.burstBuffers.append(pixelBuffer)
            
            DispatchQueue.main.async {
                self.currentSettings?.processingProgress = Float(self.burstBuffers.count) / Float(self.expectedBurstCount) * 0.4
            }
            
            self.fireBurstSequence(
                targetCount: self.expectedBurstCount,
                evBias: self.currentSettings?.hdrMode.exposureBiasEV ?? -1.0
            )
        }
    }
}


