import Foundation
import Vision
import CoreMedia

class PostureAnalyzer: ObservableObject, CameraManagerDelegate {
    @Published var currentPosture: PostureType = .good
    @Published var isReady: Bool = false
    
    var settings: PostureSettings = .defaultSettings
    
    private var lastAnalysisTime: TimeInterval = 0
    private var distanceBuffer: [CGFloat] = []
    private var postureHistory: [PostureType] = []
    
    private lazy var sequenceHandler = VNSequenceRequestHandler()
    private lazy var faceRequest = VNDetectFaceLandmarksRequest()
    private lazy var bodyPoseRequest = VNDetectHumanBodyPoseRequest()
    
    init() {
        // Model initialization is implicit with Vision, so we mark it as ready.
        DispatchQueue.main.async {
            self.isReady = true
        }
    }
    
    func cameraManager(_ manager: CameraManager, didOutput sampleBuffer: CMSampleBuffer) {
        let currentTime = Date().timeIntervalSince1970
        // Limit to 10 FPS (every 100ms)
        if currentTime - lastAnalysisTime < 0.1 { return }
        lastAnalysisTime = currentTime
        
        analyze(sampleBuffer: sampleBuffer)
    }
    
    private func analyze(sampleBuffer: CMSampleBuffer) {
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up, options: [:])
        
        do {
            try handler.perform([faceRequest, bodyPoseRequest])
            
            var detected: PostureType = .good
            
            let factor = 1.5 - settings.sensitivity
            
            // 1. Analyze Body Pose
            if let poseResult = bodyPoseRequest.results?.first {
                do {
                    let leftShoulder = try poseResult.recognizedPoint(.leftShoulder)
                    let rightShoulder = try poseResult.recognizedPoint(.rightShoulder)
                    let nose = try poseResult.recognizedPoint(.nose)
                    let leftEye = try poseResult.recognizedPoint(.leftEye)
                    let rightEye = try poseResult.recognizedPoint(.rightEye)
                    
                    if leftShoulder.confidence > 0.3 && rightShoulder.confidence > 0.3 && leftEye.confidence > 0.3 && rightEye.confidence > 0.3 {
                        
                        let eyeDistance = abs(leftEye.location.x - rightEye.location.x)
                        distanceBuffer.append(eyeDistance)
                        if distanceBuffer.count > 15 {
                            distanceBuffer.removeFirst()
                        }
                        
                        let avgEyeDist = distanceBuffer.reduce(0, +) / CGFloat(distanceBuffer.count)
                        
                        let baseThreshold = 0.15 - (settings.distanceThreshold * 0.1)
                        let distanceThreshold = baseThreshold * factor
                        
                        // Distance check
                        if avgEyeDist > distanceThreshold {
                            detected = .tooClose
                        }
                        
                        // Head tilt (y is upside down in Vision compared to Web: y=0 is bottom, y=1 is top)
                        let eyeMidY = (leftEye.location.y + rightEye.location.y) / 2.0
                        let shoulderMidY = (leftShoulder.location.y + rightShoulder.location.y) / 2.0
                        
                        let headToShoulderDist = abs(eyeMidY - shoulderMidY)
                        if headToShoulderDist < 0.15 * factor {
                            detected = .headTilt
                        }
                        
                        // Slouching (shoulder vertical diff)
                        let shoulderDiffY = abs(leftShoulder.location.y - rightShoulder.location.y)
                        if shoulderDiffY > 0.05 * factor {
                            detected = .slouching
                        }
                        
                        // Leaning forward (nose too low compared to shoulders)
                        // In vision, lower means closer to 0! Wait, top is 1, so nose should be > shoulder.
                        // If nose is closer to shoulder, leaning forward.
                        if nose.location.y < shoulderMidY + (0.05 / factor) {
                            detected = .leaningForward
                        }
                    }
                } catch {
                    // Points not found, ignore frame
                }
            }
            
            // 2. Analyze Face Landmarks for frowning/squinting
            if detected == .good, let faceResult = faceRequest.results?.first, let landmarks = faceResult.landmarks {
                if let leftEyebrow = landmarks.leftEyebrow?.normalizedPoints,
                   let rightEyebrow = landmarks.rightEyebrow?.normalizedPoints {
                    // Basic heuristic: distance between inner eyebrows for frowning
                    if let innerL = leftEyebrow.last, let innerR = rightEyebrow.first {
                        let distance = abs(innerL.x - innerR.x)
                        // This threshold needs tuning, but acts as a stand-in
                        if distance < 0.1 * factor {
                            detected = .frowning
                        }
                    }
                }
            }
            
            // Temporal Smoothing (8 frames)
            postureHistory.append(detected)
            if postureHistory.count > 8 {
                postureHistory.removeFirst()
            }
            
            let counts = postureHistory.reduce(into: [:]) { counts, posture in
                counts[posture, default: 0] += 1
            }
            
            if let mostFrequent = counts.max(by: { $0.value < $1.value }), mostFrequent.value >= 5 {
                DispatchQueue.main.async {
                    self.currentPosture = mostFrequent.key
                }
            }
            
        } catch {
            print("Vision request failed: \(error)")
        }
    }
}
