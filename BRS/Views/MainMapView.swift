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
    @State private var isShowingQRScanner = false
    
    private let gridLayout = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // ==========================================
                // СЛОЙ 1: Карта во весь экран (Нижний слой)
                // ==========================================
                Map(position: $viewModel.cameraPosition) {
                    if let radius = viewModel.currentRadiusInMeters {
                        MapCircle(center: viewModel.mockUserCoordinate, radius: radius)
                            .foregroundStyle(Color.blue.opacity(0.08)) // Очень нежная заливка внутри
                            .stroke(Color.blue.opacity(0.4), lineWidth: 1.5) // Аккуратная синяя граница круга
                    }
                    Annotation("Вы здесь", coordinate: viewModel.mockUserCoordinate) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 40, height: 40)
                            Circle()
                                .fill(Color.white)
                                .frame(width: 18, height: 18)
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 14, height: 14)
                        }
                        .shadow(color: .black.opacity(0.2), radius: 3)
                    }
                    ForEach(viewModel.rankedBars) { item in
                        Annotation(item.name, coordinate: item.coordinate) {
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .fill(item.isLeader ? Color.yellow : Color.orange)
                                        .frame(width: 38, height: 38)
                                        // 🌟 ЗЕЛЕНЫЙ ИЛИ КРАСНЫЙ ОБОДОК ВОКРУГ МАРКЕРА
                                        .overlay(
                                            Circle()
                                                .stroke(item.isOpen ? Color.green : Color.red, lineWidth: 3)
                                        )
                                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                                    
                                    Text(viewModel.filters.drinkType != "Все типы" ? "#\(item.index + 1)" : String(format: "%.1f", item.drinkRating))
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundColor(item.isLeader ? .black : .white)
                                }
                                
                                Image(systemName: "triangle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(item.isLeader ? .yellow : .orange)
                                    .frame(width: 8, height: 6)
                                    .rotationEffect(.degrees(180))
                                    .offset(y: -3)
                            }
                            .scaleEffect(item.isLeader ? 1.15 : 1.0)
                            // 🌟 ВОЗВРАЩАЕМ КЛИКАБЕЛЬНОСТЬ:
                            .onTapGesture {
                                selectedBarId = item.id
                            }
                        }
                    }
                }
                .ignoresSafeArea(edges: .bottom)
                .navigationDestination(item: $selectedBarId) { barId in
                    BarDetailView(viewModel: BarDetailViewModel(barId: barId))
                }
                VStack(spacing: 0) {
                    Spacer() // Выталкивает все плавающие кнопки к нижней кромке (над шторкой)
                    
                    HStack(alignment: .bottom) {
                        // 🌟 2.1. ЛЕВАЯ СТОРОНА: Крупная круглая кнопка QR-сканера
                        Button(action: {
                            withAnimation {
                                isShowingQRScanner = true // Активируем шторку сканера
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.orange) // Фирменный цвет заведения для главного действия
                                    .frame(width: 56, height: 56)
                                    .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                                
                                Image(systemName: "qrcode.viewfinder")
                                    .font(.system(size: 26, weight: .medium))
                                    .foregroundColor(.black) // Черная иконка на оранжевом фоне смотрится очень контрастно
                            }
                        }
                        .padding(.leading, 16)
                        
                        Spacer() // Расталкивает элементы по краям экрана
                        
                        // 2.2. ПРАВАЯ СТОРОНА: Блок кнопок управления масштабом
                        VStack(spacing: 8) {
                            MapControlButton(icon: "plus") { viewModel.zoomIn() }
                            MapControlButton(icon: "minus") { viewModel.zoomOut() }
                            MapControlButton(icon: "location.fill", iconColor: .blue) {
                                viewModel.moveToUserLocation()
                            }
                        }
                        .padding(.trailing, 16)
                    }
                    // Кнопка QR и кнопки масштаба синхронно адаптируются под высоту шторки!
                    .padding(.bottom, viewModel.filters.drinkType != "Все типы" ? 475 : 215)
                }
                // ==========================================
                // СЛОЙ 3: Монолитная Нижняя Панель Управления (Ваш оригинальный каркас)
                // ==========================================
                VStack(spacing: 0) {
                    Spacer() // 1. Выталкивает шторку на самый низ экрана
                    
                    VStack(spacing: 0) {
                        // 3.1. Декоративный индикатор шторки
                        Capsule()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 40, height: 4)
                            .padding(.top, 8)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        // 3.2. Горизонтальный скролл-фильтр категорий (Теперь внутри шторки поверх кнопок)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(viewModel.availableDrinkTypes, id: \.self) { type in
                                    let cleanType = type == "Все типы" ? "Все" : type
                                    Text(cleanType)
                                        .font(.subheadline).bold()
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(viewModel.filters.drinkType == type ? Color.orange : Color.white.opacity(0.06))
                                        .foregroundColor(viewModel.filters.drinkType == type ? .black : .white)
                                        .cornerRadius(20)
                                        .onTapGesture {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                viewModel.filters.drinkType = type
                                            }
                                        }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            .padding(.bottom, 6)
                        }
                        
                        // 3.3. Ваша оригинальная сетка кнопок фильтрации (LazyVGrid)
                        // 3.3. Обновленная сетка кнопок фильтрации (Без дублей, с радиусом)
                        LazyVGrid(columns: gridLayout, spacing: 10) {
                            // 1. Кнопка Сбросить
                        
                            
                            // 2. 🌟 ПЕРЕНЕСЕНО СЮДА: Красивая затычка радиуса расстояния
                            
                            // 3. Кнопка Открыто
                            Button(action: {
                                withAnimation { viewModel.filters.isOpenNow.toggle() }
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
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(viewModel.filters.isOpenNow ? Color.blue : Color.white.opacity(0.15), lineWidth: 1))
                            }
                            
                            // 4. Фильтр Рейтинга
                            Menu {
                                Picker("Рейтинг", selection: $viewModel.filters.rating) {
                                    ForEach(viewModel.ratings, id: \.self) { Text($0) }
                                }
                            } label: {
                                MapFilterBadge(title: viewModel.filters.rating, icon: "star.fill")
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 6)
                        .padding(.bottom, viewModel.filters.drinkType != "Все типы" ? 10 : 20)
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "location.magnifyingglass").foregroundColor(.orange)
                                Text("Радиус поиска:")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                // Динамический текст: если максимум — пишем "Везде", если нет — километраж
                                Text(viewModel.filters.distanceRadius >= 3000.0 ? "Везде" : String(format: "%.1f км", viewModel.filters.distanceRadius / 1000.0))
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(.orange)
                            }
                            .padding(.horizontal, 4)
                            
                            // Плавный нативный ползунок от 200 метров до 5 километров
                            Slider(value: $viewModel.filters.distanceRadius, in: 200...3000, step: 100)
                                .tint(.orange) // Красим полоску в фирменный цвет заведения
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                        .padding(.bottom, viewModel.filters.drinkType != "Все типы" ? 4 : 14)
                        // 3.4. Динамический Топ Баров под сеткой фильтров
                        if viewModel.filters.drinkType != "Все типы" {
                            Divider()
                                .background(Color.white.opacity(0.08))
                                .padding(.vertical, 4)
                            
                            Text("Топ баров в категории: \(viewModel.filters.drinkType)")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 4)
                            
                            if viewModel.rankedBars.isEmpty {
                                Text("Ничего не найдено в этой категории")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                                    .padding(.vertical, 20)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            } else {
                                ScrollView {
                                    VStack(spacing: 6) {
                                        ForEach(viewModel.rankedBars) { item in
                                            HStack(spacing: 12) {
                                                Text("#\(item.index + 1)")
                                                    .font(.system(.subheadline, design: .rounded))
                                                    .bold()
                                                    .foregroundColor(item.isLeader ? .yellow : (item.index == 1 ? .white : .gray))
                                                    .frame(width: 25, alignment: .leading)
                                                
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(item.name)
                                                        .font(.subheadline)
                                                        .bold()
                                                        .foregroundColor(.white)
                                                    if let address = item.address {
                                                        Text(address)
                                                            .font(.system(size: 10))
                                                            .foregroundColor(.gray)
                                                            .lineLimit(1)
                                                    }
                                                }
                                                
                                                Spacer()
                                                
                                                HStack(spacing: 4) {
                                                    Image(systemName: "star.fill")
                                                        .foregroundColor(.yellow)
                                                        .font(.system(size: 10))
                                                    
                                                    // 🌟 ПРАВИЛЬНО: Читаем уже готовый, исправленный рейтинг из нашей легкой модели!
                                                    Text(String(format: "%.1f", item.drinkRating))
                                                        .font(.subheadline)
                                                        .bold()
                                                        .foregroundColor(.orange)
                                                }
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 10)
                                            .background(Color.white.opacity(0.04))
                                            .cornerRadius(10)
                                            .padding(.horizontal, 16)
                                        }
                                    }
                                    .padding(.bottom, 10)
                                }
                            }
                        }
                    }
                    // Фиксируем адаптивную высоту контейнера шторки
                    .frame(height: viewModel.filters.drinkType != "Все типы" ? 460 : 195)
                    // Динамический системный нижний отступ из вашего старого кода
                    .padding(.bottom, UIApplication.shared.connectedScenes
                        .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
                        .first { $0.isKeyWindow }?.safeAreaInsets.bottom ?? 34)
                    .background(Color(red: 0.12, green: 0.12, blue: 0.15)) // или ваш .ultraThinMaterial
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: 24, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 24))
                    .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: -4)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.filters.drinkType)
                }
                .ignoresSafeArea(.container, edges: .bottom) // 3. Прижимает блок к самому краю намертво!
                // ==========================================
                // СЛОЙ 4: Системный Лоадер
                // ==========================================
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.blue)
                        .scaleEffect(1.5)
                        .padding(20)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(12)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
                
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
            .task {
                await viewModel.loadBarsOnMap()
            }
            .sheet(isPresented: $isShowingQRScanner) {
                // Вызываем ваш оригинальный, красивый отладочный экран чекина!
                BarCheckInView { successHash in
                    // Разбираем хэш, чтобы понять, какой ID бара открыть
                    // Если хэш имеет вид "bar_21", вытаскиваем число:
                    if successHash.contains("bar_") {
                        let rawId = successHash.replacingOccurrences(of: "bar_", with: "")
                        if let barIdInt = Int(rawId) {
                            // Активируем триггер навигации, и SwiftUI сам откроет BarDetailView!
                            self.selectedBarId = barIdInt
                        }
                    } else {
                        // Если у вас используются сложные хэши, бэкенд при чекине должен отдавать id бара,
                        // но для тестов в симуляторе вы можете вводить "bar_21" и переход сработает идеально!
                        self.selectedBarId = 21
                    }
                }
            }
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
