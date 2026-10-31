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
    private var allBars: [BarDetail] = []
    
    @Published var annotatedBars: [BarDetail] = []
    
    @Published var cameraPosition: MapCameraPosition = .automatic
    
    @Published var isLoading = false
    
    @Published var availableCities: [String] = ["Все города"]
    @Published var availableDrinkTypes: [String] = ["Все типы"]
    let mockUserCoordinate = CLLocationCoordinate2D(latitude: 53.1895, longitude: 50.0943)
    let distanceOptions = ["Любое", "500 м", "1 км", "2 км"]
    
    let ratings = ["Любой", "4.0+", "4.5+"]
    
    private let cityCenters: [String: CLLocationCoordinate2D] = [
        "Любляна": CLLocationCoordinate2D(latitude: 46.0569, longitude: 14.5058),
        "Москва": CLLocationCoordinate2D(latitude: 55.7558, longitude: 37.6173),
        "Самара": CLLocationCoordinate2D(latitude: 53.1851, longitude: 50.0887)
    ]
    
    @Published var filters = BarFilterOptions() {
        didSet {
            applyFilters(with: filters)
            
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
    }
    var currentRadiusInMeters: Double? {
        filters.distanceRadius < 3000.0 ? filters.distanceRadius : nil
    }
    
    func loadBarsOnMap() async {
        self.isLoading = true
        do {
            let savedCity = UserDefaults.standard.string(forKey: "currentCity") ?? "Любляна"
            
            self.filters.city = savedCity
            
            let defaultCoordinate = cityCenters[savedCity] ?? CLLocationCoordinate2D(latitude: 46.0569, longitude: 14.5058)
            
            let markers = try await service.fetchBarsForMap()
            
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
            
            var enrichedBars: [BarDetail] = []
            
            for var bar in fetchedDetails {
                guard let rawAddress = bar.address, !rawAddress.isEmpty else {
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
            
            generateDynamicFilters()
            
            applyFilters(with: self.filters)
            
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
    
    private func generateDynamicFilters() {
        let types = Set(allBars.flatMap { $0.drinks.compactMap { $0.type } }).sorted()
        self.availableDrinkTypes = ["Все типы"] + types
    }
    
    
    struct RankedBarItem: Identifiable {
        let id: Int
        let index: Int
        let name: String
        let address: String?
        let coordinate: CLLocationCoordinate2D
        let drinkRating: Double
        let isLeader: Bool
        let isOpen: Bool
        let distanceText: String
    }

    var rankedBars: [RankedBarItem] {
        let isDrinkFiltered = filters.drinkType != "Все типы"
        let userLocation = CLLocation(latitude: mockUserCoordinate.latitude, longitude: mockUserCoordinate.longitude)
        
        return annotatedBars.enumerated().map { index, bar in
            let targetDrink = bar.drinks.first { $0.type == filters.drinkType }
            let score = targetDrink?.score ?? bar.rate
            let barLocation = CLLocation(latitude: bar.coordinate.latitude, longitude: bar.coordinate.longitude)
            let distanceInMeters = userLocation.distance(from: barLocation)
            
            let distanceText = distanceInMeters < 1000
                ? String(format: "%.0f м", distanceInMeters)
                : String(format: "%.1f км", distanceInMeters / 1000.0)
            
            return RankedBarItem(
                id: bar.id,
                index: index,
                name: bar.name,
                address: bar.address,
                coordinate: bar.coordinate,
                drinkRating: score,
                isLeader: isDrinkFiltered && index == 0,
                isOpen: bar.openingHours.isOpenNow,
                distanceText: distanceText               
                
            )
        }
    }
    
    private func applyFilters(with options: BarFilterOptions) {
        let userLocation = CLLocation(latitude: mockUserCoordinate.latitude, longitude: mockUserCoordinate.longitude)
        var filtered = allBars.filter { bar in
            let matchCity = (options.city == "Все города") || (bar.city == options.city)
            
            var matchRating = true
            if options.rating == "4.0+" { matchRating = bar.rate >= 4.0 }
            else if options.rating == "4.5+" { matchRating = bar.rate >= 4.5 }
            
            let matchOpen = !options.isOpenNow || bar.openingHours.isOpenNow
            let barLoc = CLLocation(latitude: bar.coordinate.latitude, longitude: bar.coordinate.longitude)
            let distance = userLocation.distance(from: barLoc)

            var matchDistance = true
            if options.distanceRadius < 3000.0 {
                matchDistance = distance <= options.distanceRadius
            }
                
            return matchCity && matchRating && matchOpen && matchDistance
        }
        
        if options.drinkType != "Все типы" {
            let barsWithDrink = filtered.filter { bar in
                bar.drinks.contains { $0.type == options.drinkType }
            }
            
            filtered = barsWithDrink.sorted { (bar1: BarDetail, bar2: BarDetail) -> Bool in
                let drinkInBar1 = bar1.drinks.first { $0.type == options.drinkType }
                let drinkInBar2 = bar2.drinks.first { $0.type == options.drinkType }
                
                let score1 = drinkInBar1?.score ?? bar1.rate
                let score2 = drinkInBar2?.score ?? bar2.rate
                
                return score1 > score2
            }
        }
        
        self.annotatedBars = filtered
    }

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
    
    var currentRegion: MKCoordinateRegion?
    
    
    func moveToUserLocation() {
        let region = MKCoordinateRegion(
            center: mockUserCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
        )
        withAnimation(.easeInOut(duration: 0.6)) {
            self.cameraPosition = .region(region)
        }
        print("✈️ Камера перелетела на Площадь Революции")
    }
    
    func zoomIn() {
        let activeRegion = currentRegion ?? cameraPosition.region ?? MKCoordinateRegion(
            center: cityCenters[filters.city] ?? CLLocationCoordinate2D(latitude: 53.2001, longitude: 50.1500),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        
        var newRegion = activeRegion
        
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
        
        if newRegion.span.latitudeDelta < 30.0 {
            newRegion.span.latitudeDelta *= 2.0
            newRegion.span.longitudeDelta *= 2.0
        }
        
        withAnimation(.easeInOut(duration: 0.25)) {
            cameraPosition = .region(newRegion)
        }
    }
}
