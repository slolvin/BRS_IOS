//
//  FavoriteBarsView.swift
//  BRS
//
//  Created by Haris York on 07.07.2026.
//

import SwiftUI

// 1. Модель данных для парсинга JSON
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
    
    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.1, blue: 0.12).ignoresSafeArea()
            
            if isLoading {
                ProgressView().tint(.blue)
            } else if let error = errorMessage {
                Text(error).foregroundColor(.red)
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
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.02), lineWidth: 1))
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
    
    // Простой метод запроса к нашему новому эндпоинту
    private func fetchFavoriteBars() async {
        isLoading = true
        errorMessage = nil
        // Укажите ваш рабочий локальный IP
        guard let url = URL(string: "http://172.20.10.8:8000/api/v1.0") else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let jsonString = String(data: data, encoding: .utf8) {
                        print("Ответ сервера (Любимые бары): \(jsonString)")
                    }
                    
                    let responseObj = try JSONDecoder().decode(FavoriteBarsResponse.self, from: data)
                    self.bars = responseObj.bars
        } catch {
            print("Критическая ошибка сети: \(error)")
            self.errorMessage = "Ошибка подключения к серверу БРС"
        }
        isLoading = false
    }
}
