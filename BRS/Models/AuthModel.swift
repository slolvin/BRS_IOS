//
//  AuthModel.swift
//  BRS
//
//  Created by Haris York on 10.09.2026.
//

import Foundation

// То, что мы отправляем на Flask
struct LoginRequest: Encodable {
    let email: String
    let password: String
}

// То, что Flask возвращает при успешном входе
struct AuthResponse: Decodable {
    let status: String
    let token: String
    let user: MobileUser
}

struct MobileUser: Decodable {
    let id: Int
    let username: String
    let role: String
}
