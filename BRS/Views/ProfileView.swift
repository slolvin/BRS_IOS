//
//  ProfileView.swift
//  BRS
//
//  Created by Haris York on 06.06.2026.
//
import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var isShowingEditProfile = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Фирменный темный фон БРС
            Color(red: 0.1, green: 0.1, blue: 0.12)
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView().tint(.blue).scaleEffect(1.5)
            } else if let profile = viewModel.profile {
                ScrollView {
                    VStack(spacing: 24) {
                        let role = profile.role.lowercased()
                        
                        profileHeaderBlock(profile: profile)
                        
                        if role == "user" {
                            
                            analyticsGridBlock(profile: profile)
                            
                            guestAccordionSections(profile: profile)
                            
                        } else {
                            
                            managerBlock(profile: profile)
                        }
                    }
                    .padding(.vertical)
                }
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
            if viewModel.profile == nil && !viewModel.isLoading {
                await viewModel.loadProfile()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.profile != nil {
                    Button(action: { isShowingEditProfile = true }) {
                        Image(systemName: "gearshape")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingEditProfile) {
            if let currentProfile = viewModel.profile {
                EditProfileView(currentProfile: currentProfile) {
                    Task {
                        // 🌟 ИСПРАВЛЕНО: Вызываем ваш реальный, существующий метод загрузки
                        await viewModel.loadProfile()
                    }
                }
            }
        }
    }
    
    // MARK: - ИЗОЛИРОВАННЫЙ БЛОК 1: Хедер профиля
    @ViewBuilder
    private func profileHeaderBlock(profile: UserProfileResponse) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 90, height: 90)
                    .overlay(Circle().stroke(Color.blue.opacity(0.3), lineWidth: 2))
                Image(systemName: "person.fill").font(.system(size: 40)).foregroundColor(.blue)
            }
            Text(profile.displayUsername).font(.title2).fontWeight(.bold).foregroundColor(.white).tracking(1)
            Text(profile.safeEmail).font(.subheadline).foregroundColor(.gray)
        }
        .padding(.top, 20)
        
        HStack(spacing: 10) {
            Text(profile.displayRole).font(.caption2).fontWeight(.black).padding(.horizontal, 12).padding(.vertical, 6).background(Color.purple.opacity(0.15)).foregroundColor(.purple).cornerRadius(20)
            Text("СТАТУС: \(profile.safeBadge.uppercased())").font(.caption2).fontWeight(.black).padding(.horizontal, 12).padding(.vertical, 6).background(badgeColor(for: profile.safeBadge).opacity(0.15)).foregroundColor(badgeColor(for: profile.safeBadge)).cornerRadius(20)
        }
    }
    
        
    @ViewBuilder
    private func managerBlock(profile: UserProfileResponse) -> some View {
        VStack(spacing: 20) {
            HStack(spacing: 16) {
                Image(systemName: "briefcase.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Управление системой БРС")
                        .font(.subheadline).bold()
                        .foregroundColor(.white)
                    Text("Доступ к коммерческой аналитике и управлению меню открыт через боковое меню или веб-панель.")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
            .padding()
            .background(Color.white.opacity(0.03))
            .cornerRadius(16)
            .padding(.horizontal)
            
            VStack(spacing: 16) {
                DisclosureGroup {
                    if profile.safeRecentLogs.isEmpty {
                        Text("История активности пуста").font(.caption).foregroundColor(.gray).padding(.vertical, 8)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(profile.safeRecentLogs) { log in
                                UserLogActionRow(log: log, isLast: log.isLast(in: profile.safeRecentLogs))
                            }
                        }.padding(.top, 8)
                    }
                } label: {
                    HStack {
                        Image(systemName: "list.bullet.rectangle.fill").foregroundColor(.orange)
                        Text("История ваших действий в СУБД").fontWeight(.medium).foregroundColor(.white)
                        Spacer()
                        Text("\(profile.safeRecentLogs.count)").font(.caption).foregroundColor(.gray).padding(.horizontal, 8).padding(.vertical, 2).background(Color.white.opacity(0.05)).cornerRadius(10)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.03))
                .cornerRadius(16)
            }
            .padding(.horizontal)
        }
    }
        
    // MARK: - ИЗОЛИРОВАННЫЙ БЛОК 2: Сетка Аналитики
    @ViewBuilder
    private func analyticsGridBlock(profile: UserProfileResponse) -> some View {
        if let stats = profile.stats {
            VStack(spacing: 24) {
                VStack(spacing: 14) {
                    HStack(spacing: 14) {
                        StatCard(title: "Всего бокалов", value: stats.safeGlasses, icon: "plus.circle.fill", color: .green)
                        StatCard(title: "Выпито литров", value: stats.safeLiters, icon: "drop.fill", color: .blue)
                    }
                    HStack(spacing: 14) {
                        StatCard(title: "Любимый напиток", value: stats.safeFavoriteDrink, icon: "wineglass.fill", color: .pink)
                        StatCard(title: "Средний градус", value: stats.safeAbv, icon: "percent", color: .orange)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
        
    @ViewBuilder
    private func guestAccordionSections(profile: UserProfileResponse) -> some View {
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
                            DrunkHistoryRow(
                                item: item,
                                isLast: item.isLast(in: profile.safeDrunkHistory)
                            )
                        }
                    }
                    .padding(.top, 8)
                }
            } label: {
                HStack {
                    Image(systemName: "clock.fill").foregroundColor(.green)
                    Text("История выпитого").fontWeight(.medium).foregroundColor(.white)
                    Spacer()
                    Text("\(profile.safeDrunkHistory.count)")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(10)
                }
            }
            .padding()
            .background(Color.white.opacity(0.03))
            .cornerRadius(16)

            // БЛОК 2: Системный лог активности
            DisclosureGroup {
                if profile.safeRecentLogs.isEmpty {
                    Text("История активности пуста")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.vertical, 8)
                } else {
                    VStack(spacing: 10) {
                        ForEach(profile.safeRecentLogs) { log in
                            UserLogActionRow(
                                log: log,
                                isLast: log.isLast(in: profile.safeRecentLogs)
                            )
                        }
                    }
                    .padding(.top, 8)
                }
            } label: {
                HStack {
                    Image(systemName: "list.bullet.rectangle.fill").foregroundColor(.purple)
                    Text("Логи активности").fontWeight(.medium).foregroundColor(.white)
                    Spacer()
                    Text("\(profile.safeRecentLogs.count)")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(10)
                }
            }
            .padding()
            .background(Color.white.opacity(0.03))
            .cornerRadius(16)
        }
        .padding(.horizontal)
    }
    
    private func badgeColor(for badge: String) -> Color {
        switch badge.uppercased() {
        case "ПИВО": return .orange
        case "ПИРАТ": return .red
        case "ЭСТЕТ": return .blue
        default: return .gray
        }
    }
}

// MARK: - ВСПОМОГАТЕЛЬНЫЕ КОМПОНЕНТЫ ЯЧЕЕК (ВЕРСТКА)

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
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.04))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.02), lineWidth: 1)
        )
    }
}

// MARK: - Ячейка Истории Выпитого
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

// MARK: - Ячейка Лога Активности
struct UserLogActionRow: View {
    let log: UserLogAction
    let isLast: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(log.safeActionType.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.gray)
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Text(log.displayTimestamp)
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
                
                Text(log.safeDescription)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 4)
            
            if !isLast {
                Divider()
                    .background(Color.white.opacity(0.05))
            }
        }
    }
}
