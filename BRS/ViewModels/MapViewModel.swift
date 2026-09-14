//
//  MapViewModel.swift
//  BRS
//
//  Created by Haris York on 06.06.2026.
//

import Combine
import SwiftUI
import MapKit
import CoreLocation

@MainActor
class MapViewModel: ObservableObject {
    // Внутренний массив для хранения всех полных объектов из базы БРС
    private var allBars: [BarDetail] = []
    
    // Массив отфильтрованных баров, который отображается на карте
    @Published var annotatedBars: [BarDetail] = []
    
    // Позиция камеры на карте
    @Published var cameraPosition: MapCameraPosition = .automatic
    
    // Флаг загрузки (активирует лоадер по центру экрана)
    @Published var isLoading = false
    
    // Динамические списки, собираемые на основе записей в БД
    @Published var availableCities: [String] = ["Все города"]
    @Published var availableDrinkTypes: [String] = ["Все типы"]
    
    // Статический фильтр рейтинга
    let ratings = ["Любой", "4.0+", "4.5+"]
    
    // Встроенный словарь центров городов (копия логики cityCenters из bars.html на Leaflet.js)
    private let cityCenters: [String: CLLocationCoordinate2D] = [
        "Любляна": CLLocationCoordinate2D(latitude: 46.0569, longitude: 14.5058), // 🇸🇮 Центр Любляны у реки
        "Москва": CLLocationCoordinate2D(latitude: 55.7558, longitude: 37.6173),
        "Самара": CLLocationCoordinate2D(latitude: 53.2001, longitude: 50.1500)
    ]
    
    // Единый источник правды для фильтрации с реактивнымdidSet триггером
    @Published var filters = BarFilterOptions() {
        didSet {
            // 1. Пересчитываем маркеры на карте локально
            applyFilters(with: filters)
            
            // 2. Если пользователь переключил город — плавно перелетаем на его центр
            if oldValue.city != filters.city {
                updateCameraPosition(for: filters.city)
            }
        }
    }
    
    private let service = DrinkService()
    
    func resetFilters() {
        self.filters.drinkType = "Все типы"
        self.filters.rating = "Любой"
        self.filters.isOpenNow = false
        // Значение города filters.city не сбрасываем, чтобы не сбивать регион настроек
    }
    
    /// Основной метод инициализации данных на карте
    func loadBarsOnMap() async {
        self.isLoading = true
        do {
            // 1. Читаем город из сохраненных настроек приложения (UserDefaults)
            let savedCity = UserDefaults.standard.string(forKey: "currentCity") ?? "Любляна"
            
            // Синхронизируем фильтр города на панели с глобальными настройками
            self.filters.city = savedCity
            
            // Получаем дефолтную координату текущего города на случай сбоя геокодера
            let defaultCoordinate = cityCenters[savedCity] ?? CLLocationCoordinate2D(latitude: 46.0569, longitude: 14.5058)
            
            // 2. Загружаем легковесные маркеры с бэкенда
            let markers = try await service.fetchBarsForMap()
            
            // 3. Асинхронно и параллельно стягиваем детальные карточки баров (N+1 решено на бэке)
            let fetchedDetails = await withTaskGroup(of: BarDetail?.self) { group in
                for marker in markers {
                    group.addTask {
                        do {
                            return try await self.service.fetchBarDetail(id: marker.id)
                        } catch {
                            print("Ошибка загрузки ID \(marker.id): \(error.localizedDescription)")
                            return nil
                        }
                    }
                }
                var details: [BarDetail] = []
                for await barDetail in group {
                    if let bar = barDetail { details.append(bar) }
                }
                return details
            }
            
            // 4. Нативное геокодирование адресов через современный MKGeocodingRequest (iOS 18+)
            var enrichedBars: [BarDetail] = []
            
            for var bar in fetchedDetails {
                guard let rawAddress = bar.address, !rawAddress.isEmpty else {
                    // ИСПРАВЛЕНО: Вместо Самары ставим центр текущего выбранного города
                    bar.coordinate = defaultCoordinate
                    enrichedBars.append(bar)
                    continue
                }
                
                let cleanAddress = rawAddress.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if let geocodeRequest = MKGeocodingRequest(addressString: cleanAddress) {
                    do {
                        let response = try await geocodeRequest.mapItems
                        if let topLocation = response.first?.location {
                            bar.coordinate = topLocation.coordinate
                            print("✅ Разъехался бар: \(bar.name) -> (\(topLocation.coordinate.latitude), \(topLocation.coordinate.longitude))")
                        } else {
                            bar.coordinate = defaultCoordinate
                        }
                    } catch {
                        bar.coordinate = defaultCoordinate
                        print("⚠️ Ошибка карт для адреса '\(cleanAddress)': \(error.localizedDescription)")
                    }
                } else {
                    bar.coordinate = defaultCoordinate
                }
                
                enrichedBars.append(bar)
            }
            
            self.allBars = enrichedBars
            
            // 5. Наполняем Picker-ы уникальными городами и напитками из базы
            generateDynamicFilters()
            
            // 6. Применяем фильтры
            applyFilters(with: self.filters)
            
            // 7. Умный стартовый фокус камеры строго на выбранный в настройках город
            if let centerCoordinate = cityCenters[savedCity] {
                let region = MKCoordinateRegion(
                    center: centerCoordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
                )
                withAnimation(.easeInOut(duration: 0.5)) {
                    self.cameraPosition = .region(region)
                }
            } else if !enrichedBars.isEmpty {
                self.cameraPosition = .automatic
            }
            
        } catch {
            print("Критическая ошибка БРС: \(error.localizedDescription)")
        }
        self.isLoading = false
    }
    
    /// Сбор уникальных значений для меню фильтров
    private func generateDynamicFilters() {
        // Оставляем только сбор типов напитков
        let types = Set(allBars.flatMap { $0.drinks.compactMap { $0.type } }).sorted()
        self.availableDrinkTypes = ["Все типы"] + types
    }
    
    /// Локальная фильтрация массива баров без повторных запросов в сеть
    private func applyFilters(with currentFilters: BarFilterOptions) {
        self.annotatedBars = allBars.filter { bar in
            
            // 🌟 ИСПРАВЛЕНО: Убрали matchCity, так как за очистку региона теперь отвечает СУБД на бэкенде!
            
            // 1. Фильтр по типам алкоголя в меню заведения
            let matchDrink = currentFilters.drinkType == "Все типы" || bar.drinks.contains(where: { $0.type == currentFilters.drinkType })
            
            // 2. Фильтр по оценке (рейтингу)
            let matchRating: Bool
            switch currentFilters.rating {
            case "4.0+": matchRating = bar.rate >= 4.0
            case "4.5+": matchRating = bar.rate >= 4.5
            default: matchRating = true
            }
            
            // 3. Фильтр по времени работы
            let matchOpen = !currentFilters.isOpenNow
            
            return matchDrink && matchRating && matchOpen
        }
    }
    
    /// Логика плавного перелета камеры к выбранному городу
    private func updateCameraPosition(for city: String) {
        if city == "Все города" {
            if !annotatedBars.isEmpty {
                withAnimation(.easeInOut(duration: 0.8)) {
                    self.cameraPosition = .automatic
                }
            }
        } else if let centerCoordinate = cityCenters[city] {
            let region = MKCoordinateRegion(
                center: centerCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
            )
            withAnimation(.easeInOut(duration: 0.8)) {
                self.cameraPosition = .region(region)
            }
        }
    }
    
    // MARK: - КАСТ ОМНЫЕ КОНТРОЛЛЫ МАСШТАБА (МЁД UI)
    var currentRegion: MKCoordinateRegion?
    
    func zoomIn() {
        // 1. Берем регион, куда пользователь реально доскроллил пальцами
        // 2. Если его нет, берем центр из словаря городов
        // 3. Крайний случай — дефолтная Самара
        let activeRegion = currentRegion ?? cameraPosition.region ?? MKCoordinateRegion(
            center: cityCenters[filters.city] ?? CLLocationCoordinate2D(latitude: 53.2001, longitude: 50.1500),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        
        var newRegion = activeRegion
        
        // Приближаем масштаб в 2 раза строго в текущей точке экрана
        newRegion.span.latitudeDelta /= 2.0
        newRegion.span.longitudeDelta /= 2.0
        
        withAnimation(.easeInOut(duration: 0.25)) {
            cameraPosition = .region(newRegion)
        }
    }
    
    func zoomOut() {
        let activeRegion = currentRegion ?? cameraPosition.region ?? MKCoordinateRegion(
            center: cityCenters[filters.city] ?? CLLocationCoordinate2D(latitude: 53.2001, longitude: 50.1500),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        
        var newRegion = activeRegion
        
        // Отдаляем масштаб в 2 раза, не превышая глобальный охват
        if newRegion.span.latitudeDelta < 30.0 {
            newRegion.span.latitudeDelta *= 2.0
            newRegion.span.longitudeDelta *= 2.0
        }
        
        withAnimation(.easeInOut(duration: 0.25)) {
            cameraPosition = .region(newRegion)
        }
    }
    
    func moveToUserLocation() {
        withAnimation(.easeInOut(duration: 0.3)) {
            cameraPosition = .userLocation(fallback: .automatic)
        }
    }
}
