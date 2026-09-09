//
//  MapFilterPanelView.swift
//  BRS
//
//  Created by Haris York on 09.09.2026.
//

import SwiftUI

struct MapFilterPanelView: View {
    @ObservedObject var viewModel: MapViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // Фильтр: Город
                Menu {
                    Picker("Город", selection: $viewModel.filters.city) {
                        ForEach(viewModel.availableCities, id: \.self) { Text($0) }
                    }
                } label: {
                    FilterBadge(title: viewModel.filters.city, icon: "mappin.and.ellipse")
                }
                
                // Фильтр: Тип напитка
                Menu {
                    Picker("Тип напитка", selection: $viewModel.filters.drinkType) {
                        ForEach(viewModel.availableDrinkTypes, id: \.self) { Text($0) }
                    }
                } label: {
                    FilterBadge(title: viewModel.filters.drinkType, icon: "wineglass")
                }
                
                // Фильтр: Открыто сейчас (Toggle-кнопка)
                Button(action: {
                    viewModel.filters.isOpenNow.toggle()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.filters.isOpenNow ? "clock.fill" : "clock")
                        Text("Открыто")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(viewModel.filters.isOpenNow ? Color.blue : Color(.secondarySystemBackground))
                    .foregroundColor(viewModel.filters.isOpenNow ? .white : .primary)
                    .cornerRadius(20)
                }
                
                // Фильтр: Рейтинг
                Menu {
                    Picker("Рейтинг", selection: $viewModel.filters.rating) {
                        ForEach(viewModel.ratings, id: \.self) { Text($0) }
                    }
                } label: {
                    FilterBadge(title: "Рейтинг: \(viewModel.filters.rating)", icon: "star.fill")
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground).opacity(0.85))
        .background(.ultraThinMaterial) // Красивое размытие под фильтрами
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// Вспомогательный элемент для кнопок меню
struct FilterBadge: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(title)
                .font(.system(size: 14, weight: .medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
        .foregroundColor(.primary)
        .cornerRadius(20)
    }
}
