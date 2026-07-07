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
        // Не сбрасываем profile в nil, чтобы не провоцировать резкую перерисовку экрана
        errorMessage = nil
        
        // Переключаем isLoading на главном потоке
        isLoading = true
        
        do {
            let fetchedProfile = try await service.fetchUserProfile()
            // Присваиваем данные только после успешного завершения запроса
            self.profile = fetchedProfile
        } catch {
            // Проверяем, если запрос был отменен системой, не показываем ошибку пользователю
            if (error as? URLError)?.code != .cancelled {
                self.errorMessage = "Не удалось загрузить данные профиля"
                print("Сетевая ошибка: \(error)")
            }
        }
        
        isLoading = false
    }
}
