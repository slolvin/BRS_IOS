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
    @AppStorage("appleLanguage") private var appLanguage = "ru"
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isAuthenticated {
                    MainContainerView() // Если залогинен — видит главное меню
                } else {
                    LoginView() // Если не залогинен — форму входа
                }
            }
            // Применяем локализацию ко ВСЕМУ контейнеру разом
            .environment(\.locale, Locale(identifier: appLanguage))
        }
    }
}
