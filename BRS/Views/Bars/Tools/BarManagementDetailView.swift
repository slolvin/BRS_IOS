//
//  BarManagementDetailView.swift
//  BRS
//
//  Created by Haris York on 18.09.2026.
//
import SwiftUI
import Charts

struct BarManagementDetailView: View {
    let barId: Int
    let barName: String
    let currentAddress: String
    
    @StateObject private var viewModel: BarDetailViewModel
    @StateObject private var profileViewModel: ProfileViewModel
    
    // Переменные состояния для раскрывающихся блоков аккордеонов
    @State private var isStatsExpanded = true
    @State private var isMenuExpanded = true
    @State private var selectedPeriod = "Месяц"
    @State private var selectedBarLabel: String? = nil
    let periods = ["День", "Неделя", "Месяц", "Год"]
    
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
    
    // === 🌟 ГЛАВНЫЙ СЛОЙ ВЕРСТКИ: ТЕПЕРЬ ОН АБСОЛЮТНО ПЛОСКИЙ И НЕ ПАДАЕТ ===
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // 1. Хедер карточки заведения и блок управления кадрами (ваш существующий код)
                VStack(alignment: .leading, spacing: 8) {
                    Text(barName.uppercased())
                        .font(.title2).bold().foregroundColor(.white)
                    Text(currentAddress)
                        .font(.caption).foregroundColor(.gray)
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 2. ВЫЗОВ ИЗОЛИРОВАННОГО АККОРДЕОНА КОММЕРЧЕСКОЙ СТАТИСТИКИ
                statsAccordionBlock
                
                // 3. ВЫЗОВ ИЗОЛИРОВАННОГО АККОРДЕОНА АССОРТИМЕНТА И МЕНЮ
                menuAccordionBlock
                
            }
            .padding(.vertical)
        }
        .background(Color(red: 0.12, green: 0.12, blue: 0.15).ignoresSafeArea())
        .navigationTitle("Управление баром")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadBarDetails()
            await viewModel.loadBarLiveAnalytics(barId: barId)
            await profileViewModel.loadProfile()
            if profileViewModel.profile?.role.lowercased() == "administrator" {
                await viewModel.loadAvailableManagers()
                if let currentAdminId = viewModel.bar?.adminId {
                    self.selectedManagerId = currentAdminId
                }
            }
        }
        .onAppear {
            Task { await viewModel.loadBarDetails() }
        }
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
                        Picker("Период", selection: $selectedPeriod) {
                            ForEach(periods, id: \.self) { Text($0) }
                        }
                        .pickerStyle(.segmented)
                        
                        // 🌟 ИСПРАВЛЕНО: Значения берутся из плоских изолированных методов-хелперов
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Уникальных посещений (чекинов)").font(.caption2).foregroundColor(.gray)
                                Text("\(getPortionsCount(from: analyticsData)) человек").font(.title3).bold().foregroundColor(.white)
                            }
                            Spacer()
                            Image(systemName: "person.2.fill").foregroundColor(.orange).font(.title3)
                        }
                        .padding().background(Color.white.opacity(0.02)).cornerRadius(12)
                        
                        AnalyticsInteractiveChart(
                            chartData: getChartPoints(from: analyticsData),
                            selectedPeriod: selectedPeriod,
                            selectedBarLabel: $selectedBarLabel
                        )
                        
//                        Divider()
//                            .background(Color.white.opacity(0.05))
//                            .padding(.vertical, 10)
//                        
//                        BarCategoryPieChart(pieData: getPiePoints(from: analyticsData))
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
    
    private func getPortionsCount(from data: DrinkAnalyticsResponse) -> Int {
        switch selectedPeriod {
        case "День": return data.metrics.day.portions
        case "Неделя": return data.metrics.week.portions
        case "Год": return data.metrics.year.portions
        default: return data.metrics.month.portions
        }
    }
    
    private func getChartPoints(from data: DrinkAnalyticsResponse) -> [ChartPoint] {
        switch selectedPeriod {
        case "День": return data.metrics.day.chart
        case "Неделя": return data.metrics.week.chart
        case "Год": return data.metrics.year.chart
        default: return data.metrics.month.chart
        }
    }
    
    private func getPiePoints(from data: DrinkAnalyticsResponse) -> [PieChartPoint] {
        switch selectedPeriod {
        case "День": return data.metrics.day.categoryPie
        case "Неделя": return data.metrics.week.categoryPie
        case "Год": return data.metrics.year.categoryPie
        default: return data.metrics.month.categoryPie
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

struct BarCategoryPieChart: View {
    let pieData: [PieChartPoint]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundColor(.pink)
                Text("Доли продаж по категориям алкоголя")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            if pieData.isEmpty || (pieData.count == 1 && pieData.first?.category == "Нет продаж") {
                Text("В СУБД пока отсутствуют логи транзакций пролива алкоголя.")
                    .font(.caption2)
                    .italic()
                    .foregroundColor(.gray)
                    .padding(.vertical, 8)
            } else {
                HStack(spacing: 20) {
                    // Нативный Donut-бублик БРС системы
                    Chart {
                        ForEach(pieData) { slice in
                            SectorMark(
                                angle: PlottableValue.value("Продажи", slice.count), // Явно указываем тип из-за сбоя вывода типов
                                innerRadius: .ratio(0.6),
                                angularInset: 2.0 // 🌟 ИДЕАЛЬНЫЕ ЗАЗОРЫ: Передается строго СЮДА внутри инициализатора
                            )
                            .foregroundStyle(by: PlottableValue.value("Категория", slice.category))
                        }
                    }
                    .frame(width: 120, height: 120)
                    .chartLegend(.hidden)
                    
                    // Кастомная динамическая легенда
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(pieData.enumerated()), id: \.element.id) { index, slice in
                            HStack(spacing: 6) {
                                Circle()
                                    .frame(width: 8, height: 8)
                                    .foregroundColor(getSystemColor(for: index))
                                
                                Text(slice.category)
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Text("\(slice.percentage)%")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .padding(.vertical, 6)
            }
        }
    }
    
    // Вспомогательный метод распределения цветов
    private func getSystemColor(for index: Int) -> Color {
        let colors: [Color] = [.blue, .purple, .pink, .orange, .green, .cyan]
        return colors[index % colors.count]
    }
}

struct BarManagementDrinkRow: View {
    let drink: Drink
    var onRefreshRequired: () -> Void
    
    var body: some View {
        NavigationLink(destination: DrinkManagementDetailView(drink: drink, onSaveSuccess: onRefreshRequired)) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(drink.name)
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.white)
                    
                    Text("\(drink.volume) мл • \(drink.formattedAbv)%")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text(drink.type)
                    .font(.caption2)
                    .bold()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.15))
                    .foregroundColor(.blue)
                    .cornerRadius(6)
            }
            .padding()
            .background(Color.white.opacity(0.02))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
