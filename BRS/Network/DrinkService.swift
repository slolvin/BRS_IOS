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
//    private let baseURL = "http://172.20.10.2:8000/api/v1.0"
//    private let baseURL = "http://192.168.10.12:8000/api/v1.0"
//    private let baseURL = "http://172.20.10.8:8000/api/v1.0"
    private let baseURL = "http://192.168.64.109:8000/api/v1.0"
    
    func login(with requestObj: LoginRequest) async throws -> AuthResponse {
        guard let url = URL(string: "\(baseURL)/auth/login") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Кодируем объект LoginRequest в JSON-байты
        request.httpBody = try JSONEncoder().encode(requestObj)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode == 401 {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Неверный email или пароль"])
        }
        
        guard httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }
    
    func fetchDrinks(page: Int = 1) async throws -> DrinkResponse {
        guard let url = URL(string: "\(baseURL)/drinks?page=\(page)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = AuthManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Пользователь не авторизован"])
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
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // === МАГИЯ JWT: Достаем токен и прикрепляем его к запросу ===
        if let token = AuthManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Пользователь не авторизован"])
        }
        // ============================================================
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(UserProfileResponse.self, from: data)
    }
    
    func fetchBarsForMap() async throws -> [BarMarker] {
        guard let url = URL(string: "\(baseURL)/bars/map?city=\(UserDefaults.standard.string(forKey: "currentCity") ?? "Любляна")") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = AuthManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Пользователь не авторизован"])
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
    
    func fetchBarDetail(id: Int) async throws -> BarDetail {
            guard let url = URL(string: "\(baseURL)/bars/\(id)") else {
                throw URLError(.badURL)
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            if let token = AuthManager.shared.getToken() {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } else {
                throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Пользователь не авторизован"])
            }
            
            // Выполняем сетевой запрос в фоне
            let (data, _) = try await URLSession.shared.data(for: request)
            
            // Декодируем чистые данные в фоновом контексте
            let barDetail = try JSONDecoder().decode(BarDetail.self, from: data)
            
            return barDetail
        }
    
    func fetchDrinkDetail(id: Int) async throws -> Drink {
            guard let url = URL(string: "\(baseURL)/drinks/\(id)") else {
                throw URLError(.badURL)
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            if let token = AuthManager.shared.getToken() {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } else {
                throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Пользователь не авторизован"])
            }
            
            // Выполняем сетевой запрос в фоновом потоке
            let (data, _) = try await URLSession.shared.data(for: request)
            
            // Декодируем чистый Sendable объект в фоне
            let drink = try JSONDecoder().decode(Drink.self, from: data)
            
            return drink
        }
        
        // Отправка оценки на бэкенд
    func rateDrink(id: Int, rating: Int) async throws -> Double {
        guard let url = URL(string: "\(baseURL)/drinks/\(id)/rate") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = AuthManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Пользователь не авторизован"])
        }
        
        let body: [String: Int] = ["rating": rating]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        // Выполняем сетевой запрос в фоновом режиме
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // Декодируем чистый DTO-объект
        let response = try JSONDecoder().decode(RateResponse.self, from: data)
        
        return response.newScore
    }
    
    func createNewBar(params: [String: Any]) async throws {
        guard let url = URL(string: "\(baseURL)/bars/create") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = AuthManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Пользователь не авторизован"])
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: params)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
            throw URLError(.badServerResponse)
        }
    }
    
    func createNewDrink(barId: Int, params: [String: Any]) async throws {
        guard let url = URL(string: "\(baseURL)/bars/\(barId)/drinks/add") else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = AuthManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Пользователь не авторизован"])
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: params)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
            throw URLError(.badServerResponse)
        }
    }
}

