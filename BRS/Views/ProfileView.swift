//
//  ProfileView.swift
//  BRS
//
//  Created by Haris York on 06.06.2026.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Фирменный темный фон
            Color(red: 0.1, green: 0.1, blue: 0.12)
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView().tint(.blue).scaleEffect(1.5)
            } else if let profile = viewModel.profile {
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // 1. Аватар и Юзернейм (Оставляем твой код)
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 90, height: 90)
                                    .overlay(Circle().stroke(Color.blue.opacity(0.3), lineWidth: 2))
                                Image(systemName: "person.fill").font(.system(size: 40)).foregroundColor(.blue)
                            }
                            Text(profile.username.uppercased()).font(.title2).fontWeight(.bold).foregroundColor(.white).tracking(1)
                            Text(profile.email ?? "Email не указан").font(.subheadline).foregroundColor(.gray)
                        }
                        .padding(.top, 20)
                        let badge = profile.monthlyBadge ?? "Новичок"
                        let glassesCount = profile.stats?.totalGlasses ?? 0
                        let litersCount = profile.stats?.totalLiters ?? 0.0
                        let favoriteDrink = profile.stats?.favoriteDrink ?? "Water"
                        let avgAbv = profile.stats?.avgAbv ?? 0.0
                        // Теги роли и статуса
                        HStack(spacing: 10) {
                            Text(profile.role.uppercased()).font(.caption2).fontWeight(.black).padding(.horizontal, 12).padding(.vertical, 6).background(Color.purple.opacity(0.15)).foregroundColor(.purple).cornerRadius(20)
                            Text("СТАТУС: \(badge.uppercased())").font(.caption2).fontWeight(.black).padding(.horizontal, 12).padding(.vertical, 6).background(badgeColor(for: badge.uppercased()).opacity(0.15)).foregroundColor(badgeColor(for: badge.uppercased())).cornerRadius(20)
                        }
                        
                        // 2. Сетка Аналитики / Маленькие карточки (Оставляем твой код)
                        VStack(spacing: 14) {
                            HStack(spacing: 14) {
                                StatCard(title: "Всего бокалов", value: "\(glassesCount)", icon: "plus.circle.fill", color: .green)
                                StatCard(title: "Выпито литров", value: String(format: "%.2f Л", litersCount), icon: "drop.fill", color: .blue)
                            }
                            HStack(spacing: 14) {
                                StatCard(title: "Любимый напиток", value: favoriteDrink, icon: "wineglass.fill", color: .pink)
                                StatCard(title: "Средний градус", value: String(format: "%.1f%%", avgAbv), icon: "percent", color: .orange)
                            }
                        }
                        .padding(.horizontal)
                        
                        // ================= СВОРАЧИВАЮЩИЕСЯ БЛОКИ (iOS ACCORDION) =================
                        VStack(spacing: 16) {
                            
                            // БЛОК 1: История выпитых напитков
                            DisclosureGroup {
                                if profile.safeDrunkHistory.isEmpty {
                                    Text("Вы еще не отмечали выпитые напитки")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .padding(.vertical, 8)
                                } else {
                                    VStack(spacing: 10) {
                                        ForEach(profile.safeDrunkHistory) { item in
                                            let name = item.drinkName ?? "Напиток"
                                            let drinkType = item.type ?? "Без типа"
                                            let vol = item.volume ?? 0
                                            let timestamp = item.timestamp ?? "0"
                                            let percentage = item.abv ?? 0.0
                                            HStack {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(name)
                                                        .font(.subheadline)
                                                        .fontWeight(.semibold)
                                                        .foregroundColor(.white)

                                                    Text("\(drinkType) • \(vol) мл • \(String(format: "%.1f", percentage))%")
                                                        .font(.caption2)
                                                        .foregroundColor(.gray)
                                                }
                                                Spacer()
                                                Text(timestamp)
                                                    .font(.caption2)
                                                    .foregroundColor(.blue.opacity(0.8))
                                            }
                                            .padding(.vertical, 6)
                                            if item.id != profile.safeDrunkHistory.last?.id { Divider().background(Color.white.opacity(0.05)) }
                                        }
                                    }
                                    .padding(.top, 8)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "clock.fill").foregroundColor(.green)
                                    Text("История выпитого").fontWeight(.medium).foregroundColor(.white)
                                    Spacer()
                                    Text("\(profile.safeDrunkHistory.count)").font(.caption).foregroundColor(.gray).padding(.horizontal, 8).padding(.vertical, 2).background(Color.white.opacity(0.05)).cornerRadius(10)
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.03))
                            .cornerRadius(16)

                            // БЛОК 2: Системный лог активности (Recent Logs)
                            DisclosureGroup {
                                if profile.safeRecentLogs.isEmpty {
                                    Text("История активности пуста")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .padding(.vertical, 8)
                                } else {
                                    VStack(spacing: 10) {
                                        // 1. Используем safeRecentLogs для безопасной итерации
                                        ForEach(profile.safeRecentLogs) { log in
                                            // Раскрываем опциональные поля конкретного лога БРС
                                            let type = log.actionType ?? "ИНФО"
                                            let time = log.timestamp ?? ""
                                            let desc = log.description ?? "Действие без описания"
                                            
                                            VStack(alignment: .leading, spacing: 6) {
                                                HStack {
                                                    Text(type.uppercased())
                                                        .font(.system(size: 9, weight: .bold))
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(Color.gray.opacity(0.2))
                                                        .foregroundColor(.gray)
                                                        .cornerRadius(4)
                                                    Spacer()
                                                    Text(time)
                                                        .font(.system(size: 10))
                                                        .foregroundColor(.gray)
                                                }
                                                Text(desc)
                                                    .font(.caption)
                                                    .foregroundColor(.white.opacity(0.7))
                                                    .fixedSize(horizontal: false, vertical: true)
                                            }
                                            .padding(.vertical, 4)
                                            
                                            // 2. Безопасно проверяем, является ли лог последним в списке
                                            if time != profile.safeRecentLogs.last?.timestamp {
                                                Divider().background(Color.white.opacity(0.05))
                                            }
                                        }
                                    }
                                    .padding(.top, 8)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "list.bullet.rectangle.fill").foregroundColor(.purple)
                                    Text("Логи активности").fontWeight(.medium).foregroundColor(.white)
                                    Spacer()
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.03))
                            .cornerRadius(16)
                            
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                }
                .animation(.default, value: viewModel.profile) // Плавное раскрытие спойлеров при клике
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    Text(error)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
        .navigationTitle("Профиль")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Запускаем загрузку только если данных еще нет
            if viewModel.profile == nil && !viewModel.isLoading {
                await viewModel.loadProfile()
            }
        }
    }
    
    // Вспомогательная функция для выбора цвета ачивки в iOS
    private func badgeColor(for badge: String) -> Color {
        switch badge.uppercased() {
        case "ПИВО": return .orange
        case "ПИРАТ": return .red
        case "ЭСТЕТ": return .blue
        default: return .gray
        }
    }
}

// ИСПРАВЛЕНО: возвращен вспомогательный компонент для маленьких карточек
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.headline)
                Spacer()
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .lineLimit(1) // Защита от разъезжания текста
                .minimumScaleFactor(0.7) // Сжатие шрифта, если название коктейля слишком длинное
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity) // ИСПРАВЛЕНО: изменено для корректного деления пространства в HStack
        .background(Color.white.opacity(0.04))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.02), lineWidth: 1))
    }
}
