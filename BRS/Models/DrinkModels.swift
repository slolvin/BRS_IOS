//
//  DrinkModels.swift
//  BRS
//
//  Created by Haris York on 06.06.2026.
//

import Foundation

struct DrinkResponse: Decodable {
    let drinks: [Drink]
    let currentPage: Int
    let totalPages: Int
    let hasNext: Bool
    let count: Int
}

struct Drink: Decodable, Identifiable, Hashable {
    let id: Int
    let name: String
    let type: String
    let description: String
    var score: Double
    let barId: Int?
    let imageUrl: String?
    var canRate: Bool
    
    // 🌟 НОВЫЕ ПОЛЯ ПО ТЕХПАСПОРТУ И ДЛЯ ИНТЕРФЕЙСА МЕНЕДЖЕРА
    let volume: Int
    let abv: Double
    
    enum CodingKeys: String, CodingKey {
        case id, name, type, description, score
        case barId = "bar_id"
        case imageUrl = "image_url"
        case canRate = "can_rate"
        case volume, abv
    }
    
    // 🌟 ВЫЧИСЛЯЕМОЕ СВОЙСТВО: Разгружает компилятор SwiftUI, убирая String(format:) из вью
    var formattedAbv: String {
        String(format: "%.1f", abv)
    }
    
    // 1. Кастомный декодер: защищает от отсутствующих ключей и NULL-значений
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.type = try container.decodeIfPresent(String.self, forKey: .type) ?? "Пиво"
        self.description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        self.score = try container.decodeIfPresent(Double.self, forKey: .score) ?? 0.0
        self.barId = try container.decodeIfPresent(Int.self, forKey: .barId)
        self.imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        self.canRate = try container.decodeIfPresent(Bool.self, forKey: .canRate) ?? false
        
        // Безопасно парсим объем и крепость, пришедшие из бэкенда
        self.volume = try container.decodeIfPresent(Int.self, forKey: .volume) ?? 0
        self.abv = try container.decodeIfPresent(Double.self, forKey: .abv) ?? 0.0
    }
    
    // 2. Стандартный почленный инициализатор для пересборки объекта во вью-модели
    init(id: Int, name: String, type: String, description: String, score: Double, barId: Int?, imageUrl: String?, canRate: Bool, volume: Int, abv: Double) {
        self.id = id
        self.name = name
        self.type = type
        self.description = description
        self.score = score
        self.barId = barId
        self.imageUrl = imageUrl
        self.canRate = canRate
        self.volume = volume
        self.abv = abv
    }
}

struct RateResponse: Decodable, Sendable {
    let status: String
    let message: String
    let newScore: Double
    
    enum CodingKeys: String, CodingKey {
        case status, message
        case newScore = "new_score"
    }
}
