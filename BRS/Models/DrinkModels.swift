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
    let type: String?        // Сделали опциональным
    let description: String?   // Сделали опциональным
    let score: Double?      // Средняя оценка от Flask (может быть null)
    let barId: Int?
    let imageUrl: String?      // Сделали опциональным
    var canRate: Bool?
    
    enum CodingKeys: String, CodingKey {
            case id, name, type, description, score
            case barId = "bar_id"
            case imageUrl = "image_url"
            case canRate = "can_rate"
        }
}

// Структура ответа сервера после успешной оценки
struct RateResponse: Decodable, Sendable {
    let status: String
    let message: String
    let newScore: Double
    
    enum CodingKeys: String, CodingKey {
        case status, message
        case newScore = "new_score"
    }
}
