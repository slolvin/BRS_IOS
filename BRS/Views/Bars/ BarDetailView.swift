//
//   BarDetailView.swift
//  BRS
//
//  Created by Haris York on 09.06.2026.
//

import SwiftUI

struct BarDetailView: View {
    @StateObject var viewModel: BarDetailViewModel
    
    // 1. Добавляем ProfileViewModel для точной проверки строковой роли пользователя
    @StateObject private var profileViewModel = ProfileViewModel()
    @State private var isShowingCheckIn = false
    @State private var isShowingAddDrink = false
    @State private var localIsFavorite = false
    private let service = DrinkService()
    
    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView("Загрузка данных бара...")
                        .tint(.blue)
                    Spacer()
                }
                .frame(minHeight: 300)
            } else if let bar = viewModel.bar {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Блок основной информации о баре (без изменений)...
                    VStack(alignment: .leading, spacing: 8) {
                        Text(bar.name)
                            .font(.system(.largeTitle, design: .rounded))
                            .bold()
                        
                        if let address = bar.address {
                            HStack(alignment: .top) {
                                Text("📍")
                                Text(address)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.1f", bar.rate))
                                    .fontWeight(.bold)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.yellow.opacity(0.15))
                            .cornerRadius(8)
                            
                            Text("Менеджер: \(bar.managerName)")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    if bar.isCheckedIn {
                        // Красивая статусная плашка, если чекин в базе Flask активен
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Вы в заведении")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                                Text("Доступ к оценкам и меню БРС открыт")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                    } else {
                        // Обычная кнопка чекина, если пользователь еще не сканировал QR
                        Button(action: {
                            isShowingCheckIn = true
                        }) {
                            HStack {
                                Image(systemName: "qrcode.viewfinder")
                                Text("Чекин по QR-коду")
                                    .fontWeight(.bold)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // 2. Меню напитков бара
                    VStack(alignment: .leading, spacing: 16) {
                        
                        HStack(alignment: .center) {
                            Text("Меню напитков")
                                .font(.title2)
                                .bold()
                            
                            Spacer()
                            
                            // 2. ИСПРАВЛЕННАЯ ПРОВЕРКА РОЛИ: Читаем роль из живого профиля бэкенда.
                            if let user = profileViewModel.profile {
                                let role = user.role.lowercased()
                                
                                // Кнопка рендерится для Главного админа ИЛИ для Менеджера, который владеет конкретно этим баром
                                if role == "administrator" || (role == "manager" && bar.adminId == user.id) {
                                    Button(action: {
                                        isShowingAddDrink = true
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "plus.circle.fill")
                                            Text("Напиток")
                                                .font(.system(size: 14, weight: .bold))
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(16)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Код списка напитков ForEach и заглушки empty-стейта (без изменений)...
                        if bar.drinks.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "wineglass")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                Text("В этом баре пока нет напитков")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(bar.drinks) { drink in
                                    NavigationLink(destination: DrinkDetailView(viewModel: DrinkDetailViewModel(drinkId: drink.id))) {
                                        // 🌟 ИСПРАВЛЕНО: Прокидываем bar.isCheckedIn в каждую ячейку меню
                                        DrinkRowView(drink: drink, isBarCheckedIn: bar.isCheckedIn, onDrinkLogged: {
                                            viewModel.loadBarDetails()
                                            if let bar = viewModel.bar {
                                                self.localIsFavorite = bar.isFavorite
                                            }
                                        })
                                        .padding(.horizontal)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                }
                .padding(.vertical)
            } else {
                // Блок ошибки (без изменений)...
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    Text("Не удалось загрузить информацию")
                        .font(.headline)
                    Button("Повторить запрос") { viewModel.loadBarDetails()
                        if let bar = viewModel.bar {
                            self.localIsFavorite = bar.isFavorite
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.vertical, 100)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let bar = viewModel.bar {
                    Button(action: {
                        // Запускаем асинхронный Task для общения с Flask
                        Task {
                            do {
                                let newStatus = try await service.toggleBarFavorite(barId: bar.id)
                                // Плавно анимируем смену иконки с эффектом пружины
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                                    self.localIsFavorite = newStatus
                                }
                            } catch {
                                print("Ошибка изменения избранного БРС: \(error.localizedDescription)")
                            }
                        }
                    }) {
                        // Если лайкнут — залитое красное сердце, если нет — серый контур
                        Image(systemName: localIsFavorite ? "heart.fill" : "heart")
                            .foregroundColor(localIsFavorite ? .red : .gray)
                            .font(.title3)
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
        // 3. Асинхронно подгружаем профиль при входе на экран детализации бара
        .task {
            viewModel.loadBarDetails()
            if let bar = viewModel.bar {
                self.localIsFavorite = bar.isFavorite
            }
            if profileViewModel.profile == nil {
                await profileViewModel.loadProfile()
            }
        }
        .sheet(isPresented: $isShowingAddDrink) {
            if let bar = viewModel.bar {
                // Используем ОРИГИНАЛЬНУЮ AddDrinkFormView
                AddDrinkFormView(barId: bar.id) {
                    // Этот код выполнится ТОЛЬКО при успешном создании напитка во Flask
                    Task {
                        viewModel.loadBarDetails()
                        // Синхронизируем локальный флаг избранного, если он вам нужен
                        if let updatedBar = viewModel.bar {
                            self.localIsFavorite = updatedBar.isFavorite
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingCheckIn) {
            BarCheckInView()
        }
    }
}
