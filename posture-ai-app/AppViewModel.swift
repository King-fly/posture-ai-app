import Foundation
import Combine
import AVFoundation

class AppViewModel: ObservableObject {
    @Published var settings: PostureSettings {
        didSet {
            saveSettings()
            analyzer.settings = settings
        }
    }
    
    @Published var stats: DailyStats {
        didSet {
            saveStats()
        }
    }
    
    @Published var history: [DailyStats] = []
    
    @Published var isMonitoring: Bool = false
    @Published var alertProgress: Double = 0.0
    
    let cameraManager = CameraManager()
    let analyzer = PostureAnalyzer()
    
    private var badPostureStartTime: TimeInterval?
    private var cancellables = Set<AnyCancellable>()
    private var alertTimer: Timer?
    private var activeTimeTimer: Timer?
    
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    init() {
        // Configure AVAudioSession for Voice Synthesis
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
        
        // Load Settings
        if let data = UserDefaults.standard.data(forKey: "posture_settings"),
           let savedSettings = try? JSONDecoder().decode(PostureSettings.self, from: data) {
            self.settings = savedSettings
        } else {
            self.settings = .defaultSettings
        }
        
        // Load Stats
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())
        
        if let data = UserDefaults.standard.data(forKey: "posture_stats_\(today)"),
           let savedStats = try? JSONDecoder().decode(DailyStats.self, from: data) {
            self.stats = savedStats // Should ideally merge if dates match, but simple decode works
        } else {
            self.stats = DailyStats.empty(for: today)
        }
        
        // Load History
        var loadedHistory: [DailyStats] = []
        for (key, value) in UserDefaults.standard.dictionaryRepresentation() {
            if key.hasPrefix("posture_stats_") && key != "posture_stats_\(today)" {
                // Ensure value can be cast to data or String
                if let stringValue = value as? String, let data = stringValue.data(using: .utf8) {
                    if let stat = try? JSONDecoder().decode(DailyStats.self, from: data) {
                        loadedHistory.append(stat)
                    }
                } else if let data = value as? Data {
                    if let stat = try? JSONDecoder().decode(DailyStats.self, from: data) {
                        loadedHistory.append(stat)
                    }
                }
            }
        }
        loadedHistory.sort { $0.date > $1.date }
        self.history = loadedHistory
        
        // Configure analyzer
        cameraManager.delegate = analyzer
        analyzer.settings = settings
        
        // Sync posture from analyzer
        analyzer.$currentPosture
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newPosture in
                self?.handlePostureChange(newPosture: newPosture)
            }
            .store(in: &cancellables)
    }
    
    func toggleMonitoring() {
        isMonitoring.toggle()
        if isMonitoring {
            cameraManager.checkPermissionsAndConfigure()
            cameraManager.start()
            startTimers()
        } else {
            cameraManager.stop()
            stopTimers()
            alertProgress = 0
            badPostureStartTime = nil
        }
    }
    
    private func handlePostureChange(newPosture: PostureType) {
        guard isMonitoring else { return }
        
        if newPosture == .good {
            badPostureStartTime = nil
            alertProgress = 0
        } else {
            if badPostureStartTime == nil {
                badPostureStartTime = Date().timeIntervalSince1970
            }
        }
    }
    
    private func startTimers() {
        alertTimer?.invalidate()
        alertTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.checkAlertProgress()
        }
        
        activeTimeTimer?.invalidate()
        activeTimeTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.stats.totalActiveTime += 5.0
        }
    }
    
    private func stopTimers() {
        alertTimer?.invalidate()
        activeTimeTimer?.invalidate()
        alertTimer = nil
        activeTimeTimer = nil
    }
    
    private func checkAlertProgress() {
        let posture = analyzer.currentPosture
        
        if posture != .good {
            let start = badPostureStartTime ?? Date().timeIntervalSince1970
            badPostureStartTime = start
            let elapsed = Date().timeIntervalSince1970 - start
            let threshold = max(settings.alertThreshold, 0.1)
            
            var progress = (elapsed / threshold) * 100.0
            if progress > 100 { progress = 100 }
            
            self.alertProgress = progress
            
            if progress >= 100 {
                triggerAlert(for: posture)
                badPostureStartTime = Date().timeIntervalSince1970 // Reset
            }
        } else {
            self.alertProgress = 0
        }
    }
    
    private func triggerAlert(for posture: PostureType) {
        if settings.enableAudio {
            AudioServicesPlaySystemSound(1052)
        }
        
        if settings.enableVoice && !speechSynthesizer.isSpeaking {
            let utterance = AVSpeechUtterance(string: "请注意，检测到您正在\(posture.label)")
            utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
            speechSynthesizer.speak(utterance)
        }
        
        // Update stats
        stats.events[posture.rawValue, default: 0] += 1
        let totalEvents = stats.events.values.reduce(0, +)
        stats.score = max(100 - (totalEvents * 2), 0)
    }
    
    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: "posture_settings")
        }
    }
    
    private func saveStats() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())
        
        if let encoded = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(encoded, forKey: "posture_stats_\(today)")
        }
    }
}
