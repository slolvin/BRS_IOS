//
//  MainMapView.swift
//  BRS
//
//  Created by Haris York on 06.06.2026.
//
import SwiftUI
import MapKit

struct MainMapView: View {
    @StateObject private var viewModel = MapViewModel()
    // 1. Свойство для хранения ID выбранного бара, на который нажали
    @State private var selectedBarId: Int?
    
    var body: some View {
        NavigationStack { // 2. Обертываем всё в NavigationStack для работы переходов
            ZStack {
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
                            // 3. Обрабатываем нажатие на сам маркер
                            .onTapGesture {
                                selectedBarId = bar.id
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
            // 4. Описываем, какой экран открывать при изменении selectedBarId
            .navigationDestination(item: $selectedBarId) { barId in
                BarDetailView(viewModel: BarDetailViewModel(barId: barId))
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
