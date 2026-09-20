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
        self.day = PeriodMetric(portions: 0, liters: 0.0, chart: [], categoryPie: [])
        self.week = PeriodMetric(portions: 0, liters: 0.0, chart: [], categoryPie: [])
        self.month = PeriodMetric(portions: 0, liters: 0.0, chart: [], categoryPie: [])
        self.year = PeriodMetric(portions: 0, liters: 0.0, chart: [], categoryPie: [])
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaultMetric = PeriodMetric(portions: 0, liters: 0.0, chart: [], categoryPie: [])
        
        self.day = try container.decodeIfPresent(PeriodMetric.self, forKey: .day) ?? defaultMetric
        self.week = try container.decodeIfPresent(PeriodMetric.self, forKey: .week) ?? defaultMetric
        self.month = try container.decodeIfPresent(PeriodMetric.self, forKey: .month) ?? defaultMetric
        self.year = try container.decodeIfPresent(PeriodMetric.self, forKey: .year) ?? defaultMetric
    }
}

// 3. Структура конкретного периода с его массивами точек и пирога
struct PeriodMetric: Decodable {
    let portions: Int
    let liters: Double
    let chart: [ChartPoint]
    let categoryPie: [PieChartPoint]
    
    enum CodingKeys: String, CodingKey {
        case portions, liters, chart
        case categoryPie = "category_pie"
    }
    
    init(portions: Int, liters: Double, chart: [ChartPoint], categoryPie: [PieChartPoint]) {
        self.portions = portions
        self.liters = liters
        self.chart = chart
        self.categoryPie = categoryPie
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.portions = try container.decodeIfPresent(Int.self, forKey: .portions) ?? 0
        self.chart = try container.decodeIfPresent([ChartPoint].self, forKey: .chart) ?? []
        self.categoryPie = try container.decodeIfPresent([PieChartPoint].self, forKey: .categoryPie) ?? []
        
        if let doubleLiters = try container.decodeIfPresent(Double.self, forKey: .liters) {
            self.liters = doubleLiters
        } else if let intLiters = try container.decodeIfPresent(Int.self, forKey: .liters) {
            self.liters = Double(intLiters)
        } else {
            self.liters = 0.0
        }
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

// 5. Структура точки круговой диаграммы (Пирога)
struct PieChartPoint: Decodable, Identifiable, Hashable {
    var id: String { category }
    let category: String
    let count: Int
    let percentage: Int
    
    enum CodingKeys: String, CodingKey {
        case category, count, percentage
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.category = try container.decodeIfPresent(String.self, forKey: .category) ?? "—"
        self.count = try container.decodeIfPresent(Int.self, forKey: .count) ?? 0
        self.percentage = try container.decodeIfPresent(Int.self, forKey: .percentage) ?? 0
    }
}
