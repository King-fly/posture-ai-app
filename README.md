# Posture AI App

## Project Introduction
Posture AI App is an iOS-based posture analysis application developed using Swift. It uses the camera to real-time monitor users' posture and provide feedback, helping users maintain correct sitting posture and reduce health problems caused by poor posture.

## Features
- Real-time posture monitoring
- Posture analysis and evaluation
- Historical data statistics and analysis
- Personalized settings
- Intuitive user interface

## Technology Stack
- Swift
- SwiftUI
- AVFoundation (camera management)
- Core ML (posture analysis)

## Project Structure
- `posture-ai-app/` - Main application code
  - `Assets.xcassets/` - Application resource files
  - `AppViewModel.swift` - Application view model
  - `CameraManager.swift` - Camera management
  - `CameraPreviewView.swift` - Camera preview view
  - `ContentView.swift` - Main content view
  - `DashboardView.swift` - Dashboard view
  - `Models.swift` - Data models
  - `MonitorView.swift` - Monitoring view
  - `PostureAnalyzer.swift` - Posture analyzer
  - `SettingsView.swift` - Settings view
  - `posture_ai_app.entitlements` - Application permissions configuration
  - `posture_ai_appApp.swift` - Application entry point
- `posture-ai-app.xcodeproj/` - Xcode project files

## Installation and Running
1. Clone the project to your local machine
2. Open `posture-ai-app.xcodeproj` file with Xcode
3. Select an appropriate simulator or connect a real device
4. Run the project

## Usage
1. Authorize camera access when opening the app for the first time
2. Enter the monitoring interface and point the camera at your upper body
3. The app will real-time analyze your posture and provide feedback
4. View historical posture data and analysis reports on the dashboard
5. Adjust app parameters in the settings interface

## Permission Notes
- Camera permission: Used to capture user posture in real-time
- Storage permission: Used to save historical data

## Contribution Guide
Welcome to submit issues and Pull Requests to improve this project.

## License
This project is licensed under the MIT License.