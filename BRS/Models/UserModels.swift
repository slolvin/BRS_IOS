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
    let email: String?                // 🌟 Опционально
    let role: String
    let monthlyBadge: String?         // 🌟 Опционально
    let stats: ProfileStats?          // 🌟 Опционально на случай пустой статистики
    let recentLogs: [UserLogAction]?   // 🌟 Опционально
    let drunkHistory: [DrunkHistoryItem]? // 🌟 Опционально
    
    // Вычисляемые свойства-хелперы, чтобы в UI не пришлось писать ?? []
    var safeRecentLogs: [UserLogAction] { recentLogs ?? [] }
    var safeDrunkHistory: [DrunkHistoryItem] { drunkHistory ?? [] }
    
    enum CodingKeys: String, CodingKey {
        case id, username, email, role, stats
        case monthlyBadge = "monthly_badge"
        case recentLogs = "recent_logs"
        case drunkHistory = "drunk_history"
    }
}

// Структура для системного лога
struct UserLogAction: Decodable, Identifiable, Equatable {
    var id: String { (timestamp ?? "") + (description ?? "") }
    let actionType: String?           // 🌟 Опционально
    let description: String?          // 🌟 Опционально
    let timestamp: String?            // 🌟 Опционально
    
    enum CodingKeys: String, CodingKey {
        case description, timestamp
        case actionType = "action_type"
    }
}

// Структура для записи выпитого алкоголя
struct DrunkHistoryItem: Decodable, Identifiable, Equatable {
    let id: Int
    let drinkName: String?            // 🌟 Опционально
    let type: String?                 // 🌟 Опционально
    let volume: Int?                  // 🌟 Опционально
    let abv: Double?                  // 🌟 Опционально
    let timestamp: String?            // 🌟 Опционально
    
    enum CodingKeys: String, CodingKey {
        case id, type, volume, abv, timestamp
        case drinkName = "drink_name"
    }
}

struct ProfileStats: Decodable, Equatable {
    let totalGlasses: Int?            // 🌟 Опционально (прилетит NULL, если юзер не пил)
    let totalLiters: Double?          // 🌟 Опционально
    let avgAbv: Double?               // 🌟 Опционально
    let favoriteDrink: String?        // 🌟 Опционально
    let registeredAt: String?         // 🌟 Опционально
    
    enum CodingKeys: String, CodingKey {
        case totalGlasses = "total_matches" // проверь, совпадает ли на бэке, обычно total_glasses
        case totalLiters = "total_liters"
        case avgAbv = "avg_abv"
        case favoriteDrink = "favorite_drink"
        case registeredAt = "registered_at"
    }
    
    // Первоначальный CodingKeys из твоего кода (оставляем как у тебя):
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.totalGlasses = try container.decodeIfPresent(Int.self, forKey: .totalGlasses)
        self.totalLiters = try container.decodeIfPresent(Double.self, forKey: .totalLiters)
        self.avgAbv = try container.decodeIfPresent(Double.self, forKey: .avgAbv)
        self.favoriteDrink = try container.decodeIfPresent(String.self, forKey: .favoriteDrink)
        self.registeredAt = try container.decodeIfPresent(String.self, forKey: .registeredAt)
    }
}
