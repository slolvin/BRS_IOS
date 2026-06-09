//
//  BarDetailViewModel.swift
//  BRS
//
//  Created by Haris York on 09.06.2026.
//

import Foundation
import Combine

@MainActor // Гарантирует, что обновление @Published полей идет на Главном Потоке
class BarDetailViewModel: ObservableObject {
    @Published var bar: BarDetail?
    @Published var isLoading = false
    
    private let barService = DrinkService() //переделай под drinkservice или переименуй
    let barId: Int
    
    init(barId: Int) {
        self.barId = barId
    }
    
    func loadBarDetails() {
        isLoading = true
        
        // Запускаем асинхронную задачу
        Task {
            do {
                // Сеть отработает в фоне, а результат вернется на Главный поток
                let loadedBar = try await barService.fetchBarDetail(id: barId)
                self.bar = loadedBar
            } catch {
                print("Ошибка загрузки бара: \(error.localizedDescription)")
            }
            self.isLoading = false
        }
    }
}
