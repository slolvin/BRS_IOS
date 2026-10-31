//
//  DrinkService.swift
//  BRS
//
//  Created by Haris York on 06.06.2026.
//
import Foundation

enum NetworkError: Error, LocalizedError {
    case badURL
    case invalidResponse(statusCode: Int, message: String)
    case decodingError
    
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

struct APIErrorResponse: Decodable {
    let error: String
    let message: String
}

class DrinkService {
    
    func login(with requestObj: LoginRequest) async throws -> AuthResponse {
        guard let url = URL(string: "\(APIConfig.baseURL)/auth/login") else {
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
        guard let url = URL(string: "\(APIConfig.baseURL)/drinks?page=\(page)") else {
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
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.badURL
        }
        
        print("📝 СТАТУС ОТВЕТА СЕРВЕРА: \(httpResponse.statusCode)")
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        if httpResponse.statusCode != 200 {
            if let apiError = try? decoder.decode(APIErrorResponse.self, from: data) {
                throw NetworkError.invalidResponse(statusCode: httpResponse.statusCode, message: apiError.message)
            } else {
                throw NetworkError.invalidResponse(statusCode: httpResponse.statusCode, message: "Ошибка авторизации (Проверь логин/пароль).")
            }
        }
        
        do {
            return try decoder.decode(DrinkResponse.self, from: data)
        } catch {
            print("Ошибка декодирования: \(error)")
            throw NetworkError.decodingError
        }
    }
    
    func fetchUserProfile() async throws -> UserProfileResponse {
        guard let url = URL(string: "\(APIConfig.baseURL)/user/profile") else {
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
        
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 404 {
                await MainActor.run {
                    AuthManager.shared.logout()
                }
                throw URLError(.userAuthenticationRequired)
            }
            
            guard httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
        }
        
        return try JSONDecoder().decode(UserProfileResponse.self, from: data)
    }
    
    func fetchBarsForMap() async throws -> [BarMarker] {
        let city = UserDefaults.standard.string(forKey: "currentCity") ?? "Любляна"
        guard let encodedCity = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(APIConfig.baseURL)/bars/map?city=\(encodedCity)") else {
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
        
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 401 {
                await MainActor.run {
                    AuthManager.shared.logout()
                }
                throw URLError(.userAuthenticationRequired)
            }
            
            guard httpResponse.statusCode == 200 else {
                throw NetworkError.decodingError
            }
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let mapResponse = try decoder.decode(BarMapResponse.self, from: data)
        return mapResponse.bars
    }
    
    func fetchBarDetail(id: Int) async throws -> BarDetail {
            guard let url = URL(string: "\(APIConfig.baseURL)/bars/\(id)") else {
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
            
            let (data, _) = try await URLSession.shared.data(for: request)
            
            let barDetail = try JSONDecoder().decode(BarDetail.self, from: data)
            
            return barDetail
        }
    
    func fetchDrinkDetail(id: Int) async throws -> Drink {
            guard let url = URL(string: "\(APIConfig.baseURL)/drinks/\(id)") else {
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
            
            let (data, _) = try await URLSession.shared.data(for: request)
            
            let drink = try JSONDecoder().decode(Drink.self, from: data)
            
            return drink
        }
        
    func rateDrink(id: Int, rating: Int) async throws -> Double {
        guard let url = URL(string: "\(APIConfig.baseURL)/drinks/\(id)/rate") else {
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
        

        let (data, _) = try await URLSession.shared.data(for: request)
        
        let response = try JSONDecoder().decode(RateResponse.self, from: data)
        
        return response.newScore
    }
    
    func createNewBar(params: [String: Any]) async throws {
        guard let url = URL(string: "\(APIConfig.baseURL)/bars/create") else {
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
    
    func createNewDrink(barId: Int, body: Data, boundary: String) async throws {
        guard let url = URL(string: "\(APIConfig.baseURL)/bars/\(barId)/drinks/add") else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        print("🚨 БРС СЕТЬ: Отправляем запрос Content-Type = \(request.value(forHTTPHeaderField: "Content-Type") ?? "NIL")")
        print("🚨 БРС СЕТЬ: Все заголовки: \(request.allHTTPHeaderFields ?? [:])")
        if let token = AuthManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Пользователь не авторизован"])
        }
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
            
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 201 {
            let serverErrorText = String(data: data, encoding: .utf8) ?? "Нечитаемый ответ"
            print("❌ БРС СЕРВЕР ОТВЕТИЛ СБОЕМ (\(httpResponse.statusCode)): \(serverErrorText)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
            throw URLError(.badServerResponse)
        }
    }
    
    func checkInAtBar(qrHash: String) async throws -> String {
        guard let url = URL(string: "\(APIConfig.baseURL)/bars/checkin") else {
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
        
        if httpResponse.statusCode == 404 {
            throw NSError(domain: "BRS", code: 404, userInfo: [NSLocalizedDescriptionKey: "Невалидный QR-код. Бар не найден."])
        }
        
        guard httpResponse.statusCode == 201 else {
            throw URLError(.badServerResponse)
        }
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let message = json["message"] as? String {
            return message
        }
        
        return "Чекин успешно пройден"
    }
    
    func logDrinkAction(drinkId: Int, volume: Int = 400) async throws {
        guard let url = URL(string: "\(APIConfig.baseURL)/drinks/\(drinkId)/drink") else {
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
        
        let body: [String: Any] = ["volume": volume]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
            throw URLError(.badServerResponse)
        }
    }
    
    func registerUser(username: String, email: String, password: String) async throws -> String {
        guard let url = URL(string: "\(APIConfig.baseURL)/auth/register") else {
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
        
        if httpResponse.statusCode != 201 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = json["message"] as? String {
                throw NSError(domain: "BRS_Auth", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
            }
            throw URLError(.badServerResponse)
        }
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let message = json["message"] as? String {
            return message
        }
        
        return "Регистрация успешна! Проверьте вашу почту."
    }
    
    func toggleBarFavorite(barId: Int) async throws -> Bool {
       let urlString = "\(APIConfig.baseURL)/bars/\(barId)/favorite"
       guard let url = URL(string: urlString) else { throw URLError(.badURL) }
       
       var request = URLRequest(url: url)
       request.httpMethod = "POST"
       request.setValue("application/json", forHTTPHeaderField: "Content-Type")
       
       if let token = AuthManager.shared.getToken() {
           request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
       }
       
       let (data, response) = try await URLSession.shared.data(for: request)
       guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
           throw URLError(.badServerResponse)
       }
       
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let isFavorite = json["is_favorite"] as? Bool {
            return isFavorite
        }
       return false
   }
    
    func fetchManagedBars() async throws -> [ManagedBar] {
        guard let url = URL(string: "\(APIConfig.baseURL)/user/managed_bars") else {
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
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            let decodedResponse = try decoder.decode(ManagedBarsResponse.self, from: data)
            return decodedResponse.bars
            
        case 403:
            throw NSError(domain: "BRS_Permission_Error", code: 403, userInfo: [NSLocalizedDescriptionKey: "Доступ запрещен. Вы не являетесь менеджером или администратором."])
        default:
            throw NSError(domain: "BRS_Server_Error", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Сервер вернул код: \(httpResponse.statusCode)"])
        }
    }
    
    func fetchManagedUsers(searchQuery: String = "") async throws -> [AdminUserItem] {
        var urlString = "\(APIConfig.baseURL)/admin/users"
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
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            let decodedResponse = try decoder.decode(AdminUsersResponse.self, from: data)
            return decodedResponse.users
        case 403:
            throw NSError(domain: "BRS_Permission_Error", code: 403, userInfo: [NSLocalizedDescriptionKey: "Недостаточно прав. Требуется роль Administrator."])
        default:
            throw NSError(domain: "BRS_Server_Error", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Код ответа сервера: \(httpResponse.statusCode)"])
        }
    }
    
    func postEditUserRights(userId: Int, body: [String: Any]) async throws {
        guard let url = URL(string: "\(APIConfig.baseURL)/admin/users/\(userId)/edit") else {
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
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode != 200 {
            if let jsonError = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = jsonError["message"] as? String {
                throw NSError(domain: "BRS_Server_Error", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
            }
            throw NSError(domain: "BRS_Server_Error", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Не удалось сохранить права. Код: \(httpResponse.statusCode)"])
        }
    }
    
    func fetchAllManagers() async throws -> [AdminManagerItem] {
        guard let url = URL(string: "\(APIConfig.baseURL)/admin/managers") else { throw URLError(.badURL) }
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
    
    func postUpdateBarManager(barId: Int, body: [String: Any]) async throws {
        guard let url = URL(string: "\(APIConfig.baseURL)/bars/\(barId)/edit") else { throw URLError(.badURL) }
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
        guard let url = URL(string: "\(APIConfig.baseURL)/user/edit_profile") else { throw URLError(.badURL) }
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
        guard let url = URL(string: "\(APIConfig.baseURL)/drinks/\(drinkId)/edit") else { throw URLError(.badURL) }
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
        guard let url = URL(string: "\(APIConfig.baseURL)/drinks/\(drinkId)/delete") else { throw URLError(.badURL) }
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
        guard let url = URL(string: "\(APIConfig.baseURL)/drinks/\(drinkId)/analytics") else {
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
        guard let url = URL(string: "\(APIConfig.baseURL)/bars/\(barId)/analytics") else {
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
        guard let url = URL(string: "\(APIConfig.baseURL)/bars/\(barId)/opening_hours") else {
            throw URLError(.badURL)
        }
       
       var request = URLRequest(url: url)
       request.httpMethod = "PUT"
        if let token = AuthManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Пользователь не авторизован"])
        }
       
       request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
       request.setValue("application/json", forHTTPHeaderField: "Accept")
       
       let encoder = JSONEncoder()
       request.httpBody = try encoder.encode(body)
       
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
    
    func toggleDrinkFavorite(drinkId: Int) async throws -> Bool {
        let urlString = "\(APIConfig.baseURL)/drinks/\(drinkId)/toggle-favorite"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = AuthManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let isFavorite = json["is_favorite"] as? Bool {
            return isFavorite
        }
        return false
    }
}
