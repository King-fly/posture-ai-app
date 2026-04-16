import Foundation
import SwiftUI

enum PostureType: String, CaseIterable, Codable {
    case good = "good"
    case frowning = "frowning"
    case squinting = "squinting"
    case headTilt = "head_tilt"
    case slouching = "slouching"
    case leaningForward = "leaning_forward"
    case tooClose = "too_close"
    case leaningBack = "leaning_back"
    
    var label: String {
        switch self {
        case .good: return "良好"
        case .frowning: return "皱眉"
        case .squinting: return "眯眼"
        case .headTilt: return "低头"
        case .slouching: return "驼背"
        case .leaningForward: return "前倾"
        case .tooClose: return "距离过近"
        case .leaningBack: return "后仰"
        }
    }
    
    var color: Color {
        switch self {
        case .good: return Color(hex: "#58cc02")
        case .frowning, .squinting, .leaningForward, .leaningBack: return Color(hex: "#ffc800")
        case .headTilt, .slouching, .tooClose: return Color(hex: "#ff4b4b")
        }
    }
}

struct PostureEvent: Identifiable, Codable {
    var id: String = UUID().uuidString
    var timestamp: TimeInterval
    var type: PostureType
    var duration: TimeInterval
}

struct PostureSettings: Codable, Equatable {
    var sensitivity: Double
    var alertThreshold: Double
    var distanceThreshold: Double
    var enableAudio: Bool
    var enableVoice: Bool
    var enableVisualAlert: Bool
    var focusMode: Bool
    
    static let defaultSettings = PostureSettings(
        sensitivity: 0.5,
        alertThreshold: 3.0,
        distanceThreshold: 0.4,
        enableAudio: true,
        enableVoice: true,
        enableVisualAlert: true,
        focusMode: false
    )
}

struct DailyStats: Codable {
    var date: String
    var score: Int
    var events: [String: Int] // Use string key for Codable enum dictionaries
    var totalActiveTime: TimeInterval
    
    static func empty(for date: String) -> DailyStats {
        return DailyStats(date: date, score: 100, events: [:], totalActiveTime: 0)
    }
}

// Utility extension for Hex Colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    // Semantic Colors for Dark Mode Support
    static var dsTextPrimary: Color { Color.primary }
    static var dsTextSecondary: Color { Color.secondary }
    static var dsBackground: Color { Color(UIColor.systemBackground) }
    static var dsCardBackground: Color { Color(UIColor.secondarySystemBackground) }
    static var dsBorder: Color { Color(UIColor.separator) }
    
    // Core brand colors
    static var dsGreen: Color { Color(hex: "#58cc02") }
    static var dsGreenDark: Color { Color(hex: "#58a700") }
    static var dsGreenLight: Color { Color.green.opacity(0.15) }
    
    static var dsBlue: Color { Color(hex: "#1cb0f6") }
    static var dsBlueDark: Color { Color(hex: "#1899d6") }
    static var dsBlueLight: Color { Color.blue.opacity(0.15) }
    
    static var dsRed: Color { Color(hex: "#ff4b4b") }
    static var dsRedDark: Color { Color(hex: "#ea1515") }
    static var dsYellow: Color { Color(hex: "#ffc800") }
}
