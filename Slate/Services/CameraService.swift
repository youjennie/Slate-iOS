import AVFoundation
import UIKit
import SwiftUI

/// 실제 카메라 세션을 관리하는 서비스
/// - 전면/후면 카메라 전환
/// - 실시간 프리뷰 제공
/// - 사진 촬영
class CameraService: NSObject, ObservableObject {
    
    // MARK: - Published
    @Published var capturedImage: UIImage?
    @Published var isUsingFrontCamera: Bool = false
    @Published var isCameraAuthorized: Bool = false
    @Published var showPermissionAlert: Bool = false
    
    // MARK: - AVFoundation
    let session = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var currentInput: AVCaptureDeviceInput?
    private var completion: ((UIImage?) -> Void)?
    
    override init() {
        super.init()
        checkPermission()
    }
    
    // MARK: - 권한 체크
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isCameraAuthorized = true
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isCameraAuthorized = granted
                    if granted {
                        self?.setupSession()
                    } else {
                        self?.showPermissionAlert = true
                    }
                }
            }
        default:
            isCameraAuthorized = false
            showPermissionAlert = true
        }
    }
    
    // MARK: - 세션 설정
    func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        // 기존 입력 제거
        if let currentInput = currentInput {
            session.removeInput(currentInput)
        }
        
        // 카메라 선택 (전면/후면)
        let position: AVCaptureDevice.Position = isUsingFrontCamera ? .front : .back
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
              let input = try? AVCaptureDeviceInput(device: device) else {
            session.commitConfiguration()
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
            currentInput = input
        }
        
        // Photo Output 추가 (최초 1회만)
        if session.outputs.isEmpty {
            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
            }
        }
        
        session.commitConfiguration()
    }
    
    // MARK: - 세션 시작/정지
    func start() {
        guard isCameraAuthorized else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }
    
    func stop() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.stopRunning()
        }
    }
    
    // MARK: - 카메라 전환
    func toggleCamera() {
        isUsingFrontCamera.toggle()
        setupSession()
    }
    
    // MARK: - 사진 촬영
    func takePhoto(completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            completion?(nil)
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.capturedImage = image
            self?.completion?(image)
        }
    }
}

// MARK: - SwiftUI 카메라 프리뷰 (UIViewRepresentable)
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        
        // Auto Layout 대응
        context.coordinator.previewLayer = previewLayer
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.previewLayer?.frame = uiView.bounds
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}
