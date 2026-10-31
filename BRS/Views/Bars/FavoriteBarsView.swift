//
//  FavoriteBarsView.swift
//  BRS
//
//  Created by Haris York on 07.07.2026.
//

import SwiftUI

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

struct FavoriteBarsView: View {
    @State private var bars: [FavoriteBarItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
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
                List {
                    ForEach(bars) { bar in
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
                        .buttonStyle(PlainButtonStyle())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                    .onDelete(perform: removeBarFromFavorites)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Мои Бары")
        .task {
            await fetchFavoriteBars()
        }
    }
    
    private func removeBarFromFavorites(at offsets: IndexSet) {
        if let index = offsets.first {
            let targetBar = bars[index]
            
            Task {
                do {
                    _ = try await service.toggleBarFavorite(barId: targetBar.id)
                    print("✅ [БРС СУБД] Заведение «\(targetBar.name)» стерто из избранного через свайп")
                } catch {
                    print("❌ Ошибка удаления бара по сети: \(error.localizedDescription)")
                    await fetchFavoriteBars()
                }
            }
        }
        
        bars.remove(atOffsets: offsets)
    }
    
    private func fetchFavoriteBars() async {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "\(APIConfig.baseURL)/user/favorites") else {
            self.errorMessage = "Неверный URL сервера"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = AuthManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            self.errorMessage = "Пользователь не авторизован"
            isLoading = false
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                self.errorMessage = "Ошибка ответа сервера"
                isLoading = false
                return
            }
            
            if httpResponse.statusCode == 401 {
                self.errorMessage = "Сессия устарела. Перевойдите в аккаунт."
                isLoading = false
                return
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
