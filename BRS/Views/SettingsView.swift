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
    
    // Сохраняем выбранный язык приложения ("ru" или "en")
    @AppStorage("appleLanguage") private var appLanguage = "ru"
    
    @State private var isSavingCity = false
    
    // Подключаем среду окружения, чтобы вью мгновенно реагировала на смену языка
    @Environment(\.locale) private var locale
    
    let availableCities = ["Самара", "Москва", "Санкт-Петербург", "Сочи"]
    
    var body: some View {
        Form {
            // СЕКЦИЯ 1: ЯЗЫК ПРИЛОЖЕНИЯ
            Section(header: Text("Язык")) {
                Picker(selection: $appLanguage) {
                    Text("Русский").tag("ru")
                    Text("English").tag("en")
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "globe")
                            .foregroundColor(.blue)
                        Text("Язык приложения")
                            .foregroundColor(.white)
                    }
                }
            }
            .listRowBackground(Color.white.opacity(0.04))
            
            // СЕКЦИЯ 2: ГЕОЛОКАЦИЯ
            Section(header: Text("География поиска")) {
                Picker("Текущий город", selection: $currentCity) {
                    Text("Любляна").tag("Любляна")
                    Text("Самара").tag("Самара")
                    Text("Москва").tag("Москва")
                }
            }
            .listRowBackground(Color.white.opacity(0.04))
            
            // СЕКЦИЯ 3: ВИЗУАЛЬНЫЕ ШКУРКИ КАРТЫ
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
        .scrollContentBackground(.hidden)
        .background(Color(red: 0.1, green: 0.1, blue: 0.12).ignoresSafeArea())
        // ЭТА СТРОКА заставляет эту вью (и все дочерние) принудительно обновить язык интерфейса
        .environment(\.locale, Locale(identifier: appLanguage))
    }
    
    // Метод отправки города на бэкенд Flask
    private func updateCityOnServer(newCity: String) async {
        isSavingCity = true
        guard let url = URL(string: "\(APIConfig.baseURL)/user/update-location") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["city": newCity]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        _ = try? await URLSession.shared.data(for: request)
        isSavingCity = false
    }
}
