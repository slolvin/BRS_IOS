//
//  ProfileView.swift
//  BRS
//
//  Created by Haris York on 06.06.2026.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @Environment(\.dismiss) var dismiss // Позволит закрыть экран, если откроем его модально
    
    var body: some View {
        ZStack {
            // Фон
            Color(red: 0.1, green: 0.1, blue: 0.12)
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView().tint(.blue).scaleEffect(1.5)
            } else if let profile = viewModel.profile {
                VStack(spacing: 24) {
                    
                    // 1. Аватар и Юзернейм
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 90, height: 90)
                                .overlay(Circle().stroke(Color.blue.opacity(0.3), lineWidth: 2))
                            
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                        }
                        
                        Text(profile.username.uppercased())
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .tracking(1)
                        
                        Text(profile.email)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 20)
                    
                    // 2. Тег Роли (Полиморфизм)
                    Text(profile.role.uppercased())
                        .font(.caption)
                        .fontWeight(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.purple.opacity(0.15))
                        .foregroundColor(.purple)
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.purple.opacity(0.3), lineWidth: 1))
                    
                    // 3. Карточки Статистики
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            StatCard(title: "Позиций в баре", value: "\(profile.stats.totalDrinksManaged)", icon: "wineglass.fill", color: .blue)
                            StatCard(title: "Топ категория", value: profile.stats.favoriteCategory, icon: "star.fill", color: .orange)
                        }
                        
                        // Длинная карточка даты регистрации
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.green)
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("В системе БРС с")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                Text(profile.stats.registeredAt)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(16)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            } else if let error = viewModel.errorMessage {
                Text(error).foregroundColor(.red)
            }
        }
        .navigationTitle("Профиль")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadProfile()
        }
    }
}

// Вспомогательный компонент для маленькой карточки
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.headline)
                Spacer()
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .greatestFiniteMagnitude)
        .background(Color.white.opacity(0.04))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.02), lineWidth: 1))
    }
}
