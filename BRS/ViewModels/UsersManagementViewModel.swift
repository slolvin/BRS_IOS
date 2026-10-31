//
//  UsersManagementViewModel.swift
//  BRS
//
//  Created by Haris York on 18.09.2026.
//

import Foundation
import Combine

@MainActor
final class UsersManagementViewModel: ObservableObject {
    @Published var users: [AdminUserItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    private let drinkService = DrinkService()
    
    func loadUsers(search: String = "") async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedUsers = try await drinkService.fetchManagedUsers(searchQuery: search)
            self.users = fetchedUsers
        } catch {
            self.errorMessage = error.localizedDescription
            print("❌ Ошибка панели управления пользователями БРС: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
}
