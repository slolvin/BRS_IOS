//
//  FavoriteDrinksView.swift
//  BRS
//
//  Created by Haris York on 19.09.2026.
//

import SwiftUI

struct FavoriteDrinksView: View {
    // Используем ProfileViewModel, так как в UserProfileResponse уже зашит массив drunkHistory
    @StateObject private var viewModel = ProfileViewModel()
    
    // Временное хранилище на клиенте для мгновенного визуального удаления напитка из списка при свайпе
    @State private var localHistory: [DrunkHistoryItem] = []
    
    var body: some View {
        ZStack {
            // Фирменный темный фон БРС системы v4.0
            Color(red: 0.1, green: 0.1, blue: 0.12)
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView()
                    .tint(.blue)
                    .scaleEffect(1.5)
            } else {
                if localHistory.isEmpty {
                    // Вариантность отсутствия данных (Красивая заглушка по UX)
                    VStack(spacing: 16) {
                        Image(systemName: "wineglass")
                            .font(.system(size: 64))
                            .foregroundColor(.gray.opacity(0.4))
                        
                        Text("Ваш топ напитков пока пуст")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Посетите любое заведение Самары, отсканируйте QR-код и отметьте ваш первый бокал!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding()
                } else {
                    // Выводим отфильтрованный список уникальных любимых напитков гостя
                    List {
                        ForEach(localHistory) { item in
                            FavoriteDrinkRow(item: item)
                                .listRowBackground(Color.white.opacity(0.02))
                                .listRowSeparatorTint(Color.white.opacity(0.05))
                        }
                        // 🌟 ДОБАВЛЕНО: Нативный свайп удаления элементов из списка
                        .onDelete(perform: removeDrinkFromFavorites)
                    }
                    .listStyle(.plain)
                }
            }
        }
        .navigationTitle("Избранные напитки")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Мягко загружаем данные профиля и истории при открытии экрана
            await viewModel.loadProfile()
            if let profile = viewModel.profile {
                // Фильтруем дубликаты и сохраняем в локальный стейт для поддержки анимаций свайпа
                self.localHistory = uniqueDrinks(from: profile.safeDrunkHistory)
            }
        }
    }
    
    /// Хелпер для фильтрации истории: оставляет только уникальные позиции алкоголя
    private func uniqueDrinks(from history: [DrunkHistoryItem]) -> [DrunkHistoryItem] {
        var uniqueItems: [DrunkHistoryItem] = []
        var seenNames = Set<String>()
        
        for item in history {
            let name = item.safeDrinkName
            if !seenNames.contains(name) {
                seenNames.insert(name)
                uniqueItems.append(item)
            }
        }
        return uniqueItems
    }
    
    /// 🌟 ЗАГЛУШКА ДЛЯ БУДУЩЕЙ РУЧКИ: Логика удаления напитка по свайпу
    private func removeDrinkFromFavorites(at offsets: IndexSet) {
        // Вытаскиваем ID напитка, который крестьянин решил стереть из памяти
        if let index = offsets.first {
            let targetDrink = localHistory[index]
            print("⚙️ [БРС СУБД] Заглушка удаления. Отправка POST /api/v1.0/drinks/\(targetDrink.id)/unfavorite")
        }
        
        // Мгновенно удаляем позицию из интерфейса с плавной системной анимацией
        localHistory.remove(atOffsets: offsets)
    }
}

// MARK: - ИЗОЛИРОВАННАЯ ЯЧЕЙКА НАПИТКА (Полностью очищена и исправлена)
struct FavoriteDrinkRow: View {
    let item: DrunkHistoryItem
    
    var body: some View {
        HStack(spacing: 16) {
            // Иконка категории напитка
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: item.safeType.lowercased() == "beer" ? "mug.fill" : "wineglass.fill")
                    .foregroundColor(.blue)
                    .font(.body)
            }
            
            // 🌟 ИСПРАВЛЕНО: Чистый, каноничный VStack без лишних расширений-костылей
            VStack(alignment: .leading, spacing: 4) {
                Text(item.safeDrinkName)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("\(item.safeType) • \(item.safeVolume) • \(item.safeAbv)")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Маленькая звездочка-бейдж, подчеркивающая статус "Избранного"
            Image(systemName: "star.fill")
                .font(.caption2)
                .foregroundColor(.yellow)
                .opacity(0.8)
        }
        .padding(.vertical, 4)
    }
}
