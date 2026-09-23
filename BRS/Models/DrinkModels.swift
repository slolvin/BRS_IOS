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
    
    // Переводим объем в Int (миллилитры всегда целые: 50, 500), а крепость оставляем Double
    let volume: Int
    let abv: Double
    
    // 🌟 ВЫЧИСЛЯЕМЫЕ СВОЙСТВА ДЛЯ КРАСИВОГО ОТОБРАЖЕНИЯ (Без лишних нулей после запятой!)
    var formattedVolume: String {
        "\(volume)" // Выведет чистые "50" или "500" без "50,000000"
    }
    
    var formattedAbv: String {
        if abv == 0.0 { return "0" }
        // Если число целое (например, 10.0), пишем "10", если дробное (4.5) — оставляем один знак
        return abv.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", abv) : String(format: "%.1f", abv)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, type, description, score
        case barId = "bar_id"
        case imageUrl = "image_url"
        case canRate = "can_rate"
        case volume, abv
    }
    
    // 🌟 ИСПРАВЛЕННЫЙ ВСЕЯДНЫЙ ПАРСЕР
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decodeIfPresent(Int.self, forKey: .id) ?? 0
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Без названия"
        self.type = try container.decodeIfPresent(String.self, forKey: .type) ?? "Другое"
        self.description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        self.imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        self.canRate = try container.decodeIfPresent(Bool.self, forKey: .canRate) ?? false
        self.barId = try container.decodeIfPresent(Int.self, forKey: .barId)
        
        // Чтение score
        if let scoreDouble = try? container.decodeIfPresent(Double.self, forKey: .score) {
            self.score = scoreDouble
        } else if let scoreInt = try? container.decodeIfPresent(Int.self, forKey: .score) {
            self.score = Double(scoreInt)
        } else {
            self.score = 0.0
        }
        
        // 🌟 Сначала пробуем читать Double, затем Int для объема (Защита от сброса в ноль!)
        if let volDouble = try? container.decodeIfPresent(Double.self, forKey: .volume) {
            self.volume = Int(volDouble)
        } else if let volInt = try? container.decodeIfPresent(Int.self, forKey: .volume) {
            self.volume = volInt
        } else {
            self.volume = 0
        }
        
        // Сначала пробуем читать Double, затем Int для крепости (abv)
        if let abvDouble = try? container.decodeIfPresent(Double.self, forKey: .abv) {
            self.abv = abvDouble
        } else if let abvInt = try? container.decodeIfPresent(Int.self, forKey: .abv) {
            self.abv = Double(abvInt)
        } else if let abvString = try? container.decodeIfPresent(String.self, forKey: .abv), let parsed = Double(abvString) {
            // Если бэкенд отдал Decimal как строку "4.5", мы безопасно превращаем её в Double
            self.abv = parsed
        } else {
            self.abv = 0.0 // Дефолтное значение, если в базе null
        }
    }
    
    // 2. Стандартный почленный инициализатор для пересборки объекта во вью-модели
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
