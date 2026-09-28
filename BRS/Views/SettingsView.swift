//
//  SettingsView.swift
//  BRS
//
//  Created by Haris York on 07.07.2026.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = true
    @AppStorage("currentCity") private var currentCity = "Любляна"
    @AppStorage("appleLanguage") private var appLanguage = "ru"
    
    @State private var isSavingCity = false
    @State private var isDeletingAccount = false // Состояние для лоадера удаления
    @State private var showDeleteAlert = false   // Состояние для показа предупреждения
    @State private var showPrivacySheet = false
    
    @Environment(\.locale) private var locale
    
    let availableCities = ["Самара", "Москва", "Санкт-Петербург", "Сочи"]
    
    // Получаем версию и билд приложения динамически из системы
    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Версия \(version) (\(build))"
    }
    
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
                       
            Section(header: Text("Правовая информация")) {
                Button {
                    showPrivacySheet = true
                } label: {
                    HStack {
                        Image(systemName: "doc.text.magnifyingglass")
                            .foregroundColor(.orange)
                        Text("Политика конфиденциальности")
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .listRowBackground(Color.white.opacity(0.04))
           // СЕКЦИЯ 4: УДАЛЕНИЕ АККАУНТА (Теперь это финальная секция формы)
           Section {
               Button(role: .destructive) {
                   showDeleteAlert = true
               } label: {
                   HStack {
                       if isDeletingAccount {
                           ProgressView()
                               .tint(.red)
                               .padding(.trailing, 5)
                       } else {
                           Image(systemName: "trash")
                       }
                       Text("Удалить аккаунт")
                           .fontWeight(.medium)
                   }
               }
               .disabled(isDeletingAccount)
           } footer: {
               // Добавляем большой отступ снизу футера, чтобы отделить версию
               VStack(alignment: .center, spacing: 20) {
                   Text("Внимание: все ваши чекины, оценки и лог выпитого будут безвозвратно удалены из базы данных BRS.")
                       .font(.caption2)
                       .foregroundColor(.gray)
                       .frame(maxWidth: .infinity, alignment: .leading)
                   
                   Text(APIConfig.fullVersionString)
                       .font(.caption)
                       .foregroundColor(.gray.opacity(0.6))
                       .frame(maxWidth: .infinity, alignment: .center)
                       .padding(.top, 10)
               }
           }
           .listRowBackground(Color.white.opacity(0.04))
       }
        .sheet(isPresented: $showPrivacySheet) {
            NavigationStack {
                // Используем встроенный в iOS веб-браузер прямо внутри приложения
                // При деплое на VPS замените localhost на https://yourdomain.com
                WebView(url: URL(string: "\(APIConfig.baseURL)/privacy")!)
                    .ignoresSafeArea()
                    .navigationTitle("Конфиденциальность")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Готово") {
                                showPrivacySheet = false
                            }
                        }
                    }
            }
        }
       .navigationTitle("Настройки")
       .scrollContentBackground(.hidden)
       .background(Color(red: 0.1, green: 0.1, blue: 0.12).ignoresSafeArea())
       .environment(\.locale, Locale(identifier: appLanguage))
        // Алерт подтверждения удаления
       .alert("Удаление профиля", isPresented: $showDeleteAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Удалить навсегда", role: .destructive) {
                Task {
                    await deleteAccountOnServer()
                }
            }
        } message: {
            Text("Вы уверены? Это действие невозможно отменить.")
        }
    }
    
    // Метод отправки города на бэкенд Flask
    private func updateCityOnServer(newCity: String) async {
        isSavingCity = true
        guard let url = URL(string: "\(APIConfig.baseURL)/user/update-location") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Подставляем токен из вашего AuthManager
        if let token = AuthManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body: [String: String] = ["city": newCity]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                // 🔥 ЕСЛИ СЕРВЕР СКАЗАЛ, ЧТО СЕССИЯ БИТАЯ (401) -> ОВТОМАТИЧЕСКИ ВЫКИДЫВАЕМ НА ВХОД
                if httpResponse.statusCode == 401 {
                    print("⚠️ Токен протух. Принудительный авто-выход...")
                    AuthManager.shared.logout()
                    isSavingCity = false
                    return
                }
            }
        } catch {
            print("Ошибка обновления локации: \(error)")
        }
        
        isSavingCity = false
    }
    
    // Метод удаления аккаунта на бэкенде Flask
    private func deleteAccountOnServer() async {
        isDeletingAccount = true
        guard let url = URL(string: "\(APIConfig.baseURL)/user/delete-account") else {
            isDeletingAccount = false
            return
        }
        
        // 1. Создаем объект запроса ДО того, как настраивать его свойства (Исправляет первую ошибку)
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = AuthManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            // 2. Выполняем запрос и сохраняем кортеж (data, response)
            let (_, response) = try await URLSession.shared.data(for: request)
            
            // 3. Кастим response в HTTPURLResponse внутри блока do (Исправляет вторую ошибку)
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    print("🚀 Аккаунт успешно удален на бэкенде")
                    
                    // Вызываем глобальный метод очистки сессии
                    // Благодаря DispatchQueue.main.async внутри logout(),
                    // SwiftUI мгновенно и без зависаний переключит BRSApp на LoginView()
                    AuthManager.shared.logout()
                    
                } else {
                    print("Сервер вернул ошибку, статус-код: \(httpResponse.statusCode)")
                }
            }
        } catch {
            print("Ошибка сети при удалении аккаунта: \(error)")
        }
        isDeletingAccount = false
    }
}
