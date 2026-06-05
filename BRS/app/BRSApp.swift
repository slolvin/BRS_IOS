//
//  BRSApp.swift
//  BRS
//
//  Created by Haris York on 06.06.2026.
//

import SwiftUI

@main
struct BRSApp: App {
    @StateObject private var authManager = AuthManager.shared
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                MainContainerView() // Если залогинен — видит список и бургер
            } else {
                LoginView() // Если не залогинен — видит окно ввода учетки
            }
        }
    }
}
