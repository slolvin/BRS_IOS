//
//  FavoriteDrinksView.swift
//  BRS
//
//  Created by Haris York on 19.09.2026.
//

import SwiftUI

struct FavoriteDrinksView: View {
    @StateObject private var viewModel = ProfileViewModel()
    
    @State private var localFavorites: [Drink] = []
    
    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.1, blue: 0.12)
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView()
                    .tint(.blue)
                    .scaleEffect(1.5)
            } else {
                if localFavorites.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "star.slash")
                            .font(.system(size: 64))
                            .foregroundColor(.gray.opacity(0.4))
                        
                        Text("Ваш топ напитков пока пуст")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Откройте карточку любого напитка и нажмите на звездочку в верхнем углу, чтобы добавить его сюда!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(localFavorites) { drink in
                            FavoriteDrinkRow(drink: drink)
                                .listRowBackground(Color.white.opacity(0.02))
                                .listRowSeparatorTint(Color.white.opacity(0.05))
                        }
                        .onDelete(perform: removeDrinkFromFavorites)
                    }
                    .listStyle(.plain)
                }
            }
        }
        .navigationTitle("Избранные напитки")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            print("🛰️ [БРС] Запрашиваем профиль гостя...")
            await viewModel.loadProfile()
            
            if let profile = viewModel.profile {
                print("✅ [БРС] Профиль успешно получен для юзера: \(profile.username)")
                print("📊 [БРС] Количество напитков в массиве favorite_drinks с бэка: \(profile.favoriteDrinks?.count ?? -1)")
                print("📦 [БРС] Количество элементов через safe-хелпер: \(profile.safeFavoriteDrinks.count)")
                
                self.localFavorites = profile.safeFavoriteDrinks
            } else {
                print("⚠️ [БРС ОШИБКА]: Переменная viewModel.profile равна nil!")
            }
        }
    }
    
    private func removeDrinkFromFavorites(at offsets: IndexSet) {
        if let index = offsets.first {
            let targetDrink = localFavorites[index]
            
            Task {
                do {
                    _ = try await DrinkService().toggleDrinkFavorite(drinkId: targetDrink.id)
                    print("⚙️ [БРС СУБД] Напиток \(targetDrink.name) успешно удален через toggle-favorite ручку.")
                } catch {
                    print("❌ Ошибка удаления из СУБД: \(error.localizedDescription)")
                    await MainActor.run {
                        Task { await viewModel.loadProfile() }
                    }
                }
            }
        }
        
        localFavorites.remove(atOffsets: offsets)
    }
}

struct FavoriteDrinkRow: View {
    let drink: Drink
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: drink.type.lowercased() == "beer" ? "mug.fill" : "wineglass.fill")
                    .foregroundColor(.blue)
                    .font(.body)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(drink.name)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("\(drink.type) • \(drink.formattedVolume) мл • \(drink.formattedAbv)%")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
