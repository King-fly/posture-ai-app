import SwiftUI

struct DashboardView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: AppViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("健康统计")
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(Color.dsTextPrimary)
                    Text("见证您的每一天改善。")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.dsTextSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                // Active time card
                VStack {
                    Text("今日监测时长")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(Color.dsTextSecondary)
                    
                    Text(formatTime(viewModel.stats.totalActiveTime))
                        .font(.system(size: 32, weight: .black))
                        .foregroundColor(Color.dsGreen)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color.dsBackground)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.dsBorder, lineWidth: 2)
                )
                .shadow(color: Color.dsBorder, radius: 0, x: 0, y: 4)
                .padding(.horizontal)
                
                // Events Breakdown
                VStack(alignment: .leading, spacing: 16) {
                    Text("今日不良姿势触发")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(Color.dsTextPrimary)
                    
                    if viewModel.stats.events.isEmpty {
                        Text("暂无数据，保持良好坐姿！")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color.dsTextSecondary)
                            .frame(maxWidth: .infinity, minHeight: 100)
                            .background(Color.dsCardBackground)
                            .cornerRadius(16)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(Array(viewModel.stats.events.keys.sorted()), id: \.self) { key in
                                if let type = PostureType(rawValue: key), viewModel.stats.events[key]! > 0 {
                                    HStack {
                                        Text(type.label)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(Color.dsTextPrimary)
                                        Spacer()
                                        Text("\(viewModel.stats.events[key]!) 次")
                                            .font(.system(size: 16, weight: .black))
                                            .foregroundColor(type.color)
                                    }
                                    .padding()
                                    .background(Color.dsCardBackground)
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // History
                VStack(alignment: .leading, spacing: 16) {
                    Text("历史记录")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(Color.dsTextPrimary)
                    
                    if viewModel.history.isEmpty {
                        Text("暂无历史记录。")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color.dsTextSecondary)
                    } else {
                        ForEach(viewModel.history, id: \.date) { record in
                            HStack {
                                Text(record.date)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Color.dsTextSecondary)
                                Spacer()
                                Text("评分: \(record.score)")
                                    .font(.system(size: 16, weight: .black))
                                    .foregroundColor(record.score >= 80 ? Color.dsGreen : Color.dsYellow)
                            }
                            .padding()
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.dsBorder, lineWidth: 2)
                            )
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer(minLength: 40)
            }
            .padding(.top)
        }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let hrs = Int(seconds) / 3600
        let mins = (Int(seconds) % 3600) / 60
        if hrs > 0 {
            return "\(hrs)小时 \(mins)分钟"
        }
        return "\(mins)分钟"
    }
}
