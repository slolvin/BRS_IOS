//
//   BarDetailView.swift
//  BRS
//
//  Created by Haris York on 09.06.2026.
//

import SwiftUI

struct BarDetailView: View {
    @StateObject var viewModel: BarDetailViewModel
    
    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView("Загрузка данных бара...")
                        .tint(.blue)
                    Spacer()
                }
                .frame(minHeight: 300)
            } else if let bar = viewModel.bar {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // 1. Блок основной информации о баре
                    VStack(alignment: .leading, spacing: 8) {
                        Text(bar.name)
                            .font(.system(.largeTitle, design: .rounded))
                            .bold()
                            .foregroundColor(.primary)
                        
                        if let address = bar.address {
                            HStack(alignment: .top) {
                                Text("📍")
                                Text(address)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        HStack(spacing: 12) {
                            // Рейтинг заведения
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.1f", bar.rate))
                                    .fontWeight(.bold)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.yellow.opacity(0.15))
                            .cornerRadius(8)
                            
                            // Имя менеджера
                            Text("Менеджер: \(bar.managerName)")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // 2. Меню напитков бара
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Меню напитков")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)
                        
                        if bar.drinks.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "wineglass")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                Text("В этом баре пока нет напитков")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .greatestFiniteMagnitude )
                            .padding(.vertical, 40)
                        } else {
                            // Выводим список напитков через ForEach
                            LazyVStack(spacing: 12) {
                                ForEach(bar.drinks) { drink in
                                    // Связываем с реальным экраном детализации напитка
                                    NavigationLink(destination: DrinkDetailView(viewModel: DrinkDetailViewModel(drinkId: drink.id))) {
                                        DrinkRowView(drink: drink)
                                            .padding(.horizontal)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                }
                .padding(.vertical)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    Text("Не удалось загрузить информацию")
                        .font(.headline)
                    Button("Повторить запрос") {
                        viewModel.loadBarDetails()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.vertical, 100)
            }
        }
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadBarDetails()
        }
    }
}
