//
//  DrinkService.swift
//  BRS
//
//  Created by Haris York on 06.06.2026.
//
import Foundation

// 1. Обязательно объявляем типы ошибок в самом верху файла, чтобы Xcode видел их во всем проекте
enum NetworkError: Error, LocalizedError {
    case badURL
    case invalidResponse(statusCode: Int, message: String)
    case decodingError
    
    // Красивое описание ошибки для вывода пользователю в интерфейс
    var errorDescription: String? {
        switch self {
        case .badURL:
            return "Некорректный адрес сервера."
        case .invalidResponse(_, let message):
            return message
        case .decodingError:
            return "Ошибка обработки данных от сервера."
        }
    }
}

// Вспомогательная структура для парсинга ошибок твоего Flask API
struct APIErrorResponse: Decodable {
    let error: String
    let message: String
}

// 2. Сам класс сервиса
class DrinkService {
    private let baseURL = "http://localhost:8000/api/v1.0"
    
    func fetchDrinks(page: Int = 1) async throws -> DrinkResponse {
        guard let url = URL(string: "\(baseURL)/drinks/?page=\(page)") else {
            throw NetworkError.badURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // 🔐 HTTP BASIC AUTHENTICATION
        // Введи свои тестовые данные учетки из базы данных Postgres
        let username = AuthManager.shared.username
        let password = AuthManager.shared.password
        
        // Формируем строку "логин:пароль" и переводим её в Base64
        let loginString = "\(username):\(password)"
        if let loginData = loginString.data(using: .utf8) {
            let base64LoginString = loginData.base64EncodedString()
            request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        }
        
        // Выполняем запрос
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.badURL
        }
        
        print("📝 СТАТУС ОТВЕТА СЕРВЕРА: \(httpResponse.statusCode)")
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        // Если Flask ругается, парсим сообщение об ошибке
        if httpResponse.statusCode != 200 {
            if let apiError = try? decoder.decode(APIErrorResponse.self, from: data) {
                throw NetworkError.invalidResponse(statusCode: httpResponse.statusCode, message: apiError.message)
            } else {
                throw NetworkError.invalidResponse(statusCode: httpResponse.statusCode, message: "Ошибка авторизации (Проверь логин/пароль).")
            }
        }
        
        // Если всё успешно, парсим массив напитков
        do {
            return try decoder.decode(DrinkResponse.self, from: data)
        } catch {
            print("Ошибка декодирования: \(error)")
            throw NetworkError.decodingError
        }
    }
    
    func fetchUserProfile() async throws -> UserProfileResponse {
        guard let url = URL(string: "\(baseURL)/user/profile") else {
            throw NetworkError.badURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Используем те же логин/пароль из AuthManager
        let loginString = "\(AuthManager.shared.username):\(AuthManager.shared.password)"
        if let loginData = loginString.data(using: .utf8) {
            request.setValue("Basic \(loginData.base64EncodedString())", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NetworkError.decodingError
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(UserProfileResponse.self, from: data)
    }
    
    func fetchBarsForMap() async throws -> [BarMarker] {
        guard let url = URL(string: "\(baseURL)/bars/map") else {
            throw NetworkError.badURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let loginString = "\(AuthManager.shared.username):\(AuthManager.shared.password)"
        if let loginData = loginString.data(using: .utf8) {
            request.setValue("Basic \(loginData.base64EncodedString())", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NetworkError.decodingError
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let mapResponse = try decoder.decode(BarMapResponse.self, from: data)
        return mapResponse.bars
    }
}

