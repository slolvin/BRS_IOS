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
    @Published var availableManagers: [AdminManagerItem] = []
    @Published var barAnalytics: DrinkAnalyticsResponse? = nil
    @Published var isAnalyticsLoading = true
    
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
    
    func loadAvailableManagers() async {
        do {
            // fetchAllManagers() пропишем в DrinkService
            self.availableManagers = try await DrinkService().fetchAllManagers()
        } catch {
            print("❌ Ошибка загрузки списка менеджеров для Picker: \(error.localizedDescription)")
        }
    }

    /// Отправка POST-запроса на бэкенд для мгновенной смены владельца бара
    func updateBarManager(barId: Int, managerId: Int) async {
        do {
            let body: [String: Any] = ["manager_id": managerId]
            try await DrinkService().postUpdateBarManager(barId: barId, body: body)
            print(" Управляющий бара \(barId) успешно изменен в Postgres на ID: \(managerId)")
        } catch {
            print("❌ Ошибка изменения управляющего бара: \(error.localizedDescription)")
        }
    }
    
    func loadBarLiveAnalytics(barId: Int) async {
        // Не даем спамить запросами
        guard isAnalyticsLoading else { return }
        
        print("🛰️ DEBUG: Запускаем DrinkService для barId = \(barId)...")
        
        do {
            // Вызываем ваш оригинальный рабочий сервис
            let data = try await DrinkService().fetchBarAnalytics(barId: barId)
            
            // Переключаемся на Главный поток для обновления UI
            await MainActor.run {
                self.barAnalytics = data
                print(data)
                // 🌟 Вот этот принт покажет ПРАВДУ: то, что распарсилось в модель из реального DrinkService!
                print("📈 Swift УСПЕШНО прочитал из DrinkService. RetentionRate = \(data.retentionRate)%")
                self.isAnalyticsLoading = false
            }
        } catch {
            if (error as NSError).code != NSURLErrorCancelled {
                print("❌ Ошибка загрузки чекин-аналитики БРС: \(error.localizedDescription)")
            }
            await MainActor.run {
                self.isAnalyticsLoading = false
            }
        }
    }
}
