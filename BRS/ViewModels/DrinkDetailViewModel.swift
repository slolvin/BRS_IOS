//
//  DrinkDetailViewModel.swift
//  BRS
//
//  Created by Haris York on 09.06.2026.
//

import Foundation
import Combine

@MainActor
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
                let loadedDrink = try await drinkService.fetchDrinkDetail(id: drinkId)
                self.drink = loadedDrink
            } catch {
                print("Ошибка загрузки деталей напитка: \(error.localizedDescription)")
            }
            self.isLoading = false
        }
    }
    
    func sendRating(_ rating: Int) {
        guard var currentDrink = drink, currentDrink.canRate else { return }
        
        userRating = rating
        
        Task {
            do {
                let newScore = try await drinkService.rateDrink(id: drinkId, rating: rating)
                
                await MainActor.run {
                    currentDrink.score = newScore
                    currentDrink.canRate = false
                    
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
                    self.drink?.isFavorite = newStatus
                }
            } catch {
                print("❌ Ошибка переключения избранного во ViewModel: \(error.localizedDescription)")
            }
        }
    }
}
