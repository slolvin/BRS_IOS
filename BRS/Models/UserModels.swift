//
//  UserModels.swift
//  BRS
//
//  Created by Haris York on 06.06.2026.
//

import Foundation

struct UserProfileResponse: Decodable {
    let id: Int
    let username: String
    let email: String
    let role: String
    let stats: ProfileStats
}

struct ProfileStats: Decodable {
    let totalDrinksManaged: Int
    let favoriteCategory: String
    let registeredAt: String
}
