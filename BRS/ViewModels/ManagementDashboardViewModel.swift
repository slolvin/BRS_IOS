//
//  ManagementDashboardViewModel.swift
//  BRS
//
//  Created by Haris York on 17.09.2026.
//

import Foundation
import Combine

@MainActor
final class ManagementDashboardViewModel: ObservableObject {
    @Published var managedBars: [ManagedBar] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    private let drinkService = DrinkService()
    
    func loadManagedBars() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedBars = try await drinkService.fetchManagedBars()
            self.managedBars = fetchedBars
        } catch {
            self.errorMessage = error.localizedDescription
            print("❌ Ошибка загрузки панели управления БРС: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
}
