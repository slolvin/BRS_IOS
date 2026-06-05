//
//  ProfileViewModel.swift
//  BRS
//
//  Created by Haris York on 06.06.2026.
//

import Foundation
import Combine // Обязательно добавляем для корректной работы ObservableObject!

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfileResponse? = nil
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    private let service = DrinkService()
    
    func loadProfile() async {
        isLoading = true
        errorMessage = nil
        do {
            self.profile = try await service.fetchUserProfile()
        } catch {
            self.errorMessage = "Не удалось загрузить данные профиля"
        }
        isLoading = false
    }
}
