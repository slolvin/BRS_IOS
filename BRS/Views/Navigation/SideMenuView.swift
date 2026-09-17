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
                            if let profile = profileViewModel.profile {
                                Text(profile.username.uppercased())
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(profile.role.capitalized)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            } else {
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
                    
                    // Список пунктов меню
                    VStack(alignment: .leading, spacing: 22) {
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
                                    .foregroundColor(.blue)
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
                            withAnimation { isOpen = false }
                        })
                        
                        // 🌟 ИСПРАВЛЕННЫЙ РОЛЕВОЙ БЛОК: Разделяем "Мои Бары" и "Управление"
                        if let profile = profileViewModel.profile,
                           (profile.role.lowercased() == "administrator" || profile.role.lowercased() == "manager") {
                            
                            NavigationLink(destination: ManagementDashboardView()) {
                                HStack(spacing: 16) {
                                    Image(systemName: "briefcase.fill")
                                        .foregroundColor(.blue)
                                    Text("Управление")
                                    Spacer()
                                }
                                .foregroundColor(.white)
                                .font(.body)
                            }
                        } else {
                            // Обычный гость видит только Избранное
                            NavigationLink(destination: FavoriteBarsView()) {
                                HStack(spacing: 16) {
                                    Image(systemName: "building.2.fill")
                                    Text("Мои Бары")
                                    Spacer()
                                }
                            }
                        }
                        if let profile = profileViewModel.profile, profile.role.lowercased() == "administrator" {
                            // 🌟 НОВИНКА: Кнопка тотального контроля пользователей системы БРС
                            NavigationLink(destination: UsersManagementView()) {
                                Label("Пользователи", systemImage: "person.2.governance.fill")
                                    .foregroundColor(.red) // Выделим красным под стать важности прав!
                            }
                        }
                        
                        NavigationLink(destination: SettingsView()) {
                            HStack(spacing: 16) {
                                Image(systemName: "gearshape.fill")
                                Text("Настройки")
                                Spacer()
                            }
                            .foregroundColor(.white)
                            .font(.body)
                        }
                        .simultaneousGesture(TapGesture().onEnded { _ in
                            withAnimation { isOpen = false }
                        })
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Кнопка logout (Разлогин)
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
                .offset(x: isOpen ? 0 : -280)
                .animation(.spring(), value: isOpen)
                
                Spacer()
            }
        }
    }
}
