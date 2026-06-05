//
//  MainMapView.swift
//  BRS
//
//  Created by Haris York on 06.06.2026.
//
import SwiftUI
import MapKit // Оставляем только один импорт MapKit

struct MainMapView: View {
    @StateObject private var viewModel = MapViewModel()
    
    var body: some View {
        ZStack {
            // Инициализатор нового поколения: принимает состояние позиции камеры и замыкание контента
            Map(position: $viewModel.cameraPosition) {
                // Перечисляем маркеры через ForEach внутри MapContentBuilder
                ForEach(viewModel.annotatedBars) { bar in
                    // СОВРЕМЕННЫЙ СТАНДАРТ: Вместо MapAnnotation используем обычный Annotation
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
                    }
                }
            }
            .ignoresSafeArea(edges: .top)
            
            .mapControls {
                            MapCompass()
                            MapPitchToggle()
                            MapUserLocationButton()
                        }
                        .ignoresSafeArea(edges: .top)
            
            // Индикатор загрузки поверх карты
            if viewModel.isLoading {
                ProgressView()
                    .tint(.blue)
                    .scaleEffect(1.5)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(12)
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await viewModel.loadBarsOnMap()
        }
    }
}

#Preview {
    MainMapView()
}
