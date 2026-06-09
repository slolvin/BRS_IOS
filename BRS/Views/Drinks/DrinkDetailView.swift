//
//  DrinkDetailView.swift
//  BRS
//
//  Created by Haris York on 09.06.2026.
//

import SwiftUI

struct DrinkDetailView: View {
    @StateObject var viewModel: DrinkDetailViewModel
    
    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView().padding(.top, 100)
            } else if let drink = viewModel.drink {
                VStack(spacing: 24) {
                    
                    // 1. Асинхронная картинка напитка с сервера
                    // 1. Сначала безопасно разворачиваем опциональную строку из модели, а затем создаем из неё валидный URL
                    if let imageURLString = drink.imageUrl, let url = URL(string: imageURLString) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 200, height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(radius: 10)
                    } else {
                        // Системная заглушка, если картинки на сервере нет или URL поврежден
                        Image(systemName: "wineglass.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.secondary)
                            .frame(width: 200, height: 200)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    
                    // 2. Описание напитка
                    VStack(spacing: 8) {
                        Text(drink.name)
                            .font(.title).bold()
                        
                        Text(drink.type ?? "Без типа")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.15))
                            .cornerRadius(20)
                        
                        // БЕЗОПАСНОЕ РАЗВЕРТЫВАНИЕ: проверяем, есть ли рейтинг у напитка
                        if let score = drink.score {
                            Text("⭐ \(String(format: "%.2f", score))")
                                .font(.headline)
                                .padding(.top, 4)
                        } else {
                            Text("⭐ Нет оценок")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                    }
                    
                    if let desc = drink.description, !desc.isEmpty {
                        Text(desc)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    Divider().padding(.horizontal)
                    
                    // 3. Интерактивный блок голосования (Звёздочки)
                    VStack(spacing: 12) {
                        Text("Оцените напиток")
                            .font(.headline)
                        
                        HStack(spacing: 10) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= viewModel.userRating ? "star.fill" : "star")
                                    .font(.title)
                                    .foregroundColor(.yellow)
                                    .onTapGesture {
                                        // Отправляем оценку на бэк по тапу
                                        viewModel.sendRating(star)
                                    }
                            }
                        }
                        .animation(.easeInOut(duration: 0.2), value: viewModel.userRating)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadDrink()
        }
    }
}
