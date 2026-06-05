//
//  MapViewModel.swift
//  BRS
//
//  Created by Haris York on 06.06.2026.
//

import Combine
import SwiftUI // <-- КРИТИЧЕСКИ ВАЖНО! Без этого Xcode не знает, что такое MapCameraPosition
import MapKit

@MainActor
class MapViewModel: ObservableObject {
    @Published var annotatedBars: [AnnotatedBar] = []
    @Published var isLoading = false
    
    // Теперь .region и MapCameraPosition распознаются без ошибок компиляции
    @Published var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 53.2001, longitude: 50.1500),
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        )
    )
    
    private let service = DrinkService()
    
    func loadBarsOnMap() async {
        isLoading = true
        do {
            let markers = try await service.fetchBarsForMap()
            print("🍏 ИЗ API ПРИШЛО МАРКЕРОВ: \(markers.count)")
            
            var tempBars: [AnnotatedBar] = []
            
            // Твоя существующая логика геокодирования из API
            for marker in markers {
                if let coordinate = try? await geocodeAddress(marker.fullAddress) {
                    let annotated = AnnotatedBar(id: marker.id, name: marker.name, coordinate: coordinate)
                    tempBars.append(annotated)
                }
            }
            
            // 🛠 ПРИНУДИТЕЛЬНЫЙ ТЕСТОВЫЙ МАРКЕР (ХАРДКОД)
            // Координаты Самары, Самарская филармония / ул. Куйбышева
            let testBarCoordinate = CLLocationCoordinate2D(latitude: 53.1963, longitude: 50.0988)
            let testBar = AnnotatedBar(
                id: 9999, // фейковый ID
                name: "Тестовый Бар (Самара)",
                coordinate: testBarCoordinate
            )
            tempBars.append(testBar)
            
            // Обновляем массив на экране
            self.annotatedBars = tempBars
            
            // Всегда принудительно центрируем камеру на нашем тестовом баре в Самаре
            self.cameraPosition = .region(
                MKCoordinateRegion(
                    center: testBarCoordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03) // более крупный масштаб
                )
            )
            
        } catch {
            print("🚨 Критическая ошибка загрузки API карт: \(error)")
            
            // Подстраховка: если API лежит, всё равно показываем тестовый бар, чтобы карта не была пустой
            let testBarCoordinate = CLLocationCoordinate2D(latitude: 53.1963, longitude: 50.0988)
            self.annotatedBars = [
                AnnotatedBar(id: 9999, name: "Тестовый Бар (Самара офлайн)", coordinate: testBarCoordinate)
            ]
            self.cameraPosition = .region(
                MKCoordinateRegion(center: testBarCoordinate, span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03))
            )
        }
        isLoading = false
    }

    
    /// МЕТОД ГЕОКОДИРОВАНИЯ (MapKit iOS 18+)
    private func geocodeAddress(_ address: String) async throws -> CLLocationCoordinate2D {
        guard let request = MKGeocodingRequest(addressString: address) else {
            throw NSError(domain: "MKGeocodingError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Некорректная строка адреса"])
        }
        
        let mapItems = try await request.mapItems
        
        guard let firstMapItem = mapItems.first else {
            throw NSError(domain: "MKGeocodingError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Адрес не найден на картах Apple Maps"])
        }
        
        return firstMapItem.location.coordinate
    }
}
