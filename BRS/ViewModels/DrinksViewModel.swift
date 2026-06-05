//
//  DrinksViewModel.swift
//  BRS
//
//  Created by Haris York on 06.06.2026.
//

import Foundation
import Combine // Обязательно добавляем для корректной работы ObservableObject!

class DrinksViewModel: ObservableObject {
    // Теперь компилятор видит переменные без конфликта изоляции актора
    @Published var drinks: [Drink] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    private let service = DrinkService()
    private var currentPage = 1
    private var canLoadMore = true
    
    // Переносим @MainActor строго на этот метод.
    // Это гарантирует, что мутация свойств @Published выполнится безопасно в главном потоке.
    @MainActor
    func loadDrinks() async {
        guard !isLoading && canLoadMore else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await service.fetchDrinks(page: currentPage)
            self.drinks.append(contentsOf: response.drinks)
            
            self.canLoadMore = response.hasNext
            if self.canLoadMore {
                self.currentPage += 1
            }
        } catch let error as NetworkError {
                // Выводим ровно то сообщение, которое прислал Flask (например, "Invalid credentials")
                self.errorMessage = error.localizedDescription
                print("🚨 БРЕНД-ЛОГ [NetworkError]: \(error.localizedDescription)")
            } catch {
                self.errorMessage = "Ошибка сети: \(error.localizedDescription)"
                print("🚨 БРЕНД-ЛОГ [SystemError]: \(error)")
            }
        
        isLoading = false
    }
}

