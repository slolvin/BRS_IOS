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
    static let serverRoot = "http://192.168.64.109:8000"
    
    // Для удобства здесь же можно собрать базовый путь для обычных API-запросов
    static var baseURL: String {
        return "\(serverRoot)/api/v1.0"
    }
}
