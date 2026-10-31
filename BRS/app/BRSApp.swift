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
                    MainContainerView()
                } else {
                    LoginView()
                }
            }
            .environment(\.locale, Locale(identifier: appLanguage))
        }
    }
}
