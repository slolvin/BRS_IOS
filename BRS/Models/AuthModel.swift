//
//  AuthModel.swift
//  BRS
//
//  Created by Haris York on 10.09.2026.
//

import Foundation

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

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
