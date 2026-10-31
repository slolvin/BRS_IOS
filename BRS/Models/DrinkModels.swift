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
    let imageName: String
    var canRate: Bool
    var isFavorite: Bool
    
    
    let volume: Int
    let abv: Double
    
    var formattedVolume: String {
        "\(volume)"
    }
    
    var imageUrl: URL? {
        if imageName == "placeholder" || imageName == "NULL" {
            return URL(string: "\(APIConfig.serverRoot)/static/icons/placeholder.png")
        }
        
        if imageName.hasPrefix("http://") || imageName.hasPrefix("https://") {
            return URL(string: imageName)
        }
        
        return URL(string: "\(APIConfig.serverRoot)/static/drinks/\(imageName)")
    }
    
    var formattedAbv: String {
        if abv == 0.0 { return "0" }
        return abv.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", abv) : String(format: "%.1f", abv)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, type, description, score
        case barId = "bar_id"
        case imageUrl = "image_url"
        case canRate = "can_rate"
        case volume, abv
        case imageName = "image_name"
        case isFavorite = "is_favorite"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decodeIfPresent(Int.self, forKey: .id) ?? 0
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Без названия"
        self.type = try container.decodeIfPresent(String.self, forKey: .type) ?? "Другое"
        self.description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        self.imageName = try container.decodeIfPresent(String.self, forKey: .imageName) ?? "placeholder"
        self.canRate = try container.decodeIfPresent(Bool.self, forKey: .canRate) ?? false
        self.barId = try container.decodeIfPresent(Int.self, forKey: .barId)
        self.isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        
        if let scoreDouble = try? container.decodeIfPresent(Double.self, forKey: .score) {
            self.score = scoreDouble
        } else if let scoreInt = try? container.decodeIfPresent(Int.self, forKey: .score) {
            self.score = Double(scoreInt)
        } else {
            self.score = 0.0
        }
        
        if let volDouble = try? container.decodeIfPresent(Double.self, forKey: .volume) {
            self.volume = Int(volDouble)
        } else if let volInt = try? container.decodeIfPresent(Int.self, forKey: .volume) {
            self.volume = volInt
        } else {
            self.volume = 0
        }
        
        if let abvDouble = try? container.decodeIfPresent(Double.self, forKey: .abv) {
            self.abv = abvDouble
        } else if let abvInt = try? container.decodeIfPresent(Int.self, forKey: .abv) {
            self.abv = Double(abvInt)
        } else if let abvString = try? container.decodeIfPresent(String.self, forKey: .abv), let parsed = Double(abvString) {
            self.abv = parsed
        } else {
            self.abv = 0.0
        }
    }
    
    init(id: Int, name: String, type: String, description: String, score: Double, barId: Int?, imageName: String, canRate: Bool, volume: Int, abv: Double, isFavorite: Bool) {
        self.id = id
        self.name = name
        self.type = type
        self.description = description
        self.score = score
        self.barId = barId
        self.imageName = imageName
        self.canRate = canRate
        self.volume = volume
        self.abv = abv
        self.isFavorite = false
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
