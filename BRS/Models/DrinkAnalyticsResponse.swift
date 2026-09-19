//
//  DrinkAnalyticsResponse.swift
//  BRS
//
//  Created by Haris York on 20.09.2026.
//

import Foundation

struct DrinkAnalyticsResponse: Decodable {
    let status: String
    let drinkId: Int
    let name: String
    let metrics: AnalyticsMetrics
    let hourlyChart: [HourlyChartPoint]
    
    enum CodingKeys: String, CodingKey {
        case status, name, metrics
        case drinkId = "drink_id"
        case hourlyChart = "hourly_chart"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.status = try container.decodeIfPresent(String.self, forKey: .status) ?? "success"
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Напиток"
        self.drinkId = try container.decodeIfPresent(Int.self, forKey: .drinkId) ?? 0
        
        // Безопасный парсинг вложенных структур с фолбеками на пустые объекты
        self.metrics = try container.decodeIfPresent(AnalyticsMetrics.self, forKey: .metrics) ?? AnalyticsMetrics()
        self.hourlyChart = try container.decodeIfPresent([HourlyChartPoint].self, forKey: .hourlyChart) ?? []
    }
}

struct AnalyticsMetrics: Decodable {
    let day: PeriodMetric
    let week: PeriodMetric
    let month: PeriodMetric
    let year: PeriodMetric
    
    struct PeriodMetric: Decodable {
        let portions: Int
        let liters: Double
        
        enum CodingKeys: String, CodingKey {
            case portions, liters
        }
        
        init(portions: Int, liters: Double) {
            self.portions = portions
            self.liters = liters
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.portions = try container.decodeIfPresent(Int.self, forKey: .portions) ?? 0
            
            // Фикс типов: если Flask прислал 3 вместо 3.0, decode подставит Double корректно
            if let doubleLiters = try container.decodeIfPresent(Double.self, forKey: .liters) {
                self.liters = doubleLiters
            } else if let intLiters = try container.decodeIfPresent(Int.self, forKey: .liters) {
                self.liters = Double(intLiters)
            } else {
                self.liters = 0.0
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case day, week, month, year
    }
    
    // Инициализатор по умолчанию на случай сбоя
    init() {
        self.day = PeriodMetric(portions: 0, liters: 0.0)
        self.week = PeriodMetric(portions: 0, liters: 0.0)
        self.month = PeriodMetric(portions: 0, liters: 0.0)
        self.year = PeriodMetric(portions: 0, liters: 0.0)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaultMetric = PeriodMetric(portions: 0, liters: 0.0)
        
        self.day = try container.decodeIfPresent(PeriodMetric.self, forKey: .day) ?? defaultMetric
        self.week = try container.decodeIfPresent(PeriodMetric.self, forKey: .week) ?? defaultMetric
        self.month = try container.decodeIfPresent(PeriodMetric.self, forKey: .month) ?? defaultMetric
        self.year = try container.decodeIfPresent(PeriodMetric.self, forKey: .year) ?? defaultMetric
    }
}

struct HourlyChartPoint: Decodable, Identifiable, Hashable {
    var id: String { hour }
    let hour: String
    let count: Int
    
    enum CodingKeys: String, CodingKey {
        case hour, count
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.hour = try container.decodeIfPresent(String.self, forKey: .hour) ?? "00:00"
        self.count = try container.decodeIfPresent(Int.self, forKey: .count) ?? 0
    }
}
