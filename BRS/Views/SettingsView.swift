//
//  SettingsView.swift
//  BRS
//
//  Created by Haris York on 07.07.2026.
//

import SwiftUI

struct SettingsView: View {
    // Сохраняем тему локально в настройки приложения
    @AppStorage("isDarkMode") private var isDarkMode = true
    @AppStorage("currentCity") private var currentCity = "Любляна"
    @State private var isSavingCity = false
    
    let availableCities = ["Самара", "Москва", "Санкт-Петербург", "Сочи"]
    
    var body: some View {
        Form {
            // СЕКЦИЯ 1: ГЕОЛОКАЦИЯ
            Section(header: Text("География поиска")) {
                Picker("Текущий город", selection: $currentCity) {
                    Text("Любляна").tag("Любляна")
                    Text("Самара").tag("Самара")
                    Text("Москва").tag("Москва")
                }
            }
            .listRowBackground(Color.white.opacity(0.04))
            
            // СЕКЦИЯ 2: ВИЗУАЛЬНЫЕ ШКУРКИ КАРТЫ
            Section(header: Text("Оформление карты").foregroundColor(.gray)) {
                Toggle(isOn: $isDarkMode) {
                    HStack(spacing: 12) {
                        Image(systemName: isDarkMode ? "moon.stars.fill" : "sun.max.fill")
                            .foregroundColor(isDarkMode ? .purple : .orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(isDarkMode ? "Ночная схема" : "Дневная схема")
                                .foregroundColor(.white)
                            Text("Влияет на подложку карты Leaflet")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .listRowBackground(Color.white.opacity(0.04))
        }
        .navigationTitle("Настройки")
        .scrollContentBackground(.hidden) // Позволяет покрасить фон формы в наш цвет
        .background(Color(red: 0.1, green: 0.1, blue: 0.12).ignoresSafeArea())
    }
    
    private let baseURL = "http://172.20.10.8:8000/api/v1.0"
    // Метод отправки города на бэкенд Flask
    private func updateCityOnServer(newCity: String) async {
        isSavingCity = true
        guard let url = URL(string: "\(baseURL)/user/update-location") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["city": newCity]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        _ = try? await URLSession.shared.data(for: request)
        isSavingCity = false
    }
}
