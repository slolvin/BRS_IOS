//
//  DrinksViewModel.swift
//  BRS
//
//  Created by Haris York on 06.06.2026.
//

import Foundation
import Combine

class DrinksViewModel: ObservableObject {
    @Published var drinks: [Drink] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    private let service = DrinkService()
    private var currentPage = 1
    private var canLoadMore = true
    
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
                self.errorMessage = error.localizedDescription
                print("🚨 БРЕНД-ЛОГ [NetworkError]: \(error.localizedDescription)")
            } catch {
                self.errorMessage = "Ошибка сети: \(error.localizedDescription)"
                print("🚨 БРЕНД-ЛОГ [SystemError]: \(error)")
            }
        
        isLoading = false
    }
}

