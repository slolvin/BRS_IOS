//
//  FavoriteBarsView.swift
//  BRS
//
//  Created by Haris York on 07.07.2026.
//

import SwiftUI

// 1. Модель данных для парсинга JSON (Строго Codable без затычек)
struct FavoriteBarsResponse: Decodable {
    let bars: [FavoriteBarItem]
}

struct FavoriteBarItem: Decodable, Identifiable {
    let id: Int
    let name: String
    let address: String
    let city: String
    let rate: Double
}

// 2. Представление экрана
struct FavoriteBarsView: View {
    @State private var bars: [FavoriteBarItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
    // Используем базовый IP твоего DrinkService, чтобы не хардкодить
    private let service = DrinkService()
    
    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.1, blue: 0.12).ignoresSafeArea()
            
            if isLoading {
                ProgressView().tint(.blue)
            } else if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.subheadline)
                    .padding()
            } else if bars.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "heart.slash.fill")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("Список любимых заведений пока пуст")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(bars) { bar in
                            // 🌟 ДОБАВИЛИ: Нативный переход в карточку бара БРС
                            NavigationLink(destination: BarDetailView(viewModel: BarDetailViewModel(barId: bar.id))) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(bar.name.uppercased())
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text(String(format: "★ %.1f", bar.rate))
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.orange)
                                    }
                                    
                                    HStack(spacing: 4) {
                                        Image(systemName: "mappin.and.ellipse")
                                            .foregroundColor(.red)
                                            .font(.caption)
                                        Text("\(bar.city), \(bar.address)")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .multilineTextAlignment(.leading)
                                    }
                                }
                                .padding()
                                .background(Color.white.opacity(0.04))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.02), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle()) // Убираем дефолтное синее подсвечивание ссылки
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Мои Бары")
        .task {
            await fetchFavoriteBars()
        }
    }
    
    // 🌟 АДАПТИРОВАННЫЙ МЕТОД: Работает через мобильные JWT-токены авторизации БРС
    private func fetchFavoriteBars() async {
        isLoading = true
        errorMessage = nil
        let baseURL = "http://192.168.64.109:8000/api/v1.0"
        // Формируем роут к списку избранного
        guard let url = URL(string: "\(baseURL)/user/favorites") else {
            self.errorMessage = "Неверный URL сервера"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // 🌟 ГЛАВНЫЙ СЛОЙ ЗАЩИТЫ: Прокидываем Bearer токен авторизованного юзера
        if let token = AuthManager.shared.getToken() {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } else {
                self.errorMessage = "Пользователь не авторизован"
                isLoading = false
                return // Просто выходим из функции
            }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                self.errorMessage = "Ошибка ответа сервера"
                isLoading = false
                return
            }
            
            // Если токен протух или невалиден
            if httpResponse.statusCode == 401 {
                self.errorMessage = "Сессия устарела. Перевойдите в аккаунт."
                isLoading = false
                return
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Ответ сервера (Любимые бары): \(jsonString)")
            }
            
            let responseObj = try JSONDecoder().decode(FavoriteBarsResponse.self, from: data)
            self.bars = responseObj.bars
            
        } catch {
            print("Критическая ошибка сети БРС: \(error)")
            self.errorMessage = "Не удалось загрузить любимые заведения"
        }
        isLoading = false
    }
}
