//
//  AdminManagementModels.swift
//  BRS
//
//  Created by Haris York on 18.09.2026.
//

import Foundation

struct AdminUsersResponse: Decodable {
    let status: String
    let users: [AdminUserItem]
}

struct AdminUserItem: Decodable, Identifiable, Hashable {
    let id: Int
    let username: String
    let email: String
    var role: String
    let name: String
    let location: String
    let aboutMe: String
    let confirmed: Bool
    
    var displayRole: String {
        role.lowercased() == "user" ? "User" : role.capitalized
    }
    
    enum CodingKeys: String, CodingKey {
        case id, username, email, role, name, location, confirmed
        case aboutMe = "about_me"
    }
    
    // 🌟 КАСКРАДНАЯ ЗАЩИТА ОТ MISSING DATA / NULL ЗНАЧЕНИЙ В Postgres
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(Int.self, forKey: .id)
        self.username = try container.decode(String.self, forKey: .username)
        self.email = try container.decode(String.self, forKey: .email)
        self.role = try container.decode(String.self, forKey: .role)
        
        // Личные данные могут отсутствовать или быть null в базе у новых юзеров
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        self.location = try container.decodeIfPresent(String.self, forKey: .location) ?? ""
        self.aboutMe = try container.decodeIfPresent(String.self, forKey: .aboutMe) ?? ""
        
        // Защита флага авторизации
        self.confirmed = try container.decodeIfPresent(Bool.self, forKey: .confirmed) ?? false
    }
}

struct AdminManagersResponse: Decodable {
    let status: String
    let managers: [AdminManagerItem]
}

struct AdminManagerItem: Decodable, Identifiable, Hashable {
    let id: Int
    let username: String
}
