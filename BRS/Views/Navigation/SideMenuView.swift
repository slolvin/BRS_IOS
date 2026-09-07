//
//  SideMenuView.swift
//  BRS
//
//  Created by Haris York on 06.06.2026.
//

import SwiftUI

struct SideMenuView: View {
    @Binding var isOpen: Bool
    @ObservedObject private var authManager = AuthManager.shared
    @State private var showProfilePlaceholder = false
    @StateObject private var profileViewModel = ProfileViewModel()
    
    var body: some View {
        ZStack {
            // Размытый полупрозрачный фон при открытии меню
            if isOpen {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation { isOpen = false }
                    }
            }
            
            // Само меню
            HStack {
                VStack(alignment: .leading, spacing: 32) {
                    // Хедер меню
                    HStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            // ИСПРАВЛЕНО: берем имя и роль из profileViewModel, а не из менеджера авторизации
                            if let profile = profileViewModel.profile {
                                Text(profile.username.uppercased())
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(profile.role.capitalized)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            } else {
                                // Заглушка на время, пока данные скачиваются с сервера Flask
                                Text("ЗАГРУЗКА...")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                Text("Пожалуйста, подождите")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .task {
                        if profileViewModel.profile == nil {
                            await profileViewModel.loadProfile()
                        }
                    }
                    .padding(.top, 60)
                    .padding(.horizontal)
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    NavigationLink(destination: ProfileView()) {
                        HStack(spacing: 16) {
                            Image(systemName: "person.fill")
                            Text("Профиль пользователя")
                            Spacer()
                        }
                        .foregroundColor(.white)
                        .font(.body)
                    }
                    .simultaneousGesture(TapGesture().onEnded { _ in
                        withAnimation { isOpen = false }
                    })
                    NavigationLink(destination: DrinksListView()) {
                        HStack(spacing: 16) {
                            Image(systemName: "wineglass.fill")
                                .foregroundColor(.blue) // подсветим синим в стиль приложения
                            Text("Барная карта (Напитки)")
                                .foregroundColor(.white)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        .font(.body)
                    }
                    .simultaneousGesture(TapGesture().onEnded { _ in
                        // Плавно закрываем шторку бургер-меню, чтобы при возврате назад меню было закрыто
                        withAnimation { isOpen = false }
                    })
                    // Кнопки навигации (Заглушки)
                    NavigationLink(destination: FavoriteBarsView()) {
                        HStack {
                            Image(systemName: "building.2.fill")
                            Text("Мои Бары")
                        }
                    }

                    NavigationLink(destination: SettingsView()) {
                        HStack {
                            Image(systemName: "gearshape.fill")
                            Text("Настройки")
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Кнопка Сlogout (Разлогин)
                    Button(action: {
                        withAnimation {
                            authManager.logout()
                        }
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.forward")
                            Text("Выйти")
                        }
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .greatestFiniteMagnitude, alignment: .leading)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
                .frame(width: 280)
                .background(Color(red: 0.12, green: 0.12, blue: 0.15))
                .offset(x: isOpen ? 0 : -280) // Сдвигаем влево/вправо в зависимости от состояния
                .animation(.spring(), value: isOpen)
                
                Spacer() // Выталкивает меню влево
            }
        }
    }
}
