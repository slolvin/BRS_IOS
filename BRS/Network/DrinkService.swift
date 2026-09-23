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
        // 🌟 ИСПРАВЛЕНО: Убрали лишний /api/v1.0, путь теперь строится идеально ровно!
        guard let url = URL(string: "\(baseURL)/auth/login") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.httpBody = try JSONEncoder().encode(requestObj)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let serverMessage = json["message"] as? String {
                throw NSError(domain: "AuthError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: serverMessage])
            }
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
    
    func checkInAtBar(qrHash: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/bars/checkin") else {
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
        
        let body: [String: Any] = ["qr_hash": qrHash]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        // Обрабатываем ошибки бизнес-логики Flask
        if httpResponse.statusCode == 404 {
            throw NSError(domain: "BRS", code: 404, userInfo: [NSLocalizedDescriptionKey: "Невалидный QR-код. Бар не найден."])
        }
        
        guard httpResponse.statusCode == 201 else {
            throw URLError(.badServerResponse)
        }
        
        // Парсим успешное сообщение
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let message = json["message"] as? String {
            return message
        }
        
        return "Чекин успешно пройден"
    }
    
    func logDrinkAction(drinkId: Int, volume: Int = 400) async throws {
        guard let url = URL(string: "\(baseURL)/drinks/\(drinkId)/drink") else {
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
        
        // Передаем стандартный объем бокала (например, 400 мл для пива или 50 мл для шотов)
        let body: [String: Any] = ["volume": volume]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
            throw URLError(.badServerResponse)
        }
    }
    
    /// POST: Регистрация нового мобильного пользователя БРС
    func registerUser(username: String, email: String, password: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/auth/register") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "username": username,
            "email": email,
            "password": password
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        // Парсим сообщения об ошибках валидации, конфликтах (409) и т.д.
        if httpResponse.statusCode != 201 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = json["message"] as? String {
                throw NSError(domain: "BRS_Auth", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
            }
            throw URLError(.badServerResponse)
        }
        
        // Парсим успешный ответ
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let message = json["message"] as? String {
            return message
        }
        
        return "Регистрация успешна! Проверьте вашу почту."
    }
    
    func toggleBarFavorite(barId:Int) async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/bars/\(barId)/favorite") else {
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
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        // Десериализуем ответ, вытаскивая актуальный статус
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let isFav = json["isFavorite"] as? Bool {
            return isFav
        }
        return false
    }
    
    func fetchManagedBars() async throws -> [ManagedBar] {
        // baseURL подхватится автоматически из вашего класса DrinkService
        guard let url = URL(string: "\(baseURL)/user/managed_bars") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Защищаем роут Bearer-токеном, как требует декоратор @mobile_token_required на Flask
        if let token = AuthManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Пользователь не авторизован"])
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            // Автоматически переводит бэкендовский snake_case (qr_secret_hash) в свифтовый camelCase (qrSecretHash)
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            let decodedResponse = try decoder.decode(ManagedBarsResponse.self, from: data)
            return decodedResponse.bars
            
        case 403:
            throw NSError(domain: "BRS_Permission_Error", code: 403, userInfo: [NSLocalizedDescriptionKey: "Доступ запрещен. Вы не являетесь менеджером или администратором."])
        default:
            throw NSError(domain: "BRS_Server_Error", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Сервер вернул код: \(httpResponse.statusCode)"])
        }
    }
    
    
    func postNewDrink(barId: Int, body: [String: Any]) async throws {
        // Формируем URL в соответствии с роутом Flask
        guard let url = URL(string: "\(baseURL)/bars/\(barId)/drinks/add") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Защищаем роут токеном менеджера
        if let token = AuthManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Пользователь не авторизован"])
        }
        
        // Превращаем Dictionary в бинарный JSON-дата
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        // Нам достаточно статуса 201 Created для подтверждения успеха
        if httpResponse.statusCode != 201 {
            // Пытаемся вытащить ошибку из бэкенда, если она там есть
            if let jsonError = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = jsonError["message"] as? String {
                throw NSError(domain: "BRS_Server_Error", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
            }
            throw NSError(domain: "BRS_Server_Error", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Сервер вернул код: \(httpResponse.statusCode)"])
        }
    }
    
    func fetchManagedUsers(searchQuery: String = "") async throws -> [AdminUserItem] {
        // Формируем URL с query-параметром для регистронезависимого поиска ilike в Postgres
        var urlString = "\(baseURL)/admin/users"
        if !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if let encodedSearch = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                urlString += "?search=\(encodedSearch)"
            }
        }
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Защищаем роут токеном верховного админа из вашего AuthManager
        if let token = AuthManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Пользователь не авторизован"])
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase // Переводит confirmed, about_me на лету
            
            let decodedResponse = try decoder.decode(AdminUsersResponse.self, from: data)
            return decodedResponse.users
        case 403:
            throw NSError(domain: "BRS_Permission_Error", code: 403, userInfo: [NSLocalizedDescriptionKey: "Недостаточно прав. Требуется роль Administrator."])
        default:
            throw NSError(domain: "BRS_Server_Error", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Код ответа сервера: \(httpResponse.statusCode)"])
        }
    }
    
    /// POST-запрос на сохранение измененных прав и личных данных любого пользователя
    func postEditUserRights(userId: Int, body: [String: Any]) async throws {
        guard let url = URL(string: "\(baseURL)/admin/users/\(userId)/edit") else {
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
        
        // Упаковываем плоский словарь в JSON-бинарник
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        // Flask возвращает 200 OK при успешном db.session.commit()
        if httpResponse.statusCode != 200 {
            if let jsonError = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = jsonError["message"] as? String {
                throw NSError(domain: "BRS_Server_Error", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
            }
            throw NSError(domain: "BRS_Server_Error", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Не удалось сохранить права. Код: \(httpResponse.statusCode)"])
        }
    }
    
    func fetchAllManagers() async throws -> [AdminManagerItem] {
        guard let url = URL(string: "\(baseURL)/admin/managers") else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = AuthManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoded = try JSONDecoder().decode(AdminManagersResponse.self, from: data)
        return decoded.managers
    }
    
    /// Отправка измененного менеджера заведения
    func postUpdateBarManager(barId: Int, body: [String: Any]) async throws {
        guard let url = URL(string: "\(baseURL)/bars/\(barId)/edit") else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = AuthManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
    }
    
    func postEditOwnProfile(body: [String: Any]) async throws {
        guard let url = URL(string: "\(baseURL)/user/edit_profile") else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = AuthManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Пользователь не авторизован"])
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        
        if httpResponse.statusCode != 200 {
            if let jsonError = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = jsonError["message"] as? String {
                throw NSError(domain: "BRS_Error", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
            }
            throw NSError(domain: "BRS_Error", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Ошибка СУБД"])
        }
    }
    
    func postEditDrinkParams(drinkId: Int, body: [String: Any]) async throws {
        guard let url = URL(string: "\(baseURL)/drinks/\(drinkId)/edit") else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = AuthManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Пользователь не авторизован"])
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
    }
    
    func postDeleteDrink(drinkId: Int) async throws {
        guard let url = URL(string: "\(baseURL)/drinks/\(drinkId)/delete") else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = AuthManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Пользователь не авторизован"])
        }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
    }
    
    func fetchDrinkAnalytics(drinkId: Int) async throws -> DrinkAnalyticsResponse {
        guard let url = URL(string: "\(baseURL)/drinks/\(drinkId)/analytics") else {
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
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(DrinkAnalyticsResponse.self, from: data)
    }
    
    func fetchBarAnalytics(barId: Int) async throws -> DrinkAnalyticsResponse {
        guard let url = URL(string: "\(baseURL)/bars/\(barId)/analytics") else {
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
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(DrinkAnalyticsResponse.self, from: data)
    }
    
    func postOpeningHours(barId: Int, body: [String: String]) async throws {
        guard let url = URL(string: "\(baseURL)/bars/\(barId)/opening_hours") else {
            throw URLError(.badURL)
        }
       
       var request = URLRequest(url: url)
       request.httpMethod = "PUT"
        if let token = AuthManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Пользователь не авторизован"])
        }
       
       // 🌟 КРИТИЧЕСКИ ВАЖНО: Явно выставляем заголовки, чтобы Flask понял, что это JSON
       request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
       request.setValue("application/json", forHTTPHeaderField: "Accept")
       
       // Используем системный кодер вместо старого JSONSerialization
       let encoder = JSONEncoder()
       // Если на бэкенде включен convertFromSnakeCase, кодер сам соберет правильные ключи
       request.httpBody = try encoder.encode(body)
       
       // Для 100% уверенности распечатаем в консоль Xcode то, что мы отправляем наружу
       if let jsonString = String(data: request.httpBody ?? Data(), encoding: .utf8) {
           print("🚀 DEBUG STRING SENDING TO FLASK: \(jsonString)")
       }
       
       let (data, response) = try await URLSession.shared.data(for: request)
       
       guard let httpResponse = response as? HTTPURLResponse else {
           throw URLError(.badServerResponse)
       }
       
       if httpResponse.statusCode != 200 {
           print("❌ Бэкенд вернул ошибку расписания: \(httpResponse.statusCode)")
           if let errorText = String(data: data, encoding: .utf8) {
               print("📝 Текст ошибки бэкенда: \(errorText)")
           }
           throw URLError(.badServerResponse)
       }
   }
}
