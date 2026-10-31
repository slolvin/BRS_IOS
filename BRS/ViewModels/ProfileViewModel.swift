//
//  ProfileViewModel.swift
//  BRS
//
//  Created by Haris York on 06.06.2026.
//

import Foundation
import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfileResponse? = nil
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var managedBarsSummary: [ManagedBar] = []
    
    private let service = DrinkService()
    
    func loadProfile() async {
        errorMessage = nil
        
        isLoading = true
        
        do {
            let fetchedProfile = try await service.fetchUserProfile()
            self.profile = fetchedProfile
        } catch {
            if (error as? URLError)?.code != .cancelled {
                self.errorMessage = "Не удалось загрузить данные профиля"
                
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
                let fetchedBars = try await DrinkService().fetchManagedBars()
                self.managedBarsSummary = fetchedBars
            } catch {
                print("❌ Ошибка B2B-синхронизации в профиле: \(error.localizedDescription)")
            }
        }
    }
}
