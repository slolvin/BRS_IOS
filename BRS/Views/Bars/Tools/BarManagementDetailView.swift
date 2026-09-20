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
    
    @State private var isStatsExpanded = true
    @State private var isMenuExpanded = true
    @State private var selectedPeriod = "Месяц"
    @State private var selectedBarLabel: String? = nil
    let periods = ["День", "Неделя", "Месяц", "Год"]
    
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
                VStack(spacing: 20) {
                    
                    // === 📊 АККОРДЕОН 1: СВОРАЧИВАЕМАЯ СТАТИСТИКА ЧЕКИНОВ ===
                    DisclosureGroup(isExpanded: $isStatsExpanded) {
                        VStack(spacing: 16) {
                            if viewModel.isAnalyticsLoading {
                                ProgressView().tint(.orange).padding()
                            } else if let analyticsData = viewModel.barAnalytics {
                                
                                // Вычисляем активный каунт чекин-порций по тумблеру Picker
                                let activeCheckIns: Int = {
                                    switch selectedPeriod {
                                    case "День": return analyticsData.metrics.day.portions
                                    case "Неделя": return analyticsData.metrics.week.portions
                                    case "Год": return analyticsData.metrics.year.portions
                                    default: return analyticsData.metrics.month.portions
                                    }
                                }()
                                
                                let activeChart = {
                                    switch selectedPeriod {
                                    case "День": return analyticsData.metrics.day.chart
                                    case "Неделя": return analyticsData.metrics.week.chart
                                    case "Год": return analyticsData.metrics.year.chart
                                    default: return analyticsData.metrics.month.chart
                                    }
                                }()
                                
                                VStack(alignment: .leading, spacing: 14) {
                                    // Переключатель периодов чекинов
                                    Picker("Период", selection: $selectedPeriod) {
                                        ForEach(periods, id: \.self) { Text($0) }
                                    }
                                    .pickerStyle(.segmented)
                                    
                                    // Инфо-плашка посещений
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Уникальных посещений (чекинов)").font(.caption2).foregroundColor(.gray)
                                            Text("\(activeCheckIns) человек").font(.title3).bold().foregroundColor(.white)
                                        }
                                        Spacer()
                                        Image(systemName: "person.2.fill").foregroundColor(.orange).font(.title3)
                                    }
                                    .padding().background(Color.white.opacity(0.02)).cornerRadius(12)
                                    
                                    // Вызов нашего готового интерактивного компонента графика БРС
                                    AnalyticsInteractiveChart(
                                        chartData: activeChart,
                                        selectedPeriod: selectedPeriod,
                                        selectedBarLabel: $selectedBarLabel
                                    )
                                }
                                .padding(.top, 10)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "chart.bar.xaxis").foregroundColor(.orange)
                            Text("Статистика заведения").font(.headline).foregroundColor(.white)
                        }
                    }
                    .padding().background(Color.white.opacity(0.03)).cornerRadius(16).padding(.horizontal)
                    
                    // === 🛠 АККОРДЕОН 2: СВОРАЧИВАЕМЫЙ АССОРТИМЕНТ И МЕНЮ БАРА ===
                    DisclosureGroup(isExpanded: $isMenuExpanded) {
                        VStack(spacing: 12) {
                            Button(action: { isShowingAddDrinkForm = true }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Добавить Напиток")
                                }
                                .font(.system(size: 14, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.green.opacity(0.15))
                                .foregroundColor(.green)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.green, lineWidth: 2)
                                )
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, 16)
                            if viewModel.bar?.drinks.isEmpty == true {
                                Text("В меню этого бара пока нет напитков.").font(.footnote).foregroundColor(.gray).padding(.vertical)
                            } else {
                                ForEach(viewModel.bar?.drinks ?? []) { drink in
                                    NavigationLink(destination: DrinkManagementDetailView(drink: drink) {
                                        Task { await viewModel.loadBarDetails() }
                                    }) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(drink.name).font(.subheadline).bold().foregroundColor(.white)
                                                Text("\(drink.volume) мл • \(drink.formattedAbv)%").font(.caption2).foregroundColor(.gray)
                                            }
                                            Spacer()
                                            Text(drink.type).font(.caption2).bold()
                                                .padding(.horizontal, 8).padding(.vertical, 4)
                                                .background(Color.blue.opacity(0.15)).foregroundColor(.blue).cornerRadius(6)
                                        }
                                        .padding()
                                        .background(Color.white.opacity(0.02))
                                        .cornerRadius(12)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .padding(.top, 10)
                    } label: {
                        HStack {
                            Image(systemName: "wineglass.fill").foregroundColor(.blue)
                            Text("Ассортимент и меню").font(.headline).foregroundColor(.white)
                            Spacer()
                            Text("\(viewModel.bar?.drinks.count ?? 0)").font(.caption).foregroundColor(.gray)
                                .padding(.horizontal, 8).padding(.vertical, 2).background(Color.white.opacity(0.05)).cornerRadius(10)
                        }
                    }
                    .padding().background(Color.white.opacity(0.03)).cornerRadius(16).padding(.horizontal)
                }
                // Запускаем триггер скачивания чекинов при открытии экрана заведения
                .task {
                    await viewModel.loadBarDetails()
                    await viewModel.loadBarLiveAnalytics(barId: barId)
                }
                
                Divider().background(Color.white.opacity(0.1)).padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(red: 0.12, green: 0.12, blue: 0.15).ignoresSafeArea()) // Наша темная тема
        .navigationTitle(barName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // 1. Прямо загружаем детали бара и его напитки из Postgres
            viewModel.loadBarDetails()
            
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
        .onAppear {
            Task {
                // Как только шторка редактирования напитка закрылась и менеджер вернулся назад —
                // вью-модель мгновенно скачивает свежий JSON из Postgres, и Sprite/Water обновляются на лету!
                viewModel.loadBarDetails()
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
