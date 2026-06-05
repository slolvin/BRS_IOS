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

struct Drink: Decodable, Identifiable {
    let id: Int
    let name: String
    let type: String?        // Сделали опциональным
    let description: String?   // Сделали опциональным
    let imageUrl: String?      // Сделали опциональным
}
