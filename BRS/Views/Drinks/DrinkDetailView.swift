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
                    if let url = drink.imageUrl {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ZStack {
                                    Color.white.opacity(0.04)
                                    ProgressView().tint(.blue)
                                }
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure:
                                ZStack {
                                    Color.white.opacity(0.04)
                                    Image(systemName: "wineglass.fill")
                                        .font(.system(size: 80))
                                        .foregroundColor(.secondary)
                                }
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(width: 200, height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(radius: 10)
                    } else {
                        Image(systemName: "wineglass.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.secondary)
                            .frame(width: 200, height: 200)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(radius: 10)
                    }
                    
                    VStack(spacing: 8) {
                        Text(drink.name)
                            .font(.title).bold()
                        
                        Text(drink.type)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.15))
                            .cornerRadius(20)
                        
                        if drink.score > 0.0 {
                            Text("⭐ \(String(format: "%.2f", drink.score))")
                                .font(.headline)
                                .padding(.top, 4)
                        } else {
                            Text("⭐ Нет оценок")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                    }
                    
                    if !drink.description.isEmpty {
                        Text(drink.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    HStack(spacing: 10) {
                        Text("\(drink.volume) мл")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Text("\(drink.formattedAbv)%")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    Divider().padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        Text((drink.canRate) ? "Оцените напиток" : "Вы уже оценили этот бокал")
                            .font(.headline)
                            .foregroundColor((drink.canRate) ? .primary : .secondary)
                        
                        HStack(spacing: 10) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= viewModel.userRating || (star <= Int((drink.score).rounded()) && !(drink.canRate)) ? "star.fill" : "star")
                                    .font(.title)
                                    .foregroundColor(.yellow)
                                    .opacity((drink.canRate) ? 1.0 : 0.4)
                                    .onTapGesture {
                                        if drink.canRate {
                                            viewModel.sendRating(star)
                                        }
                                    }
                            }
                        }
                        .animation(.easeInOut(duration: 0.2), value: viewModel.userRating)
                        
                        if !(drink.canRate) {
                            HStack(spacing: 6) {
                                Image(systemName: "info.circle.fill")
                                Text("Добавьте новую запись 'Выпить', чтобы открыть возможность повторной оценки.")
                            }
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                            .padding(.top, 4)
                        }
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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let drink = viewModel.drink {
                    Button(action: {
                        viewModel.toggleFavorite()
                    }) {
                        Image(systemName: drink.isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(drink.isFavorite ? .red : .gray)
                            .contentTransition(.symbolEffect(.replace))
                    }
                }
            }
        }
    }
}
