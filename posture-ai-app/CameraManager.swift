import AVFoundation
import CoreImage
import UIKit
import Combine

protocol CameraManagerDelegate: AnyObject {
    func cameraManager(_ manager: CameraManager, didOutput sampleBuffer: CMSampleBuffer)
}

class CameraManager: NSObject, ObservableObject {
    enum Status {
        case unconfigured
        case configured
        case unauthorized
        case failed
    }

    @Published var status: Status = .unconfigured
    @Published var isSessionRunning: Bool = false

    weak var delegate: CameraManagerDelegate?
    
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.postureai.camera.sessionQ")
    private let videoOutput = AVCaptureVideoDataOutput()
    
    override init() {
        super.init()
    }
    
    func checkPermissionsAndConfigure() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.configureSession()
        case .notDetermined:
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video) { authorized in
                if authorized {
                    self.configureSession()
                    self.sessionQueue.resume()
                } else {
                    DispatchQueue.main.async {
                        self.status = .unauthorized
                    }
                }
            }
        default:
            DispatchQueue.main.async {
                self.status = .unauthorized
            }
        }
    }
    
    private func configureSession() {
        sessionQueue.async {
            guard self.status == .unconfigured else { return }
            
            self.session.beginConfiguration()
            self.session.sessionPreset = .hd1280x720
            
            // Add video input
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
                self.setStatus(.failed)
                self.session.commitConfiguration()
                return
            }
            
            guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
                self.setStatus(.failed)
                self.session.commitConfiguration()
                return
            }
            
            if self.session.canAddInput(videoDeviceInput) {
                self.session.addInput(videoDeviceInput)
            } else {
                self.setStatus(.failed)
                self.session.commitConfiguration()
                return
            }
            
            // Add video output
            if self.session.canAddOutput(self.videoOutput) {
                self.session.addOutput(self.videoOutput)
                
                self.videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.postureai.camera.videoDataQ"))
                self.videoOutput.alwaysDiscardsLateVideoFrames = true
                self.videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
                
                if let connection = self.videoOutput.connection(with: .video) {
                    if connection.isVideoOrientationSupported {
                        connection.videoOrientation = .portrait
                    }
                    if connection.isVideoMirroringSupported {
                        connection.isVideoMirrored = true // front camera
                    }
                }
            } else {
                self.setStatus(.failed)
                self.session.commitConfiguration()
                return
            }
            
            self.session.commitConfiguration()
            self.setStatus(.configured)
        }
    }
    
    func start() {
        sessionQueue.async {
            if self.status == .configured && !self.session.isRunning {
                self.session.startRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = true
                }
            }
        }
    }
    
    func stop() {
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = false
                }
            }
        }
    }
    
    private func setStatus(_ status: Status) {
        DispatchQueue.main.async {
            self.status = status
        }
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        delegate?.cameraManager(self, didOutput: sampleBuffer)
    }
}
