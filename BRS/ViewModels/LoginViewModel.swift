//
//  LoginViewModel.swift
//  BRS
//
//  Created by Haris York on 10.09.2026.
//
import Foundation
import Combine

@MainActor
class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    private let service = DrinkService()
    
    func performLogin() async -> Bool {
        guard !email.isEmpty && !password.isEmpty else {
            errorMessage = "Заполните все поля"
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        let requestObj = LoginRequest(email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password)
        
        do {
            let response = try await service.login(with: requestObj)
            
            if !response.token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                AuthManager.shared.saveToken(response.token)
                isLoading = false
                return true
            } else {
                isLoading = false
                errorMessage = "Ошибка сервера: получен пустой токен"
                return false
            }
        } catch let decodingError as DecodingError {
            isLoading = false
            switch decodingError {
            case .keyNotFound(let key, let context):
                print("🚨 БРС ДЕБАГ: Отсутствует КЛЮЧ '\(key.stringValue)' в пути: \(context.codingPath)")
                errorMessage = "Ошибка сервера: не найден ключ \(key.stringValue)"
            case .valueNotFound(let type, let context):
                print("🚨 БРС ДЕБАГ: Пустое значение типа '\(type)' в пути: \(context.codingPath)")
                errorMessage = "Ошибка сервера: пустое значение \(type)"
            default:
                print("🚨 БРС ДЕБАГ: Ошибка структуры JSON: \(decodingError)")
                errorMessage = "Ошибка обработки данных от сервера"
            }
            return false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            return false
        }
    }
}
