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
            
            // 1. Analyze Face Landmarks (Always runs if face is detected)
            if let faceResult = faceRequest.results?.first {
                let faceWidth = faceResult.boundingBox.width
                
                let baseThreshold = 0.35 - (settings.distanceThreshold * 0.1)
                if faceWidth > baseThreshold * factor {
                    detected = .tooClose
                }
                
                if detected == .good, let landmarks = faceResult.landmarks {
                    if let leftEyebrow = landmarks.leftEyebrow?.normalizedPoints,
                       let rightEyebrow = landmarks.rightEyebrow?.normalizedPoints {
                        let innerLX = leftEyebrow.map { $0.x }.max() ?? 0
                        let innerRX = rightEyebrow.map { $0.x }.min() ?? 1
                        if abs(innerRX - innerLX) < (0.12 * factor) {
                            detected = .frowning
                        }
                    }
                    
                    if detected == .good,
                       let leftEye = landmarks.leftEye?.normalizedPoints,
                       let rightEye = landmarks.rightEye?.normalizedPoints {
                        let calcRatio = { (points: [CGPoint]) -> CGFloat in
                            let maxY = points.map { $0.y }.max() ?? 0
                            let minY = points.map { $0.y }.min() ?? 0
                            let maxX = points.map { $0.x }.max() ?? 0
                            let minX = points.map { $0.x }.min() ?? 0
                            return (maxY - minY) / max(maxX - minX, 0.001)
                        }
                        
                        let leftRatio = calcRatio(leftEye)
                        let rightRatio = calcRatio(rightEye)
                        
                        if (leftRatio + rightRatio) / 2.0 < (0.15 * factor) {
                            detected = .squinting
                        }
                    }
                }
            }
            
            // 2. Analyze Body Pose
            if let poseResult = bodyPoseRequest.results?.first {
                do {
                    let leftShoulder = try poseResult.recognizedPoint(.leftShoulder)
                    let rightShoulder = try poseResult.recognizedPoint(.rightShoulder)
                    let nose = try poseResult.recognizedPoint(.nose)
                    
                    if leftShoulder.confidence > 0.3 && rightShoulder.confidence > 0.3 {
                        let shoulderMidY = (leftShoulder.location.y + rightShoulder.location.y) / 2.0
                        
                        let shoulderDiffY = abs(leftShoulder.location.y - rightShoulder.location.y)
                        if shoulderDiffY > 0.08 * factor {
                            detected = .slouching
                        }
                        
                        // Body pose (structurally) overrides minor facial expressions except when perfectly good
                        if detected == .good || detected == .frowning || detected == .squinting {
                            if nose.confidence > 0.3 {
                                let noseToShoulder = nose.location.y - shoulderMidY
                                
                                if noseToShoulder < 0.15 * factor {
                                    detected = .headTilt
                                } else if noseToShoulder < 0.22 * factor && faceRequest.results?.first?.boundingBox.width ?? 0 > 0.25 {
                                    detected = .leaningForward
                                }
                            }
                        }
                    }
                } catch {
                    // Missed points are ignored
                }
            }
            
            // Temporal Smoothing
            postureHistory.append(detected)
            if postureHistory.count > 8 {
                postureHistory.removeFirst()
            }
            
            let counts = postureHistory.reduce(into: [:]) { counts, posture in
                counts[posture, default: 0] += 1
            }
            
            if let mostFrequent = counts.max(by: { $0.value < $1.value }), mostFrequent.value >= 5 {
                if currentPosture != mostFrequent.key {
                    DispatchQueue.main.async {
                        self.currentPosture = mostFrequent.key
                    }
                }
            }
            
        } catch {
            print("Vision request failed: \(error)")
        }
    }
}
