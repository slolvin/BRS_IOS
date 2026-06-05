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
