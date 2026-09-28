//
//  APIConfig.swift
//  BRS
//
//  Created by Haris York on 25.09.2026.
//

import Foundation

struct APIConfig {
    // 🌟 ЦЕНТРАЛЬНЫЙ АДРЕС ВАШЕГО СЕРВЕРА
    // Меняете здесь один раз — меняется во всем приложении!
    static let serverRoot = "http://192.168.64.113:8000"
    
    static var baseURL: String {
        return "\(serverRoot)/api/v1.0"
    }
    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    static var fullVersionString: String {
        "Version \(version) (\(build))"
    }
}
