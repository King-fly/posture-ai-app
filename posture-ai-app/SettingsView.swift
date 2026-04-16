import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: AppViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("应用设置")
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(Color.dsTextPrimary)
                    Text("个性化您的监测体验。")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.dsTextSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                VStack(spacing: 20) {
                    // Sensitivity
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("检测敏感度")
                                .font(.system(size: 16, weight: .black))
                                .foregroundColor(Color.dsTextPrimary)
                            Spacer()
                            Text(String(format: "%.1f", viewModel.settings.sensitivity))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color.dsBlue)
                        }
                        Slider(value: $viewModel.settings.sensitivity, in: 0...1, step: 0.1)
                            .tint(Color.dsBlue)
                        Text("值越高越容易触发不良姿势提醒。")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.dsTextSecondary)
                    }
                    .padding()
                    .background(Color.dsCardBackground)
                    .cornerRadius(16)
                    
                    // Alert Threshold
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("提醒延迟 (秒)")
                                .font(.system(size: 16, weight: .black))
                                .foregroundColor(Color.dsTextPrimary)
                            Spacer()
                            Text(String(format: "%.1f", viewModel.settings.alertThreshold))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color.dsBlue)
                        }
                        Slider(value: $viewModel.settings.alertThreshold, in: 1...10, step: 0.5)
                            .tint(Color.dsBlue)
                        Text("不良姿势持续多少秒后触发提醒。")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.dsTextSecondary)
                    }
                    .padding()
                    .background(Color.dsCardBackground)
                    .cornerRadius(16)
                    
                    // Distance Threshold
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("距离阈值")
                                .font(.system(size: 16, weight: .black))
                                .foregroundColor(Color.dsTextPrimary)
                            Spacer()
                            Text(String(format: "%.2f", viewModel.settings.distanceThreshold))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color.dsBlue)
                        }
                        Slider(value: $viewModel.settings.distanceThreshold, in: 0...1, step: 0.05)
                            .tint(Color.dsBlue)
                        Text("调整距离过近的判定标准。")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.dsTextSecondary)
                    }
                    .padding()
                    .background(Color.dsCardBackground)
                    .cornerRadius(16)
                    
                    // Toggles
                    VStack(spacing: 16) {
                        Toggle(isOn: $viewModel.settings.enableAudio) {
                            Text("提示音提醒")
                                .font(.system(size: 16, weight: .black))
                                .foregroundColor(Color.dsTextPrimary)
                        }
                        .tint(Color.dsGreen)
                        
                        Toggle(isOn: $viewModel.settings.enableVoice) {
                            Text("语音播报")
                                .font(.system(size: 16, weight: .black))
                                .foregroundColor(Color.dsTextPrimary)
                        }
                        .tint(Color.dsGreen)
                    }
                    .padding()
                    .background(Color.dsCardBackground)
                    .cornerRadius(16)
                    
                }
                .padding(.horizontal)
                
                Spacer(minLength: 40)
            }
            .padding(.top)
        }
    }
}
