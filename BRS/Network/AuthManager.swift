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
    
    
    @Published var isAuthenticated: Bool = false
    private let tokenKey = "brs_jwt_token"
    
    private init() {
        // При старте приложения проверяем, есть ли уже сохраненный токен
        self.isAuthenticated = (UserDefaults.standard.string(forKey: tokenKey) != nil)
    }
    
    // Сохранить токен после успешного логина
    func saveToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
        DispatchQueue.main.async {
            self.isAuthenticated = true
        }
    }
    
    // Получить токен для сетевых запросов
    func getToken() -> String? {
        return UserDefaults.standard.string(forKey: tokenKey)
    }
    
    // Удалить токен при выходе (Sign Out)
    func logout() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        DispatchQueue.main.async {
            self.isAuthenticated = false
        }
    }
}
