import SwiftUI

struct MonitorView: View {
    @ObservedObject var viewModel: AppViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("姿态监测")
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(Color.dsTextPrimary)
                    Text("实时监测坐姿，预防疲劳。")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.dsTextSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                // Camera Monitor
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.dsCardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.dsBorder, lineWidth: 2)
                        )
                    
                    if viewModel.isMonitoring {
                        switch viewModel.cameraManager.status {
                        case .configured:
                            CameraPreviewView(session: viewModel.cameraManager.session)
                                .clipShape(RoundedRectangle(cornerRadius: 24))
                                
                            if viewModel.alertProgress > 0 {
                                GeometryReader { geometry in
                                    Rectangle()
                                        .fill(Color.dsRed.opacity(0.8))
                                        .frame(width: geometry.size.width * (CGFloat(viewModel.alertProgress) / 100.0), height: 6)
                                        .frame(maxHeight: .infinity, alignment: .bottom)
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 24))
                                .animation(.linear(duration: 0.1), value: viewModel.alertProgress)
                            }
                        case .unauthorized:
                            Text("未授权访问摄像头")
                                .font(.headline)
                                .foregroundColor(.gray)
                        case .failed:
                            Text("摄像头启动失败")
                                .font(.headline)
                                .foregroundColor(.gray)
                        default:
                            ProgressView()
                        }
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "video.slash.fill")
                                .font(.system(size: 40))
                                .foregroundColor(Color.dsTextSecondary)
                            Text("摄像头已关闭")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color.dsTextSecondary)
                        }
                    }
                    
                    // Toggle Button overlay
                    VStack {
                        Spacer()
                        Button(action: {
                            viewModel.toggleMonitoring()
                        }) {
                            Text(viewModel.isMonitoring ? "停止监测" : "开始监测")
                                .font(.system(size: 16, weight: .heavy))
                                .foregroundColor(.white)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 14)
                                .background(viewModel.isMonitoring ? Color.dsRed : Color.dsBlue)
                                .cornerRadius(16)
                                .shadow(color: viewModel.isMonitoring ? Color.dsRedDark : Color.dsBlueDark, radius: 0, x: 0, y: 4)
                        }
                        .padding(.bottom, 20)
                    }
                }
                .frame(height: 400)
                .padding(.horizontal)
                
                // Stats Grid
                HStack(spacing: 16) {
                    StatCard(title: "当前状态", value: viewModel.analyzer.currentPosture.label, valueColor: viewModel.analyzer.currentPosture.color)
                    StatCard(title: "今日评分", value: "\(viewModel.stats.score)", valueColor: Color.dsBlue)
                }
                .padding(.horizontal)
                
                Spacer(minLength: 40)
            }
            .padding(.top)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let valueColor: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .black))
                .foregroundColor(Color.dsTextSecondary)
            Text(value)
                .font(.system(size: 20, weight: .black))
                .foregroundColor(valueColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.dsBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.dsBorder, lineWidth: 2)
        )
        .shadow(color: Color.dsBorder, radius: 0, x: 0, y: 4)
    }
}
