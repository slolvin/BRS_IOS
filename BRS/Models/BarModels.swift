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
    var distanceRadius: Double = 3000.0
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
    var isFavorite: Bool
    let drinks: [Drink]
    let openingHours: OpeningHours
    
    var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    
    enum CodingKeys: String, CodingKey {
        case id, name, address, city, rate
        case managerName = "manager_name"
        case adminId = "admin_id"
        case drinks
        case isFavorite = "is_favorite"
        case isFavoriteAlt = "isFavorite"
        case isCheckedIn = "is_checked_in"
        case openingHours = "opening_hours"
        case openingHoursAlt = "openingHours"
    }
    
    init(from decoder: Decoder) throws {
       let container = try decoder.container(keyedBy: CodingKeys.self)
       
       self.id = try container.decodeIfPresent(Int.self, forKey: .id) ?? 0
       self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Без названия"
       self.address = try container.decodeIfPresent(String.self, forKey: .address) ?? "Адрес не указан"
       self.city = try container.decodeIfPresent(String.self, forKey: .city) ?? "Не указан"
       self.rate = try container.decodeIfPresent(Double.self, forKey: .rate) ?? 0.0
       self.managerName = try container.decodeIfPresent(String.self, forKey: .managerName) ?? "Без менеджера"
       self.adminId = try container.decodeIfPresent(Int.self, forKey: .adminId) ?? 0
       self.isCheckedIn = try container.decodeIfPresent(Bool.self, forKey: .isCheckedIn) ?? false
       self.drinks = try container.decodeIfPresent([Drink].self, forKey: .drinks) ?? []
       
       if let fav = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) {
           self.isFavorite = fav
       } else if let favAlt = try container.decodeIfPresent(Bool.self, forKey: .isFavoriteAlt) {
           self.isFavorite = favAlt
       } else {
           self.isFavorite = false
       }
       
       if let oh = try container.decodeIfPresent(OpeningHours.self, forKey: .openingHours) {
           self.openingHours = oh
       } else if let ohAlt = try container.decodeIfPresent(OpeningHours.self, forKey: .openingHoursAlt) {
           self.openingHours = ohAlt
       } else {
           self.openingHours = OpeningHours()
       }
   }
}

struct OpeningHours: Decodable, Hashable, Sendable {
    var mon: String
    var tue: String
    var wed: String
    var thu: String
    var fri: String
    var sat: String
    var sun: String

    enum CodingKeys: String, CodingKey {
        case mon = "Mon", tue = "Tue", wed = "Wed", thu = "Thu", fri = "Fri", sat = "Sat", sun = "Sun"
    }
    
    init() {
        self.mon = "12:00-02:00"
        self.tue = "12:00-02:00"
        self.wed = "12:00-02:00"
        self.thu = "12:00-02:00"
        self.fri = "12:00-04:00"
        self.sat = "12:00-04:00"
        self.sun = "12:00-02:00"
    }
    
    init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            self.mon = try container.decodeIfPresent(String.self, forKey: .mon) ?? "12:00-02:00"
            self.tue = try container.decodeIfPresent(String.self, forKey: .tue) ?? "12:00-02:00"
            self.wed = try container.decodeIfPresent(String.self, forKey: .wed) ?? "12:00-02:00"
            self.thu = try container.decodeIfPresent(String.self, forKey: .thu) ?? "12:00-02:00"
            self.fri = try container.decodeIfPresent(String.self, forKey: .fri) ?? "12:00-04:00"
            self.sat = try container.decodeIfPresent(String.self, forKey: .sat) ?? "12:00-04:00"
            self.sun = try container.decodeIfPresent(String.self, forKey: .sun) ?? "12:00-02:00"
        } else {
            let altContainer = try decoder.container(keyedBy: AltCodingKeys.self)
            self.mon = try altContainer.decodeIfPresent(String.self, forKey: .mon) ?? "12:00-02:00"
            self.tue = try altContainer.decodeIfPresent(String.self, forKey: .tue) ?? "12:00-02:00"
            self.wed = try altContainer.decodeIfPresent(String.self, forKey: .wed) ?? "12:00-02:00"
            self.thu = try altContainer.decodeIfPresent(String.self, forKey: .thu) ?? "12:00-02:00"
            self.fri = try altContainer.decodeIfPresent(String.self, forKey: .fri) ?? "12:00-04:00"
            self.sat = try altContainer.decodeIfPresent(String.self, forKey: .sat) ?? "12:00-04:00"
            self.sun = try altContainer.decodeIfPresent(String.self, forKey: .sun) ?? "12:00-02:00"
        }
    }
    
    private enum AltCodingKeys: String, CodingKey {
        case mon, tue, wed, thu, fri, sat, sun
    }
}
