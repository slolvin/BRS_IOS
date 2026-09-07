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
        // Базовая валидация на стороне клиента
        guard !email.isEmpty && !password.isEmpty else {
            errorMessage = "Заполните все поля"
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        let requestObj = LoginRequest(email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password)
        
        do {
            let response = try await service.login(with: requestObj)
            // Сохраняем токен в UserDefaults через наш менеджер сессии
            AuthManager.shared.saveToken(response.token)
            isLoading = false
            return true
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            return false
        }
    }
}
