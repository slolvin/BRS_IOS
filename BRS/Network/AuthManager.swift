//
//  AuthManager.swift
//  BRS
//
//  Created by Haris York on 06.06.2026.
//

import Foundation
import Combine

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    @Published var userRole: String = "user"
    
    @Published var isAuthenticated: Bool = false
    private let tokenKey = "brs_jwt_token"
    
    var IsCanManageBars: Bool {
        return userRole == "administrator"
    }

    var isCanManageDrinks: Bool {
        return userRole == "manager" || userRole == "administrator"
    }
    
    private init() {
        if let token = UserDefaults.standard.string(forKey: tokenKey), !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.isAuthenticated = true
        } else {
            self.isAuthenticated = false
        }
    }
    
    func saveToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
        DispatchQueue.main.async {
            self.isAuthenticated = true
        }
    }
    
    func getToken() -> String? {
        return UserDefaults.standard.string(forKey: tokenKey)
    }
    
    func logout() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        
        DispatchQueue.main.async {
            self.userRole = "user"
            self.isAuthenticated = false
        }
    }
}
