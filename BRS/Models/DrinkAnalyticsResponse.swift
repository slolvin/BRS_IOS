//
//  DrinkAnalyticsResponse.swift
//  BRS
//
//  Created by Haris York on 20.09.2026.
//

import Foundation

struct DrinkAnalyticsResponse: Decodable {
    let status: String
    let drinkId: Int?
    let name: String?
    let metrics: AnalyticsMetrics
    let retentionRate: Double
    let drinksLeaderboard: [PopularDrinkItem]
    
    enum CodingKeys: String, CodingKey {
        case status, name, metrics
        case drinkId = "drink_id"
        case retentionRate = "retention_rate"
        case retentionRateAlt = "retentionRate"
        case drinksLeaderboard = "drinks_leaderboard"
        case drinksLeaderboardAlt = "drinksLeaderboard"
    }
    
    init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.status = try container.decodeIfPresent(String.self, forKey: .status) ?? "success"
            self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Напиток"
            self.drinkId = try container.decodeIfPresent(Int.self, forKey: .drinkId) ?? 0
            self.metrics = try container.decodeIfPresent(AnalyticsMetrics.self, forKey: .metrics) ?? AnalyticsMetrics()
        
            if let retentionRate = try container.decodeIfPresent(Double.self, forKey: .retentionRate) {
                self.retentionRate = retentionRate
            } else if let retentionRateAlt = try container.decodeIfPresent(Double.self, forKey: .retentionRateAlt) {
                self.retentionRate = retentionRateAlt
            } else {
                self.retentionRate = 0.0
            }
            if let list = try container.decodeIfPresent([PopularDrinkItem].self, forKey: .drinksLeaderboard) {
                    self.drinksLeaderboard = list
                } else if let listAlt = try container.decodeIfPresent([PopularDrinkItem].self, forKey: .drinksLeaderboardAlt) {
                    self.drinksLeaderboard = listAlt
                } else {
                    self.drinksLeaderboard = []
                }
        }
}

struct AnalyticsMetrics: Decodable {
    let day: PeriodMetric
    let week: PeriodMetric
    let month: PeriodMetric
    let year: PeriodMetric
    
    enum CodingKeys: String, CodingKey {
        case day, week, month, year
    }
    
    init() {
        self.day = PeriodMetric(portions: 0, liters: 0.0, chart: [], categoryPie: [], topDrink: "Нет продаж")
        self.week = PeriodMetric(portions: 0, liters: 0.0, chart: [], categoryPie: [], topDrink: "Нет продаж")
        self.month = PeriodMetric(portions: 0, liters: 0.0, chart: [], categoryPie: [], topDrink: "Нет продаж")
        self.year = PeriodMetric(portions: 0, liters: 0.0, chart: [], categoryPie: [], topDrink: "Нет продаж")
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let defaultMetric = PeriodMetric(portions: 0, liters: 0.0, chart: [], categoryPie: [], topDrink: "Нет данных")
        
        self.day = try container.decodeIfPresent(PeriodMetric.self, forKey: .day) ?? defaultMetric
        self.week = try container.decodeIfPresent(PeriodMetric.self, forKey: .week) ?? defaultMetric
        self.month = try container.decodeIfPresent(PeriodMetric.self, forKey: .month) ?? defaultMetric
        self.year = try container.decodeIfPresent(PeriodMetric.self, forKey: .year) ?? defaultMetric
    }
}

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
    
    enum CodingKeys: String, CodingKey {
        case category
        case count
        case percentage
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.category = try container.decodeIfPresent(String.self, forKey: .category) ?? "—"
        
        if let intCount = try container.decodeIfPresent(Int.self, forKey: .count) {
            self.count = intCount
        } else if let doubleCount = try container.decodeIfPresent(Double.self, forKey: .count) {
            self.count = Int(doubleCount)
        } else {
            self.count = 0
        }
        
        if let intPercent = try container.decodeIfPresent(Int.self, forKey: .percentage) {
            self.percentage = intPercent
        } else if let doublePercent = try container.decodeIfPresent(Double.self, forKey: .percentage) {
            self.percentage = Int(doublePercent)
        } else {
            self.percentage = 0
        }
    }
}

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
        case topDrink = "top_drink"
        case topDrinkAlternative = "topDrink"
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
        
        if let drink = try container.decodeIfPresent(String.self, forKey: .topDrink) {
            self.topDrink = drink
        } else if let drinkAlt = try container.decodeIfPresent(String.self, forKey: .topDrinkAlternative) {
            self.topDrink = drinkAlt
        } else {
            self.topDrink = "Данные не получены"
        }
        
        if let pie = try container.decodeIfPresent([PieChartPoint].self, forKey: .categoryPie) {
            self.categoryPie = pie
        } else if let pieAlt = try container.decodeIfPresent([PieChartPoint].self, forKey: .categoryPieAlternative) {
            self.categoryPie = pieAlt
        } else {
            self.categoryPie = []
        }
        
        if let doubleLiters = try container.decodeIfPresent(Double.self, forKey: .liters) {
            self.liters = doubleLiters
        } else if let intLiters = try container.decodeIfPresent(Int.self, forKey: .liters) {
            self.liters = Double(intLiters)
        } else {
            self.liters = 0.0
        }
    }
}

struct PopularDrinkItem: Decodable, Identifiable, Hashable {
    var id: Int { drinkId }
    let drinkId: Int
    let name: String
    let count: Int
    
    enum CodingKeys: String, CodingKey {
        case name, count
        case drinkId = "drink_id"
        case drinkIdAlt = "drinkId"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Неизвестный напиток"
        self.count = try container.decodeIfPresent(Int.self, forKey: .count) ?? 0
        
        if let idVal = try container.decodeIfPresent(Int.self, forKey: .drinkId) {
            self.drinkId = idVal
        } else if let idAlt = try container.decodeIfPresent(Int.self, forKey: .drinkIdAlt) {
            self.drinkId = idAlt
        } else {
            self.drinkId = UUID().hashValue
        }
    }
}
