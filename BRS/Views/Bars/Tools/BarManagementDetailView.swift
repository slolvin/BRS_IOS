//
//  BarManagementDetailView.swift
//  BRS
//
//  Created by Haris York on 18.09.2026.
//
import SwiftUI

enum AnalyticsPeriod: String, CaseIterable, Identifiable {
    case day = "День"
    case week = "Неделя"
    case month = "Месяц"
    case year = "Год"
    
    var id: String { self.rawValue }
}

struct BarManagementDetailView: View {
    let barId: Int
    let barName: String
    let currentAddress: String
    
    @StateObject private var viewModel: BarDetailViewModel
    @StateObject private var profileViewModel: ProfileViewModel
    
    // 🌟 ИСПРАВЛЕНО: Оставляем только один правильный типизированный массив периодов
    let periods = AnalyticsPeriod.allCases
    
    // Переменные состояния для раскрывающихся блоков аккордеонов
    @State private var isStatsExpanded = true
    @State private var isSceduleExpanded = true
    @State private var isMenuExpanded = true
    
    // 🌟 ИСПРАВЛЕНО: Задаем дефолтный период через Enum
    @State private var selectedPeriod: AnalyticsPeriod = .month
    @State private var selectedBarLabel: String? = nil
    
    // Вспомогательные стейты для управления менеджерами
    @State private var selectedManagerId: Int = 0
    
    init(barId: Int, barName: String, currentAddress: String) {
        self.barId = barId
        self.barName = barName
        self.currentAddress = currentAddress
        
        // Передаем barId во вью-модель, чтобы восстановить связь с Postgres
        _viewModel = StateObject(wrappedValue: BarDetailViewModel(barId: barId))
        _profileViewModel = StateObject(wrappedValue: ProfileViewModel())
    }
    
    // === 🌟 ГЛАВНЫЙ СЛОЙ ВЕРСТКИ ===
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // 1. Хедер карточки заведения
                VStack(alignment: .leading, spacing: 8) {
                    Text(barName.uppercased())
                        .font(.title2).bold().foregroundColor(.white)
                    Text(currentAddress)
                        .font(.caption).foregroundColor(.gray)
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
                // 1.5. БЛОК ДАННЫХ АДМИНА
                adminBlock // НЕ СТАВИМ ПРОВЕРКУ ТУТ ПОТОМУ ЧТО ЛОГИКА СИЛЬНЕЕ ЗАВЯЗАНА
                if let userRole = profileViewModel.profile?.role.lowercased(), userRole == "manager" {
                    // 1.75 БЛОК РАСПИСАНИЯ
                    sceduleBlock
                    if let analyticsData = viewModel.barAnalytics {
                        PopularityLeaderboardView(leaderboard: analyticsData.drinksLeaderboard)
                            .padding(.bottom, 10)
                    }
                    // 2. ВЫЗОВ ИЗОЛИРОВАННОГО АККОРДЕОНА КОММЕРЧЕСКОЙ СТАТИСТИКИ
                    statsAccordionBlock
                    // 3. ВЫЗОВ ИЗОЛИРОВАННОГО АККОРДЕОНА АССОРТИМЕНТА И МЕНЮ
                    menuAccordionBlock
                }
                
            }
            .padding(.vertical)
        }
        .background(Color(red: 0.12, green: 0.12, blue: 0.15).ignoresSafeArea())
        .navigationTitle("Управление баром")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Запускаем все три базовых запроса параллельно в фоне
            async let barDetails: () = viewModel.loadBarDetails()
            async let liveAnalytics: () = viewModel.loadBarLiveAnalytics(barId: barId)
            async let userProfile: () = profileViewModel.loadProfile()
            
            // Ждем выполнения всех трех задач
            _ = await (barDetails, liveAnalytics, userProfile)
            
            // Только после того, как профиль и данные загружены, проверяем админов
            if profileViewModel.profile?.role.lowercased() == "administrator" {
                await viewModel.loadAvailableManagers()
                if let currentAdminId = viewModel.bar?.adminId {
                    self.selectedManagerId = currentAdminId
                }
            }
        }
    }
    
    @ViewBuilder
    private var adminBlock: some View {
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
    }
    
    @ViewBuilder
    private var sceduleBlock: some View {
        DisclosureGroup(isExpanded: $isSceduleExpanded) {
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
        } label: {
            HStack {
                Image(systemName: "calendar").foregroundColor(.orange)
                Text("Расписание").font(.headline).foregroundColor(.white)
            }
        }
        .padding().background(Color.white.opacity(0.03)).cornerRadius(16).padding(.horizontal)
    }
    // MARK: - 📊 ИЗОЛИРОВАННЫЙ БЛОК ПОД-ПРЕДСТАВЛЕНИЯ 1: Аккордеон статистики
    @ViewBuilder
    private var statsAccordionBlock: some View {
        DisclosureGroup(isExpanded: $isStatsExpanded) {
            VStack(spacing: 16) {
                if viewModel.isAnalyticsLoading {
                    ProgressView().tint(.orange).padding()
                } else if let analyticsData = viewModel.barAnalytics {
                    
                    VStack(alignment: .leading, spacing: 14) {
                        // 🌟 ИСПРАВЛЕНО: Пикер теперь переключает чистый Enum через тэги .tag()
                        Picker("Период", selection: $selectedPeriod) {
                            ForEach(periods) { period in
                                Text(period.rawValue)
                                    .tag(period) // 🌟 КРИТИЧЕСКИ ВАЖНО: без .tag энум не свяжется со значением!
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Уникальных посещений (чекинов)").font(.caption2).foregroundColor(.gray)
                                Text("\(getPortionsCount(from: analyticsData)) человек").font(.title3).bold().foregroundColor(.white)
                            }
                            Spacer()
                            Image(systemName: "person.2.fill").foregroundColor(.orange).font(.title3)
                        }
                        .padding().background(Color.white.opacity(0.02)).cornerRadius(12)
                        
                        RetentionRateView(rate: analyticsData.retentionRate)
                        
                        AnalyticsInteractiveChart(
                            chartData: getChartPoints(from: analyticsData),
                            selectedPeriod: selectedPeriod.rawValue,
                            selectedBarLabel: $selectedBarLabel
                        )
                        
                        VStack(spacing: 10) {
                            MostPopularCategoryView(pieData: getPiePoints(from: analyticsData))
                            
                            TopDrinkView(drinkName: getTopDrink(from: analyticsData))
                        }
                        .padding(.vertical, 4)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedPeriod)
                        
                        Divider()
                            .background(Color.white.opacity(0.05))
                            .padding(.vertical, 10)
                        
                        BarCategoryPieChart(pieData: getPiePoints(from: analyticsData))
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
    }
    
    // MARK: - ХЕЛПЕРЫ ВЫБОРКИ ДАННЫХ (Полностью переведены на жесткий Enum)
    
    private func getPortionsCount(from data: DrinkAnalyticsResponse) -> Int {
        switch selectedPeriod {
        case .day: return data.metrics.day.portions
        case .week: return data.metrics.week.portions
        case .month: return data.metrics.month.portions
        case .year: return data.metrics.year.portions
        }
    }
    
    private func getChartPoints(from data: DrinkAnalyticsResponse) -> [ChartPoint] {
        switch selectedPeriod {
        case .day: return data.metrics.day.chart
        case .week: return data.metrics.week.chart
        case .month: return data.metrics.month.chart
        case .year: return data.metrics.year.chart
        }
    }
    
    private func getPiePoints(from data: DrinkAnalyticsResponse) -> [PieChartPoint] {
        switch selectedPeriod {
        case .day: return data.metrics.day.categoryPie
        case .week: return data.metrics.week.categoryPie
        case .month: return data.metrics.month.categoryPie
        case .year: return data.metrics.year.categoryPie
        }
    }
    
    private func getTopDrink(from data: DrinkAnalyticsResponse) -> String {
        switch selectedPeriod {
        case .day: return data.metrics.day.topDrink
        case .week: return data.metrics.week.topDrink
        case .month: return data.metrics.month.topDrink
        case .year: return data.metrics.year.topDrink
        }
    }

    
    // MARK: - 🛠 ИЗОЛИРОВАННЫЙ БЛОК ПОД-ПРЕДСТАВЛЕНИЯ 2: Аккордеон меню
    @ViewBuilder
    private var menuAccordionBlock: some View {
        DisclosureGroup(isExpanded: $isMenuExpanded) {
            VStack(spacing: 12) {
                
                // Кнопка добавления напитка
                NavigationLink(destination: AddDrinkView(barId: barId)) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Добавить Напиток в меню")
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.15))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.green.opacity(0.3), lineWidth: 1))
                    .cornerRadius(12)
                }
                .padding(.bottom, 4)
                
                if viewModel.bar?.drinks.isEmpty == true {
                    Text("В меню этого бара пока нет напитков.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.vertical)
                } else {
                    // 🌟 ИСПРАВЛЕНО: Цикл ForEach теперь абсолютно плоский и понятный для Xcode!
                    ForEach(viewModel.bar?.drinks ?? []) { drink in
                        BarManagementDrinkRow(drink: drink) {
                            Task { await viewModel.loadBarDetails() }
                        }
                    }
                }
            }
            .padding(.top, 10)
        } label: {
            HStack {
                Image(systemName: "wineglass.fill").foregroundColor(.blue)
                Text("Ассортимент и меню").font(.headline).foregroundColor(.white)
                Spacer()
                Text("\(viewModel.bar?.drinks.count ?? 0)")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(10)
            }
        }
        .padding().background(Color.white.opacity(0.03)).cornerRadius(16).padding(.horizontal)
    }
}
