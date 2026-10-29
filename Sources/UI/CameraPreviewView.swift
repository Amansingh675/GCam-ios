import SwiftUI
import AVFoundation

/// High-performance UIViewRepresentable embedding AVCaptureVideoPreviewLayer
public struct CameraPreviewView: UIViewRepresentable {
    public let session: AVCaptureSession
    
    public init(session: AVCaptureSession) {
        self.session = session
    }
    
    public func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        if let conn = view.videoPreviewLayer.connection, conn.isVideoOrientationSupported {
            conn.videoOrientation = .portrait
        }
        return view
    }
    
    public func updateUIView(_ uiView: PreviewUIView, context: Context) {
        if uiView.videoPreviewLayer.session != session {
            uiView.videoPreviewLayer.session = session
        }
        if let conn = uiView.videoPreviewLayer.connection, conn.isVideoOrientationSupported {
            conn.videoOrientation = .portrait
        }
    }
}

public class PreviewUIView: UIView {
    public override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    public var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        if let previewLayer = layer as? AVCaptureVideoPreviewLayer {
            return previewLayer
        }
        return AVCaptureVideoPreviewLayer()
    }
}
