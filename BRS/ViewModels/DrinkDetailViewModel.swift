//
//  DrinkDetailViewModel.swift
//  BRS
//
//  Created by Haris York on 09.06.2026.
//

import Foundation
import Combine

@MainActor // Все обновления свойств выполняются на главном потоке
class DrinkDetailViewModel: ObservableObject {
    @Published var drink: Drink?
    @Published var isLoading = false
    @Published var userRating: Int = 0
    
    private let drinkService = DrinkService()
    let drinkId: Int
    
    init(drinkId: Int) {
        self.drinkId = drinkId
    }
    
    func loadDrink() {
        isLoading = true
        
        Task {
            do {
                // Сеть отрабатывает в фоне, а результат безопасно возвращается на MainActor
                let loadedDrink = try await drinkService.fetchDrinkDetail(id: drinkId)
                self.drink = loadedDrink
            } catch {
                print("Ошибка загрузки деталей напитка: \(error.localizedDescription)")
            }
            self.isLoading = false
        }
    }
    
    func sendRating(_ rating: Int) {
        // Если флаг canRate равен false, блокируем отправку запроса на бэкенд
        guard let currentDrink = drink, currentDrink.canRate else { return }
        
        userRating = rating
        
        // Запускаем асинхронный контекст
        Task {
            do {
                // Дожидаемся ответа от фонового сетевого слоя
                let newScore = try await drinkService.rateDrink(id: drinkId, rating: rating)
                
                // Безопасно обновляем модель прямо на главном потоке, сохраняя описание
                // И принудительно переключаем canRate в false, блокируя повторное нажатие
                self.drink = Drink(
                    id: currentDrink.id,
                    name: currentDrink.name,
                    type: currentDrink.type,
                    description: currentDrink.description,
                    score: newScore, // Новый пересчитанный score от Flask базы данных
                    barId: currentDrink.barId,
                    imageUrl: currentDrink.imageUrl,
                    canRate: false,   // 👈 Мгновенно тушим активность звездочек в UI
                    volume: 0,
                    abv: 0.0
                )
            } catch {
                print("Ошибка при отправке оценки: \(error.localizedDescription)")
            }
        }
    }
}
