//
//  DrinkAnalyticsResponse.swift
//  BRS
//
//  Created by Haris York on 20.09.2026.
//

import Foundation

// 1. Главный корневой объект ответа бэкенда Flask
struct DrinkAnalyticsResponse: Decodable {
    let status: String
    let drinkId: Int?
    let name: String?
    let metrics: AnalyticsMetrics
    
    enum CodingKeys: String, CodingKey {
        case status, name, metrics
        case drinkId = "drink_id"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.status = try container.decodeIfPresent(String.self, forKey: .status) ?? "success"
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Напиток"
        self.drinkId = try container.decodeIfPresent(Int.self, forKey: .drinkId) ?? 0
        self.metrics = try container.decodeIfPresent(AnalyticsMetrics.self, forKey: .metrics) ?? AnalyticsMetrics()
    }
}

// 2. Структура метрик периодов
struct AnalyticsMetrics: Decodable {
    let day: PeriodMetric
    let week: PeriodMetric
    let month: PeriodMetric
    let year: PeriodMetric
    
    enum CodingKeys: String, CodingKey {
        case day, week, month, year
    }
    
    // 🌟 ИСПРАВЛЕНО: Добавлен обязательный пустой массив categoryPie во все дефолтные вызовы!
    init() {
        self.day = PeriodMetric(portions: 0, liters: 0.0, chart: [], categoryPie: [], topDrink: "Нет продаж")
        self.week = PeriodMetric(portions: 0, liters: 0.0, chart: [], categoryPie: [], topDrink: "Нет продаж")
        self.month = PeriodMetric(portions: 0, liters: 0.0, chart: [], categoryPie: [], topDrink: "Нет продаж")
        self.year = PeriodMetric(portions: 0, liters: 0.0, chart: [], categoryPie: [], topDrink: "Нет продаж")
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // ВРЕМЕННО: убираем decodeIfPresent и дефолтные значения, чтобы Xcode выкинул ошибку в консоль
        self.day = try container.decode(PeriodMetric.self, forKey: .day)
        self.week = try container.decode(PeriodMetric.self, forKey: .week)
        self.month = try container.decode(PeriodMetric.self, forKey: .month)
        self.year = try container.decode(PeriodMetric.self, forKey: .year)
    }
}

// 4. Структура точки графиков (Пн, Вт, 12:00...)
struct ChartPoint: Decodable, Identifiable, Hashable {
    var id: String { label }
    let label: String
    let count: Int
    
    enum CodingKeys: String, CodingKey {
        case label, count
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.label = try container.decodeIfPresent(String.self, forKey: .label) ?? "—"
        self.count = try container.decodeIfPresent(Int.self, forKey: .count) ?? 0
    }
}

struct PieChartPoint: Decodable, Identifiable, Hashable {
    var id: String { category }
    let category: String
    let count: Int
    let percentage: Int
    
    // Пишем альтернативные ключи на случай, если декодер глобально трансформирует их
    enum CodingKeys: String, CodingKey {
        case category
        case count
        case percentage
    }
    
    init(from decoder: Decoder) throws {
        // Проверяем оба варианта контейнеров (обычный и трансформированный декодером)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Безопасный разбор категории
        self.category = try container.decodeIfPresent(String.self, forKey: .category) ?? "—"
        
        // Защищенный разбор count (принимает Int и Double)
        if let intCount = try container.decodeIfPresent(Int.self, forKey: .count) {
            self.count = intCount
        } else if let doubleCount = try container.decodeIfPresent(Double.self, forKey: .count) {
            self.count = Int(doubleCount)
        } else {
            self.count = 0
        }
        
        // Защищенный разбор percentage (принимает Int и Double)
        if let intPercent = try container.decodeIfPresent(Int.self, forKey: .percentage) {
            self.percentage = intPercent
        } else if let doublePercent = try container.decodeIfPresent(Double.self, forKey: .percentage) {
            self.percentage = Int(doublePercent)
        } else {
            self.percentage = 0
        }
    }
}

// 2. ИСПРАВЛЕННАЯ СТРУКТУРА ПЕРИОДА
struct PeriodMetric: Decodable {
    let portions: Int
    let liters: Double
    let chart: [ChartPoint]
    let categoryPie: [PieChartPoint]
    let topDrink: String
    
    enum CodingKeys: String, CodingKey {
        case portions, liters, chart
        case categoryPie = "category_pie"
        case categoryPieAlternative = "categoryPie"
        case topDrink = "top_drink"           // Ключ, если конвертация выключена
        case topDrinkAlternative = "topDrink" // Ключ, если конвертация Snake Case ВКЛЮЧЕНА
    }
    
    init(portions: Int, liters: Double, chart: [ChartPoint], categoryPie: [PieChartPoint], topDrink: String) {
        self.portions = portions
        self.liters = liters
        self.chart = chart
        self.categoryPie = categoryPie
        self.topDrink = topDrink
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.portions = try container.decodeIfPresent(Int.self, forKey: .portions) ?? 0
        self.chart = try container.decodeIfPresent([ChartPoint].self, forKey: .chart) ?? []
        
        // 1. ПУЛЕНЕПРОБИВАЕМЫЙ РАЗБОР TOP DRINK (с учетом конвертации кейсов)
        if let drink = try container.decodeIfPresent(String.self, forKey: .topDrink) {
            self.topDrink = drink
        } else if let drinkAlt = try container.decodeIfPresent(String.self, forKey: .topDrinkAlternative) {
            self.topDrink = drinkAlt
        } else {
            // Если ключ вообще потерялся
            self.topDrink = "Данные не получены"
        }
        
        // 2. Разбор пирога категорий (уже рабочий код)
        if let pie = try container.decodeIfPresent([PieChartPoint].self, forKey: .categoryPie) {
            self.categoryPie = pie
        } else if let pieAlt = try container.decodeIfPresent([PieChartPoint].self, forKey: .categoryPieAlternative) {
            self.categoryPie = pieAlt
        } else {
            self.categoryPie = []
        }
        
        // 3. Разбор литров
        if let doubleLiters = try container.decodeIfPresent(Double.self, forKey: .liters) {
            self.liters = doubleLiters
        } else if let intLiters = try container.decodeIfPresent(Int.self, forKey: .liters) {
            self.liters = Double(intLiters)
        } else {
            self.liters = 0.0
        }
    }
}
