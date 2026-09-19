//
//  DrinkManagementDetailView.swift
//  BRS
//
//  Created by Haris York on 20.09.2026.
//

import SwiftUI
import Charts // 🌟 Подключаем нативный графический движок Apple

struct DrinkManagementDetailView: View {
    let drink: Drink
    var onSaveSuccess: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var drinkType: String
    @State private var volume: String
    @State private var abv: String
    @State private var description: String
    @State private var isSaving = false
    
    // Стейты подгрузки B2B-аналитики
    @State private var analytics: DrinkAnalyticsResponse? = nil
    @State private var isAnalyticsLoading = true
    @State private var selectedPeriod = "Месяц"
    let periods = ["День", "Неделя", "Месяц", "Год"]
    
    private let service = DrinkService()
    
    init(drink: Drink, onSaveSuccess: @escaping () -> Void) {
        self.drink = drink
        self.onSaveSuccess = onSaveSuccess
        
        _name = State(initialValue: drink.name)
        _drinkType = State(initialValue: drink.type)
        _volume = State(initialValue: "\(drink.volume)")
        _abv = State(initialValue: "\(drink.abv)")
        _description = State(initialValue: drink.description)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // === 📊 БЛОК 1: ЖИВАЯ БИЗНЕС-АНАЛИТИКА ===
                if isAnalyticsLoading {
                    VStack {
                        ProgressView().tint(.orange)
                        Text("Считаем логи Postgres...").font(.caption2).foregroundColor(.gray).padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .background(Color(red: 0.16, green: 0.16, blue: 0.20)).cornerRadius(16).padding(.horizontal)
                } else if let data = analytics {
                    businessAnalyticsBlock(data: data)
                }
                
                // === 🛠 БЛОК 2: ФОРМА ПАРАМЕТРОВ ===
                editParametersFormBlock
                
                // === 🔴 БЛОК 3: КНОПКА УДАЛЕНИЯ ===
                Button(action: { Task { await deleteDrinkFromMenu() } }) {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text("Удалить напиток из меню").fontWeight(.bold)
                    }
                    .foregroundColor(.white).padding().frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.15))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.3), lineWidth: 1))
                    .cornerRadius(12)
                }
                .padding(.horizontal).padding(.top, 8).disabled(isSaving)
            }
            .padding(.vertical)
        }
        .background(Color(red: 0.12, green: 0.12, blue: 0.15).ignoresSafeArea())
        .navigationTitle(drink.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Сохранить") { Task { await saveDrinkEdits() } }
                    .bold().disabled(isSaving || name.isEmpty)
            }
        }
        .task {
            // При открытии экрана асинхронно стягиваем агрегированные данные логов
            await loadLiveAnalytics()
        }
        .overlay {
            if isSaving { ProgressView("Обновляем СУБД...").padding().background(.ultraThinMaterial).cornerRadius(10) }
        }
    }
    
    // MARK: - 📊 РЕНДЕРИНГ ЖИВЫХ ГРАФИКОВ И МЕТРИК
    @ViewBuilder
    private func businessAnalyticsBlock(data: DrinkAnalyticsResponse) -> some View {
        let activePortions: Int = {
            switch selectedPeriod {
            case "День": return data.metrics.day.portions
            case "Неделя": return data.metrics.week.portions
            case "Год": return data.metrics.year.portions
            default: return data.metrics.month.portions
            }
        }()
        
        let activeLiters: Double = {
            switch selectedPeriod {
            case "День": return data.metrics.day.liters
            case "Неделя": return data.metrics.week.liters
            case "Год": return data.metrics.year.liters
            default: return data.metrics.month.liters
            }
        }()
        
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Коммерческая статистика").font(.caption).bold().foregroundColor(.orange)
                Spacer()
                Picker("Период", selection: $selectedPeriod) {
                    ForEach(periods, id: \.self) { Text($0) }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Заказано порций").font(.caption2).foregroundColor(.gray)
                    Text("\(activePortions) шт.").font(.title3).bold().foregroundColor(.white)
                }
                .padding().frame(maxWidth: .infinity, alignment: .leading).background(Color.white.opacity(0.03)).cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Проданный объем").font(.caption2).foregroundColor(.gray)
                    Text(String(format: "%.1f Л", activeLiters)).font(.title3).bold().foregroundColor(.blue)
                }
                .padding().frame(maxWidth: .infinity, alignment: .leading).background(Color.white.opacity(0.03)).cornerRadius(12)
            }
            
            // САМЫЙ ПЕРВЫЙ, АВТОМАТИЧЕСКИЙ ВАРИАНТ ГРАФИКА
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "chart.bar.fill").foregroundColor(.orange)
                    Text("Пики популярности по часам").font(.caption).foregroundColor(.gray)
                }
                
                Chart {
                    ForEach(data.hourlyChart) { point in
                        BarMark(
                            x: .value("Час", point.hour),
                            y: .value("Заказы", point.count)
                        )
                        .foregroundStyle(Color.orange.gradient)
                        .cornerRadius(2)
                    }
                }
                .frame(height: 100)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(red: 0.16, green: 0.16, blue: 0.20))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    // MARK: - 🛠 ПОД-БЛОК ФОРМЫ ПАРАМЕТРОВ
    @ViewBuilder
    private var editParametersFormBlock: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Редактирование параметров").font(.caption).bold().foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Название").font(.footnote).foregroundColor(.gray).frame(width: 80, alignment: .leading)
                    TextField("Например, Sprite", text: $name).textFieldStyle(.roundedBorder)
                }
                HStack {
                    Text("Категория").font(.footnote).foregroundColor(.gray).frame(width: 80, alignment: .leading)
                    TextField("Soft Drinks", text: $drinkType).textFieldStyle(.roundedBorder)
                }
                HStack {
                    Text("Объем (мл)").font(.footnote).foregroundColor(.gray).frame(width: 80, alignment: .leading)
                    TextField("0", text: $volume).keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                }
                HStack {
                    Text("Градус (%)").font(.footnote).foregroundColor(.gray).frame(width: 80, alignment: .leading)
                    TextField("0.0", text: $abv).keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Описание напитка").font(.footnote).foregroundColor(.gray)
                    TextField("Описание...", text: $description, axis: .vertical).lineLimit(2...4).textFieldStyle(.roundedBorder)
                }
            }
        }
        .padding()
        .background(Color(red: 0.16, green: 0.16, blue: 0.20))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    // MARK: - ЗАГРУЗКА И СИНХРОНИЗАЦИЯ
    
    private func loadLiveAnalytics() async {
        do {
            let fetchedAnalytics = try await service.fetchDrinkAnalytics(drinkId: drink.id)
            self.analytics = fetchedAnalytics
            self.isAnalyticsLoading = false
        } catch {
            print("❌ Ошибка сбора логов графиков БРС: \(error.localizedDescription)")
            self.isAnalyticsLoading = false
        }
    }
    
    // MARK: - ⚙️ МЕТОДЫ СИНХРОНИЗАЦИИ С БЭКЕНДОМ FLASK
    
    // 🌟 ВОССТАНОВЛЕНО: Метод сохранения изменений напитка
    private func saveDrinkEdits() async {
        isSaving = true
        let body: [String: Any] = [
            "name": name,
            "type": drinkType,
            "volume": Int(volume) ?? 0,
            "abv": Double(abv.replacingOccurrences(of: ",", with: ".")) ?? 0.0,
            "description": description
        ]
        
        do {
            try await DrinkService().postEditDrinkParams(drinkId: drink.id, body: body)
            onSaveSuccess() // Дергаем колбэк обновления СУБД
            dismiss()
        } catch {
            print("❌ Ошибка изменения напитка БРС: \(error.localizedDescription)")
        }
        isSaving = false
    }
    
    // 🌟 ВОССТАНОВЛЕНО: Метод удаления напитка из СУБД
    private func deleteDrinkFromMenu() async {
        isSaving = true
        do {
            try await DrinkService().postDeleteDrink(drinkId: drink.id)
            onSaveSuccess() // Сообщаем родителю об успешном стирании строки
            dismiss()
        } catch {
            print("❌ Ошибка удаления из СУБД БРС: \(error.localizedDescription)")
        }
        isSaving = false
    }
}
