
import UIKit
import AVFoundation

protocol CameraCaptureDelegate: class {
    func bufferCaptured(buffer: CMSampleBuffer!)
}

class CameraCapture: NSObject {
    private let context = CIContext()
    private let sessionQueue = DispatchQueue(label: "CameraCaptureSessionQueue")
    private var cameraCapturePermission = false
    public let captureSession = AVCaptureSession()
    public weak var delegate: CameraCaptureDelegate?
    
    override init()
    {
        super.init()
        
        checkCameraPermission()
        sessionQueue.async { [weak self] in
            self?.configureCaptureSession()
            self?.captureSession.startRunning()
        }
    }
    
    private func checkCameraPermission()
    {
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
        case .authorized:
            cameraCapturePermission = true
        case .notDetermined:
            requestPermission()
        default:
            cameraCapturePermission = false
        }
    }
    
    private func requestPermission()
    {
        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { [weak self] granted in
            self?.cameraCapturePermission = granted
            self?.sessionQueue.resume()
        }
    }
    
    private func configureCaptureSession()
    {
        guard cameraCapturePermission,
            let device =
            AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera],
                                             mediaType: AVMediaType.video,
                                             position: AVCaptureDevice.Position.front).devices.first,
            let deviceInput = try? AVCaptureDeviceInput(device: device),
            captureSession.canAddInput(deviceInput) else { return }
        
        captureSession.sessionPreset = AVCaptureSession.Preset.vga640x480
        captureSession.addInput(deviceInput)
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "CameraCaptureSampleBufferDelegateQueue"))
        
        guard captureSession.canAddOutput(videoOutput) else { return }
        captureSession.addOutput(videoOutput)
        
        guard let connection = videoOutput.connection(with: AVMediaType.video),
            connection.isVideoOrientationSupported,
            connection.isVideoMirroringSupported else { return }
        
        connection.videoOrientation = .portrait
        connection.isVideoMirrored = false
    }
}

extension CameraCapture : AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput,
                              didOutput sampleBuffer: CMSampleBuffer,
                              from connection: AVCaptureConnection)
    {
        self.delegate?.bufferCaptured(buffer: sampleBuffer)
    }
}
