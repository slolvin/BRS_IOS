//
//  BarModels.swift
//  BRS
//
//  Created by Haris York on 06.06.2026.
//

import Foundation
import CoreLocation

// Объект для получения списка из API
struct BarMapResponse: Decodable {
    let bars: [BarMarker]
}

struct BarFilterOptions {
    var city: String = "Все города"
    var drinkType: String = "Все типы"
    var distance: String = "Любое"
    var rating: String = "Любой"
    var isOpenNow: Bool = false
}

// Модель маркера бара на карте
struct BarMarker: Decodable, Identifiable {
    let id: Int
    let name: String
    let fullAddress: String
    let rate: Double?
}

// Вспомогательная структура, которая будет хранить бар уже с просчитанными координатами
struct AnnotatedBar: Identifiable {
    let id: Int
    let name: String
    let coordinate: CLLocationCoordinate2D
}

struct BarDetail: Decodable, Identifiable, Sendable {
    let id: Int
    let name: String
    let address: String?
    let city: String?
    let rate: Double
    let managerName: String
    let adminId: Int
    let isCheckedIn: Bool
    let drinks: [Drink] // Переиспользуем структуру Drink из DrinkModels
    
    var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    
    enum CodingKeys: String, CodingKey {
        case id, name, address, city, rate
        case managerName = "manager_name"
        case adminId = "admin_id"
        case drinks
        case isCheckedIn = "isCheckedIn"
    }
}
