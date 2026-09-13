//
//  AddBarViewModel.swift
//  BRS
//
//  Created by Haris York on 13.09.2026.
//
import Combine
import Foundation

@MainActor
class AddBarViewModel: ObservableObject {
    @Published var name = ""
    @Published var address = ""
    @Published var city = "Самара"
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    private let service = DrinkService()
    
    func createBar() async -> Bool {
        self.isLoading = true
        self.errorMessage = nil
        
        // Формируем тело для Flask jsonify
        let body: [String: Any] = [
            "name": name,
            "address": address,
            "city": city
        ]
        
        do {
            // Вызываем метод сетевого слоя (напишем его в Шаге 5)
            try await service.createNewBar(params: body)
            self.isLoading = false
            return true
        } catch {
            self.errorMessage = "Ошибка бэкенда: \(error.localizedDescription)"
            self.isLoading = false
            return false
        }
    }
}
