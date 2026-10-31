//
//  MostPopularCategoryView.swift
//  BRS
//
//  Created by Haris York on 20.09.2026.
//

import SwiftUI

struct MostPopularCategoryView: View {
    let pieData: [PieChartPoint]
    
    private var popularCategory: PieChartPoint? {
        pieData.max(by: { item1, item2 in
            item1.count < item2.count
        })
    }
    
    private func item2Count(_ item: PieChartPoint) -> Int {
        return item.count
    }
    
    var body: some View {
        if let leader = popularCategory, leader.count > 0 {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 16, weight: .bold))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Самая популярная категория")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Text(leader.category)
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(leader.percentage)%")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(.orange)
                    
                    Text("\(leader.count) шт.")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color.white.opacity(0.02))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.orange.opacity(0.1), lineWidth: 1)
            )
            .transition(.opacity.combined(with: .scale))
        }
    }
}
