//
//  DrinkAnalyticsResponse.swift
//  BRS
//
//  Created by Haris York on 20.09.2026.
//

import Foundation

struct DrinkAnalyticsResponse: Decodable {
    let status: String
    let metrics: PeriodMetrics
    
    enum CodingKeys: String, CodingKey {
        case status, metrics
    }
}

struct PeriodMetrics: Decodable {
    let day: ChartPeriodData
    let week: ChartPeriodData
    let month: ChartPeriodData
    let year: ChartPeriodData
    
    struct ChartPeriodData: Decodable {
        let portions: Int
        let liters: Double
        let chart: [ChartPoint]
        
        enum CodingKeys: String, CodingKey {
            case portions, liters, chart
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.portions = try container.decodeIfPresent(Int.self, forKey: .portions) ?? 0
            self.liters = try container.decodeIfPresent(Double.self, forKey: .liters) ?? 0.0
            self.chart = try container.decodeIfPresent([ChartPoint].self, forKey: .chart) ?? []
        }
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
