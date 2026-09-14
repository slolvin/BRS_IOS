//
//  MainMapView.swift
//  BRS
//
//  Created by Haris York on 06.06.2026.
//

import SwiftUI
import MapKit

struct MainMapView: View {
    @AppStorage("isDarkMode") private var isDarkMode = true
    @StateObject private var viewModel = MapViewModel()
    @State private var selectedBarId: Int?
    
    private let gridLayout = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 1. Слой карты на весь экран
                Map(position: $viewModel.cameraPosition) {
                    ForEach(viewModel.annotatedBars) { bar in
                        Annotation(bar.name, coordinate: bar.coordinate) {
                            VStack(spacing: 4) {
                                Image(systemName: "building.2.crop.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.blue)
                                    .background(Color.white.clipShape(Circle()))
                                
                                Text(bar.name)
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.black.opacity(0.75))
                                    .cornerRadius(4)
                            }
                            .onTapGesture {
                                selectedBarId = bar.id
                            }
                        }
                    }
                }
                .ignoresSafeArea(.all)
                // Отключили встроенные контроли, так как делаем свои кастомные!
                .onMapCameraChange(frequency: .continuous) { context in
                    viewModel.currentRegion = context.region
                }
                // 2. Слой кнопок управления масштабом и геопозицией (справа над фильтрами)
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Spacer() // Сдвигаем кнопки строго к правому краю
                        
                        VStack(spacing: 8) {
                            // Кнопка Приблизить (+)
                            MapControlButton(icon: "plus") {
                                viewModel.zoomIn()
                            }
                            
                            // Кнопка Отдалить (-)
                            MapControlButton(icon: "minus") {
                                viewModel.zoomOut()
                            }
                            
                            // Кнопка Моя Локация
                            MapControlButton(icon: "location.fill", iconColor: .blue) {
                                viewModel.moveToUserLocation()
                            }
                        }
                        .padding(.trailing, 16)
                    }
                    
                    // Делаем отступ снизу, чтобы кнопки красиво "парили" строго над панелью фильтров
                    Spacer()
                        .frame(height: 140)
                }
                
                // 3. Статичная нижняя панель фильтров (Сетка 2х2)
                VStack(spacing: 0) {
                    Spacer()
                    
                    VStack(spacing: 0) {
                        LazyVGrid(columns: gridLayout, spacing: 10) {
                            Button(action: {
                                withAnimation {
                                    viewModel.resetFilters()
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.counterclockwise.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                    Text("Сбросить")
                                        .font(.system(size: 14, weight: .medium))
                                    Spacer()
                                }
                                .padding(.horizontal, 14)
                                .frame(height: 44)
                                .background(Color(red: 0.1, green: 0.15, blue: 0.2).opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                )
                            }
                            
                            Menu {
                                Picker("Тип напитка", selection: $viewModel.filters.drinkType) {
                                    ForEach(viewModel.availableDrinkTypes, id: \.self) { Text($0) }
                                }
                            } label: {
                                MapFilterBadge(title: viewModel.filters.drinkType, icon: "wineglass")
                            }
                            
                            Button(action: {
                                viewModel.filters.isOpenNow.toggle()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: viewModel.filters.isOpenNow ? "clock.fill" : "clock")
                                        .font(.system(size: 14))
                                        .foregroundColor(viewModel.filters.isOpenNow ? .white : .blue)
                                    Text("Открыто")
                                        .font(.system(size: 14, weight: .medium))
                                    Spacer()
                                }
                                .padding(.horizontal, 14)
                                .frame(height: 44)
                                .background(viewModel.filters.isOpenNow ? Color.blue : Color(red: 0.1, green: 0.15, blue: 0.2).opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(viewModel.filters.isOpenNow ? Color.blue : Color.white.opacity(0.15), lineWidth: 1)
                                )
                            }
                            
                            Menu {
                                Picker("Рейтинг", selection: $viewModel.filters.rating) {
                                    ForEach(viewModel.ratings, id: \.self) { Text($0) }
                                }
                            } label: {
                                MapFilterBadge(title: viewModel.filters.rating, icon: "star.fill")
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        .padding(.bottom, 8)
                    }
                    .padding(.bottom, UIApplication.shared.connectedScenes
                        .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
                        .first { $0.isKeyWindow }?.safeAreaInsets.bottom ?? 34)
                    .background(.ultraThinMaterial)
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: 24, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 24))
                    .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: -4)
                }
                .ignoresSafeArea(.container, edges: .bottom)
                
                // 4. Индикатор загрузки по центру экрана
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.blue)
                        .scaleEffect(1.5)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(12)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
            }
            .navigationDestination(item: $selectedBarId) { barId in
                BarDetailView(viewModel: BarDetailViewModel(barId: barId))
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .task {
            await viewModel.loadBarsOnMap()
        }
    }
}

// Новый переиспользуемый компонент круглой кнопки управления в неоновом стиле БРС
struct MapControlButton: View {
    let icon: String
    var iconColor: Color = .white
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(iconColor)
                .frame(width: 42, height: 42)
                .background(
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        .background(Color(red: 0.1, green: 0.15, blue: 0.2).opacity(0.85))
                        .clipShape(Circle())
                )
                .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
        }
    }
}

// Компонент плашки фильтров (без изменений)
struct MapFilterBadge: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.blue)
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .lineLimit(1)
            Spacer()
            Image(systemName: "chevron.down")
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(Color(red: 0.1, green: 0.15, blue: 0.2).opacity(0.8))
        .foregroundColor(.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
}
