//
//   DrinkRowView.swift
//  BRS
//
//  Created by Haris York on 06.06.2026.
//

import SwiftUI

struct DrinkRowView: View {
    let drink: Drink
    let isBarCheckedIn: Bool
    let onDrinkLogged: () -> Void
    
    @State private var isLoading = false
    private let service = DrinkService()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 16) {
                Image(systemName: "wineglass.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
                    .frame(width: 44, height: 44)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(drink.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("\(drink.type) • \(String(format: "%.1f", drink.score)) ★")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // 🌟 Если drink.canRate == true, значит юзер уже выпил напиток.
                // Кнопка автоматически становится зеленой плашкой "Выпито"
                if drink.canRate {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Выпито")
                    }
                    .font(.system(size: 13, weight: .bold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.15))
                    .foregroundColor(.green)
                    .cornerRadius(12)
                } else {
                    Button(action: {
                        logBoсal()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle")
                            Text("Выпить")
                        }
                        .font(.system(size: 13, weight: .bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(isBarCheckedIn ? Color.blue : Color.gray.opacity(0.3))
                        .foregroundColor(isBarCheckedIn ? .white : .secondary)
                        .cornerRadius(12)
                    }
                    .disabled(!isBarCheckedIn || isLoading)
                }
            }
            
            // Кнопка повтора "Еще один" выезжает плавно
            if drink.canRate && isBarCheckedIn {
                HStack(spacing: 16) {
                    Button(action: {
                        logBoсal()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.caption)
                            Text("Еще один")
                                .font(.caption)
                        }
                        .foregroundColor(.blue)
                        .padding(.vertical, 4)
                    }
                    .disabled(isLoading)
                    
                    Spacer()
                }
                .padding(.leading, 60)
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    private func logBoсal() {
        isLoading = true
        Task {
            do {
                try await service.logDrinkAction(drinkId: drink.id)
                onDrinkLogged() // Командуем родительскому BarDetailView обновиться
            } catch {
                print("Ошибка фиксации бокала: \(error.localizedDescription)")
            }
            isLoading = false
        }
    }
}
