//
//  PopularityLeaderboardView.swift
//  BRS
//
//  Created by Haris York on 23.09.2026.
//

import SwiftUI

struct PopularityLeaderboardView: View {
    let leaderboard: [PopularDrinkItem]
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Клик по шапке переключает состояние развернутости
            Button(action: { withAnimation(.spring()) { isExpanded.toggle() } }) {
                HStack {
                    Image(systemName: "crown.fill").foregroundColor(.yellow)
                    Text("Рейтинг популярности").font(.headline).foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding()
                .background(Color.white.opacity(0.03))
            }
            
            if isExpanded {
                // Развернутый вид: Выводим вообще все напитки по порядку
                VStack(spacing: 12) {
                    if leaderboard.isEmpty {
                        Text("Нет данных о продажах").foregroundColor(.gray).font(.caption).padding()
                    } else {
                        ForEach(Array(leaderboard.enumerated()), id: \.element.id) { index, item in
                            HStack {
                                Text("#\(index + 1)")
                                    .bold()
                                    .foregroundColor(index == 0 ? .yellow : (index == leaderboard.count - 1 ? .red : .gray))
                                    .frame(width: 35, alignment: .leading)
                                
                                Text(item.name)
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(item.count) шт.")
                                    .foregroundColor(.orange).bold()
                            }
                            .padding(.horizontal)
                            
                            if index < leaderboard.count - 1 {
                                Divider().background(Color.white.opacity(0.05)).padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
                .background(Color.white.opacity(0.01))
            } else {
                // Свернутый вид: Показываем только Лидера и Аутсайдера
                HStack(spacing: 16) {
                    if let best = leaderboard.first {
                        // Лучший
                        HStack {
                            Text("🥇").font(.caption)
                            VStack(alignment: .leading) {
                                Text(best.name).font(.subheadline).bold().lineLimit(1).foregroundColor(.white)
                                Text("\(best.count) шт.").font(.caption2).foregroundColor(.gray)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    if leaderboard.count > 1, let worst = leaderboard.last {
                        Spacer()
                        // Худший
                        HStack {
                            Text("📉").font(.caption)
                            VStack(alignment: .leading) {
                                Text(worst.name).font(.subheadline).lineLimit(1).foregroundColor(.white)
                                Text("#\(leaderboard.count): \(worst.count) шт.").font(.caption2).foregroundColor(.red)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.01))
            }
        }
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.05), lineWidth: 1))
        .padding(.horizontal)
    }
}
