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
    let email: String?
    let role: String
    let monthlyBadge: String?
    let stats: ProfileStats?
    let recentLogs: [UserLogAction]?
    let drunkHistory: [DrunkHistoryItem]?
    
    // Личные данные из СУБД для редактирования
    let name: String?
    let location: String?
    let aboutMe: String?
    
    // === Хелперы для безопасного развертывания массивов ===
    var safeRecentLogs: [UserLogAction] { recentLogs ?? [] }
    var safeDrunkHistory: [DrunkHistoryItem] { drunkHistory ?? [] }
    
    // === 🌟 Хелперы личных данных для полной разгрузки компилятора в UI ===
    var displayUsername: String { username.uppercased() }
    var displayRole: String { role.uppercased() }
    var safeName: String { name?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? name! : "Имя не указано" }
    var safeLocation: String { location?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? location! : "Город не указан" }
    var safeAboutMe: String { aboutMe?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? aboutMe! : "Биография пуста" }
    var safeEmail: String { email ?? "Email не привязан" }
    var safeBadge: String { monthlyBadge ?? "Трезвенник" }
    
    enum CodingKeys: String, CodingKey {
        case id, username, email, role, stats, name, location
        case monthlyBadge = "monthly_badge"
        case recentLogs = "recent_logs"
        case drunkHistory = "drunk_history"
        case aboutMe = "about_me"
    }
}

// MARK: - Структура системного лога действий
struct UserLogAction: Decodable, Identifiable, Equatable {
    var id: String { (timestamp ?? "") + (description ?? "") }
    let actionType: String?
    let description: String?
    let timestamp: String?
    
    // === Хелперы безопасного вывода логов ===
    var safeActionType: String { actionType ?? "SYSTEM" }
    var safeDescription: String { description ?? "Действие без описания" }
    var displayTimestamp: String {
        guard let time = timestamp else { return "--:--" }
        // Если бэкенд отдает полную дату, берем только часы/минуты или оставляем строку
        return time.prefix(16).description
    }
    
    func isLast(in logs: [UserLogAction]) -> Bool {
        return self.id == logs.last?.id
    }
    
    enum CodingKeys: String, CodingKey {
        case description, timestamp
        case actionType = "action_type"
    }
}

// MARK: - Структура лога употребления алкоголя
struct DrunkHistoryItem: Decodable, Identifiable, Equatable {
    let id: Int
    let drinkName: String?
    let type: String?
    let volume: Int?
    let abv: Double?
    let timestamp: String?
    
    // === Хелперы безопасного вывода истории употребления ===
    var safeDrinkName: String { drinkName ?? "Неизвестный напиток" }
    var safeType: String { type ?? "Коктейль" }
    var safeVolume: String { volume != nil ? "\(volume!) мл" : "0 мл" }
    var safeAbv: String {
        if let abv = abv {
            return String(format: "%.1f%%", abv)
        }
        return "0.0%"
    }
    
    func isLast(in history: [DrunkHistoryItem]) -> Bool {
        return self.id == history.last?.id
    }
    
    enum CodingKeys: String, CodingKey {
        case id, type, volume, abv, timestamp
        case drinkName = "drink_name"
    }
}

// MARK: - Агрегированная статистика профиля
struct ProfileStats: Decodable, Equatable {
    let totalGlasses: Int?
    let totalLiters: Double?
    let avgAbv: Double?
    let favoriteDrink: String?
    let registeredAt: String?
    
    // === 🌟 Хелперы форматирования, убирающие String(format:) из SwiftUI-вью ===
    var safeGlasses: String {
        "\(totalGlasses ?? 0) бок."
    }
    
    var safeLiters: String {
        if let liters = totalLiters {
            return String(format: "%.2f л", liters)
        }
        return "0.00 л"
    }
    
    var safeAbv: String {
        if let abv = avgAbv {
            return String(format: "%.1f%%", abv)
        }
        return "0.0%"
    }
    
    var safeFavoriteDrink: String {
        favoriteDrink ?? "Нет любимого напитка"
    }
    
    enum CodingKeys: String, CodingKey {
        case totalGlasses = "total_matches" // Сохраняем ваш маппинг из СУБД
        case totalLiters = "total_liters"
        case avgAbv = "avg_abv"
        case favoriteDrink = "favorite_drink"
        case registeredAt = "registered_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.totalGlasses = try container.decodeIfPresent(Int.self, forKey: .totalGlasses)
        self.totalLiters = try container.decodeIfPresent(Double.self, forKey: .totalLiters)
        self.avgAbv = try container.decodeIfPresent(Double.self, forKey: .avgAbv)
        self.favoriteDrink = try container.decodeIfPresent(String.self, forKey: .favoriteDrink)
        self.registeredAt = try container.decodeIfPresent(String.self, forKey: .registeredAt)
    }
}
