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
    @State private var isShowingAddDrink = false
    
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
                            // Кнопка доступна ролям 'manager' и 'administrator'
                            if let role = profileViewModel.profile?.role.lowercased(),
                               (role == "manager" || role == "administrator") {
                                
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
                                        DrinkRowView(drink: drink)
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
                    Button("Повторить запрос") { viewModel.loadBarDetails() }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.vertical, 100)
            }
        }
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
        // 3. Асинхронно подгружаем профиль при входе на экран детализации бара
        .task {
            viewModel.loadBarDetails()
            if profileViewModel.profile == nil {
                await profileViewModel.loadProfile()
            }
        }
        .sheet(isPresented: $isShowingAddDrink, onDismiss: {
            viewModel.loadBarDetails()
        }) {
            AddDrinkView(barId: viewModel.barId)
        }
    }
}
