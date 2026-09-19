//
//  BarManagementDetailView.swift
//  BRS
//
//  Created by Haris York on 18.09.2026.
//
import SwiftUI

struct BarManagementDetailView: View {
    let barId: Int
    let barName: String
    let currentAddress: String
    
    @StateObject private var viewModel: BarDetailViewModel
    @StateObject private var profileViewModel = ProfileViewModel()
    @State private var selectedManagerId: Int = 0
    @State private var isShowingAddDrinkForm = false
    
    init(barId: Int, barName: String, currentAddress: String) {
        self.barId = barId
        self.barName = barName
        self.currentAddress = currentAddress
        // 🌟 Инициализируем вью-модель сразу с честным ID бара из СУБД!
        _viewModel = StateObject(wrappedValue: BarDetailViewModel(barId: barId))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Администрирование БРС")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 16) {
                        Image(systemName: "crown.fill")
                            .font(.title2)
                            .foregroundColor(.yellow)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Управляющий заведением")
                                .font(.subheadline)
                                .bold()
                                .foregroundColor(.white)
                            
                            // Проверяем роль текущего залогиненного пользователя
                            if let userRole = profileViewModel.profile?.role.lowercased(), userRole == "administrator" {
                                // Находим объект текущего выбранного менеджера в массиве для отображения его живого имени
                                let currentManagerName = viewModel.availableManagers.first(where: { $0.id == selectedManagerId })?.username.uppercased()
                                    ?? viewModel.bar?.managerName.uppercased()
                                
                                HStack {
                                    if selectedManagerId == 0 {
                                        // ФАЗА 1: Управляющий в Postgres не назначен
                                        Text("У заведения пока нет менеджера")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    } else {
                                        // ФАЗА 2: Менеджер привязан к бару (Красивый статус)
                                        HStack(spacing: 6) {
                                            Image(systemName: "person.badge.shield.checkmark.fill")
                                                .font(.caption)
                                                .foregroundColor(.green)
                                            Text("\(currentManagerName ?? "Не назначено")")
                                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    // Единая умная интерактивная кнопка-меню БРС СУБД
                                    Menu {
                                        if selectedManagerId != 0 {
                                            Button(role: .destructive, action: {
                                                selectedManagerId = 0
                                                Task { await viewModel.updateBarManager(barId: barId, managerId: 0) }
                                            }) {
                                                Label("Снять менеджера", systemImage: "person.fill.xmark")
                                            }
                                            
                                            Divider()
                                        }
                                        
                                        ForEach(viewModel.availableManagers.filter { $0.id != selectedManagerId }) { manager in
                                            Button("@\(manager.username.uppercased())") {
                                                selectedManagerId = manager.id
                                                Task { await viewModel.updateBarManager(barId: barId, managerId: manager.id) }
                                            }
                                        }
                                    } label: {
                                        // Текст кнопки меняется на лету, отражая суть действия
                                        HStack(spacing: 4) {
                                            Text(selectedManagerId == 0 ? "Назначить" : "Изменить")
                                                .font(.system(size: 12, weight: .bold))
                                            Image(systemName: "chevron.up.chevron.down")
                                                .font(.caption2)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        // Если менеджер не назначен — подсвечиваем синим, если назначен — делаем кнопку нейтрально-серой
                                        .background(selectedManagerId == 0 ? Color.blue.opacity(0.2) : Color.white.opacity(0.08))
                                        .foregroundColor(selectedManagerId == 0 ? .blue : .gray)
                                        .cornerRadius(8)
                                    }
                                }
                                .padding(.top, 4)
                                
                            } else {
                                // Обычный менеджер по-прежнему видит просто строгий текстовый статус без кнопок
                                let managerName = viewModel.bar?.managerName.uppercased() ?? "НЕ НАЗНАЧЕН"
                                Text("@\(managerName)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .padding(.top, 2)
                            }
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color(red: 0.16, green: 0.16, blue: 0.20))
                    .cornerRadius(12)
                    .onAppear {
                        // Как только экран открылся, подтягиваем id текущего менеджера в @State
                        if let adminId = viewModel.bar?.adminId {
                            self.selectedManagerId = adminId
                        }
                    }
                    .onChange(of: viewModel.bar?.adminId) { oldValue, newAdminId in
                        if let newAdminId = newAdminId {
                            self.selectedManagerId = newAdminId
                        }
                    }
                }
                .padding(.horizontal)
                // === БЛОК ОБЩИХ ДАННЫХ И ЗАТЫЧЕК ===
                VStack(alignment: .leading, spacing: 16) {
                    Text("Общая информация").font(.headline).foregroundColor(.secondary)
                    
                    // Затычка 1: Изменение фотографии заведения
                    Button(action: { /* Затычка выбора файла */ }) {
                        HStack {
                            Image(systemName: "photo.badge.plus")
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Обновить фотографию заведения")
                                    .font(.subheadline).bold()
                                Text("Файл не выбран").font(.caption).foregroundColor(.gray)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption).foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(red: 0.16, green: 0.16, blue: 0.20))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Затычка 2: Время работы и календарь
                    HStack(spacing: 14) {
                        Image(systemName: "clock.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Время работы заведения")
                                .font(.subheadline).bold()
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                Text("Сегодня: Закрыты")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color(red: 0.16, green: 0.16, blue: 0.20))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Divider().background(Color.white.opacity(0.1)).padding(.horizontal)
                
                // === АССОРТИМЕНТ И МЕНЮ БАРА ===
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Ассортимент и меню")
                            .font(.title3).bold()
                        Spacer()
                        
                        // Кнопка добавления напитка
                        Button(action: { isShowingAddDrinkForm = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                Text("Напиток")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                        }
                    }
                    
                    if viewModel.isLoading {
                        ProgressView().frame(maxWidth: .infinity).padding()
                    } else if let drinks = viewModel.bar?.drinks, !drinks.isEmpty {
                        // Рендерим нативный список позиций (Ячейки из веб-версии Jagenmeister/Smirnoff)
                        VStack(spacing: 12) {
                            ForEach(drinks, id: \.id) { drink in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(drink.name)
                                            .font(.headline)
                                            .bold()
                                            .foregroundColor(.white)
                                        
                                        // Чистый вывод без математического форматирования внутри верстки
                                        Text("\(drink.volume) мл • \(drink.formattedAbv)%")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    
                                    Text(drink.type)
                                        .font(.caption2)
                                        .bold()
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.2))
                                        .foregroundColor(.blue)
                                        .cornerRadius(6)
                                }
                                .padding()
                                .background(Color(red: 0.16, green: 0.16, blue: 0.20))
                                .cornerRadius(12)
                            }
                        }
                    } else {
                        Text("Меню бара пусто. Добавьте первый напиток.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 20)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(red: 0.12, green: 0.12, blue: 0.15).ignoresSafeArea()) // Наша темная тема
        .navigationTitle(barName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // 1. Прямо загружаем детали бара и его напитки из Postgres
            await viewModel.loadBarDetails()
            
            // 2. Подгружаем живой профиль для проверки админ-прав
            await profileViewModel.loadProfile()
            
            // 3. Если зашел верховный админ — качаем список менеджеров для Menu
            if profileViewModel.profile?.role.lowercased() == "administrator" {
                await viewModel.loadAvailableManagers()
                if let currentAdminId = viewModel.bar?.adminId {
                    self.selectedManagerId = currentAdminId
                }
            }
        }
        .sheet(isPresented: $isShowingAddDrinkForm) {
            AddDrinkFormView(barId: barId) {
                // Замыкание успеха: просто заставляем вью-модель перечитать меню,
                // ассортимент мгновенно появится на экране!
                Task {
                    viewModel.loadBarDetails()
                }
            }
        }
    }
}
