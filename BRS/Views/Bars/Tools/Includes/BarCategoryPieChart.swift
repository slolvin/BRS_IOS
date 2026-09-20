//
//  BarCategoryPieChart.swift
//  BRS
//
//  Created by Haris York on 20.09.2026.
//
import SwiftUI
import Charts

struct BarCategoryPieChart: View {
    let pieData: [PieChartPoint]
    
    private let chartColors: [Color] = [.blue, .purple, .pink, .orange, .green, .cyan]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundColor(.pink)
                Text("Доли продаж по категориям алкоголя")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // 🌟 ИСПРАВЛЕНО: Защита от пустых категорий или некорректных данных от бэка
            if pieData.isEmpty || pieData.allSatisfy({ $0.count == 0 }) {
                Text("В СУБД пока отсутствуют логи транзакций пролива алкоголя.")
                    .font(.caption2)
                    .italic()
                    .foregroundColor(.gray)
                    .padding(.vertical, 8)
            } else {
                HStack(spacing: 16) {
                    // Нативный Donut-бублик БРС системы
                    Chart {
                        ForEach(pieData) { slice in
                            // Отрисовываем сектор только если его значение больше нуля
                            if slice.count > 0 {
                                SectorMark(
                                    angle: .value("Продажи", Double(slice.count)),
                                    innerRadius: .ratio(0.6),
                                    angularInset: 2.0
                                )
                                .foregroundStyle(by: .value("Категория", slice.category))
                                .cornerRadius(4)
                            }
                        }
                    }
                    .frame(width: 110, height: 110) // Строго фиксируем размеры графика
                    .chartLegend(.hidden)
                    .chartForegroundStyleScale(domain: pieData.map { $0.category }, range: chartColors)
                    
                    // Кастомная динамическая легенда
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(pieData.enumerated()), id: \.element.id) { index, slice in
                            HStack(spacing: 6) {
                                Circle()
                                    .frame(width: 8, height: 8)
                                    .foregroundColor(getSystemColor(for: index))
                                
                                Text(slice.category)
                                    .font(.system(size: 11))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Text("\(slice.percentage)%")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading) // Даем легенде занять оставшееся место
                }
                .padding(.vertical, 6)
            }
        }
    }
    
    private func getSystemColor(for index: Int) -> Color {
        return chartColors[index % chartColors.count]
    }
}
