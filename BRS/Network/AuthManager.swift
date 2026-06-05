//
//  AuthManager.swift
//  BRS
//
//  Created by Haris York on 06.06.2026.
//

import Foundation
import Combine

class AuthManager: ObservableObject {
    // Статический синглтон, чтобы иметь доступ к авторизации со всех экранов
    static let shared = AuthManager()
    
    @Published var isAuthenticated = false
    @Published var username = ""
    @Published var password = ""
    
    private init() {}
    
    func login(user: String, pass: String) {
        self.username = user
        self.password = pass
        self.isAuthenticated = true
    }
    
    func logout() {
        self.username = ""
        self.password = ""
        self.isAuthenticated = false
    }
}
