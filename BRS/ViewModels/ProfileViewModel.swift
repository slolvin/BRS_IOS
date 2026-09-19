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
    @Published var managedBarsSummary: [ManagedBar] = []
    
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
                
                // ДОБАВЬТЕ ЭТОТ ПРИНТ: Он напечатает точный ключ или тип данных, на котором споткнулся Swift
                print("❌ КРИТИЧЕСКАЯ ОШИБКА ДЕКОДИРОВАНИЯ ПРОФИЛЯ: \(error)")
            }
        }
        
        isLoading = false
        await loadManagerBusinessData()
    }
    func loadManagerBusinessData() async {
        let role = self.profile?.role.lowercased() ?? ""
        if role == "manager" || role == "administrator" {
            do {
                // Используем метод, который мы уже писали для админского хаба
                let fetchedBars = try await DrinkService().fetchManagedBars()
                self.managedBarsSummary = fetchedBars
            } catch {
                print("❌ Ошибка B2B-синхронизации в профиле: \(error.localizedDescription)")
            }
        }
    }
}
