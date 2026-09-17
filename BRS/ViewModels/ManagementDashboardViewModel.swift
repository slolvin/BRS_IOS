//
//  ManagementDashboardViewModel.swift
//  BRS
//
//  Created by Haris York on 17.09.2026.
//

import Foundation
import Combine

@MainActor // Гарантирует, что все обновления @Published идут строго на Главном Потоке UI
final class ManagementDashboardViewModel: ObservableObject {
    @Published var managedBars: [ManagedBar] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    // Используем экземпляр вашего сетевого сервиса
    private let drinkService = DrinkService()
    
    /// Асинхронная загрузка заведений, находящихся под управлением текущего менеджера/админа
    func loadManagedBars() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        
        do {
            // Вызываем метод из DrinkService (мы пропишем его ниже)
            let fetchedBars = try await drinkService.fetchManagedBars()
            self.managedBars = fetchedBars
        } catch {
            self.errorMessage = error.localizedDescription
            print("❌ Ошибка загрузки панели управления БРС: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
}
