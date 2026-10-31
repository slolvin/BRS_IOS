//
//  ProfileStatsModels.swift
//  BRS
//
//  Created by Haris York on 17.09.2026.
//

import Foundation

struct MobileStatsResponse: Decodable {
    let badge: BadgeInfo
    let favoriteDrink: String
    let periods: PeriodStats
    
    enum CodingKeys: String, CodingKey {
        case badge
        case favoriteDrink = "favorite_drink"
        case periods
    }
}

struct BadgeInfo: Decodable {
    let title: String
    let description: String
    let color: String
}

struct PeriodStats: Decodable {
    let today: MetricMetrics
    let week: MetricMetrics
    let month: MetricMetrics
    let allTime: MetricMetrics
    
    enum CodingKeys: String, CodingKey {
        case today, week, month
        case allTime = "all_time"
    }
}

struct MetricMetrics: Decodable {
    let count: Int
    let volume: Double
    let abv: Double
}
