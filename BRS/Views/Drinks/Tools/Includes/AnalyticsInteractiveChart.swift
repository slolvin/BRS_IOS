//
//  AnalyticsInteractiveChart.swift
//  BRS
//
//  Created by Haris York on 23.09.2026.
//
import SwiftUI
import Charts

struct AnalyticsInteractiveChart: View {
    let chartData: [ChartPoint]
    let selectedPeriod: String
    @Binding var selectedBarLabel: String?
    
    @State private var chartType: ChartType = .line
    
    var body: some View {
        let maxCount = chartData.map { $0.count }.max() ?? 1
        
        VStack(spacing: 12) {
            Picker("Тип графика", selection: $chartType) {
                ForEach(ChartType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 150)
            Chart {
                ForEach(chartData) { point in
                    if chartType == .bar {
                        BarMark(
                            x: .value("Период", point.label),
                            y: .value("Заказы", point.count)
                        )
                        .foregroundStyle(selectedBarLabel == point.label ? Color.orange.gradient : Color.orange.opacity(0.8).gradient)
                        .cornerRadius(2)
                    } else {
                        LineMark(
                            x: .value("Период", point.label),
                            y: .value("Заказы", point.count)
                        )
                        .interpolationMethod(.monotone)
                        .foregroundStyle(.orange)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                    }
                }
            }
            .frame(height: 130)
            .chartXAxis {
                AxisMarks { value in
                    if let label = value.as(String.self) {
                        if selectedPeriod == "День" {
                            if let hourInt = Int(label), hourInt % 3 == 0 {
                                AxisValueLabel("\(label)").foregroundStyle(.gray)
                            }
                        } else {
                            AxisValueLabel().foregroundStyle(.gray)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { AxisValueLabel().foregroundStyle(.gray) }
            }
            
            let activePoints = chartData.filter { $0.count > 0 }
            if !activePoints.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(activePoints) { point in
                            Button(action: {
                                withAnimation {
                                    if selectedBarLabel == point.label {
                                        selectedBarLabel = nil
                                    } else {
                                        selectedBarLabel = point.label
                                    }
                                }
                            }) {
                                VStack(spacing: 2) {
                                    Text(selectedPeriod == "День" ? "\(point.label):00" : point.label)
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.gray)
                                    Text("\(point.count) зак.")
                                        .font(.system(size: 11, weight: .black))
                                        .foregroundColor(selectedBarLabel == point.label ? .black : .orange)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(selectedBarLabel == point.label ? Color.orange : Color.white.opacity(0.04))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.orange.opacity(selectedBarLabel == point.label ? 1 : 0.2), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 2)
                    .padding(.vertical, 4)
                }
            }
        }
    }
}
