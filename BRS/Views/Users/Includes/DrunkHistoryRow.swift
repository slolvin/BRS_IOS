//
//  DrunkHistoryRow.swift
//  BRS
//
//  Created by Haris York on 23.09.2026.
//
import SwiftUI

struct DrunkHistoryRow: View {
    let item: DrunkHistoryItem
    let isLast: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.safeDrinkName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    // 🌟 ИСПРАВЛЕНО: Восстановлена правильная интерполяция строк через \()
                    Text("\(item.safeType) • \(item.safeVolume) • \(item.safeAbv)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                Spacer()
                
                Text(item.timestamp ?? "--:--")
                    .font(.caption2)
                    .foregroundColor(.blue.opacity(0.8))
            }
            .padding(.vertical, 6)
            
            if !isLast {
                Divider()
                    .background(Color.white.opacity(0.05))
            }
        }
    }
}
