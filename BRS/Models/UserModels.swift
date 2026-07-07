//
//  UserModels.swift
//  BRS
//
//  Created by Haris York on 06.06.2026.
//

import Foundation

struct UserProfileResponse: Decodable, Equatable {
    let id: Int
    let username: String
    let email: String
    let role: String
    let monthlyBadge: String
    let stats: ProfileStats
    let recentLogs: [UserLogAction]  // <-- Массив логов
    let drunkHistory: [DrunkHistoryItem] // <-- Массив выпитого
    
    enum CodingKeys: String, CodingKey {
        case id, username, email, role, stats
        case monthlyBadge = "monthly_badge"
        case recentLogs = "recent_logs"
        case drunkHistory = "drunk_history"
    }
}

// Структура для системного лога
struct UserLogAction: Decodable, Identifiable, Equatable {
    var id: String { timestamp + description } // Комбинированный ID для SwiftUI ForEach
    let actionType: String
    let description: String
    let timestamp: String
    
    enum CodingKeys: String, CodingKey {
        case description, timestamp
        case actionType = "action_type"
    }
}

// Структура для записи выпитого алкоголя
struct DrunkHistoryItem: Decodable, Identifiable, Equatable {
    let id: Int
    let drinkName: String
    let type: String
    let volume: Int
    let abv: Double
    let timestamp: String
    
    enum CodingKeys: String, CodingKey {
        case id, type, volume, abv, timestamp
        case drinkName = "drink_name"
    }
}

struct ProfileStats: Decodable, Equatable {
    let totalGlasses: Int
    let totalLiters: Double
    let avgAbv: Double
    let favoriteDrink: String
    let registeredAt: String
    
    enum CodingKeys: String, CodingKey {
        case totalGlasses = "total_glasses"
        case totalLiters = "total_liters"
        case avgAbv = "avg_abv"
        case favoriteDrink = "favorite_drink"
        case registeredAt = "registered_at"
    }
}
