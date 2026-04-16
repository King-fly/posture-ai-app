import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.dsGreen)
                            .frame(width: 40, height: 40)
                            .padding(.bottom, 4)
                            .background(Color.dsGreenDark)
                            .cornerRadius(12)
                        
                        Image(systemName: "heart.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                            .offset(y: -2)
                    }
                    Text("PostureAI")
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundColor(Color.dsGreen)
                }
                
                Spacer()
                
                if viewModel.isMonitoring {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.dsGreen)
                            .frame(width: 10, height: 10)
                        
                        Text("监测中")
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(Color.dsGreen)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.dsGreenLight)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.dsGreen.opacity(0.2), lineWidth: 2)
                    )
                }
            }
            .padding()
            .background(Color.dsBackground)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
            .zIndex(1)
            
            // Main content based on selection
            ZStack {
                Color.dsBackground.ignoresSafeArea()
                
                switch selectedTab {
                case 0:
                    MonitorView(viewModel: viewModel)
                case 1:
                    DashboardView(viewModel: viewModel)
                case 2:
                    SettingsView(viewModel: viewModel)
                default:
                    EmptyView()
                }
            }
            
            // Custom Tab Bar
            HStack(spacing: 0) {
                TabBarButton(icon: "camera.fill", title: "监测", isSelected: selectedTab == 0) {
                    selectedTab = 0
                }
                TabBarButton(icon: "chart.bar.fill", title: "统计", isSelected: selectedTab == 1) {
                    selectedTab = 1
                }
                TabBarButton(icon: "gearshape.fill", title: "设置", isSelected: selectedTab == 2) {
                    selectedTab = 2
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 20)
            .background(Color.dsBackground)
            .shadow(color: Color.black.opacity(0.05), radius: -2, x: 0, y: -2)
        }
        .ignoresSafeArea(.all, edges: .bottom)
        // Auto-pause monitoring on background
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            if viewModel.isMonitoring {
                viewModel.toggleMonitoring()
            }
        }
    }
}

struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                Text(title)
                    .font(.system(size: 10, weight: .black))
            }
            .foregroundColor(isSelected ? Color.dsBlue : Color.dsTextSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? Color.dsBlueLight : Color.clear)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.dsBlue : Color.clear, lineWidth: 2)
            )
            .padding(.horizontal, 8)
        }
    }
}
