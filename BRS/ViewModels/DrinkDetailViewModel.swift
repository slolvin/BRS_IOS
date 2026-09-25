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
        guard var currentDrink = drink, currentDrink.canRate else { return }
        
        userRating = rating
        
        // Запускаем асинхронный контекст
        Task {
            do {
                // Дожидаемся ответа от фонового сетевого слоя
                let newScore = try await drinkService.rateDrink(id: drinkId, rating: rating)
                
                // Безопасно обновляем модель прямо на главном потоке
                await MainActor.run {
                    // Обновляем только те поля, которые изменились после голосования
                    currentDrink.score = newScore
                    currentDrink.canRate = false // 👈 Блокируем повторное нажатие звездочек
                    
                    // Переприсваиваем обновленный объект, сохраняя объем, крепость и статус избранного!
                    self.drink = currentDrink
                }
                print("⭐️ Оценка успешно отправлена. Новый скор напитка: \(newScore)")
            } catch {
                print("Ошибка при отправке оценки: \(error.localizedDescription)")
            }
        }
    }
    
    func toggleFavorite() {
        guard let drinkId = drink?.id else { return }

        Task {
            do {
                let newStatus = try await DrinkService().toggleDrinkFavorite(drinkId: drinkId)
                await MainActor.run {
                    // Обновляем статус локально, интерфейс мгновенно перерисуется
                    self.drink?.isFavorite = newStatus
                }
            } catch {
                print("❌ Ошибка переключения избранного во ViewModel: \(error.localizedDescription)")
            }
        }
    }
}
