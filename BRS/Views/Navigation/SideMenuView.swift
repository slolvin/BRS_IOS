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
            if isOpen {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation { isOpen = false }
                    }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 24) {
                    
                    NavigationLink(destination: ProfileView()) {
                        HStack(spacing: 14) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                if let profile = profileViewModel.profile {
                                    Text(profile.displayUsername)
                                        .font(.system(.headline, design: .rounded))
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    
                                    roleText(profile.role.lowercased())
                                } else {
                                    Text("ЗАГРУЗКА...")
                                        .font(.headline)
                                        .foregroundColor(.gray)
                                    Text("Пожалуйста, подождите")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundColor(.gray.opacity(0.5))
                        }
                        .padding()
                        .background(Color.white.opacity(0.03))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .simultaneousGesture(TapGesture().onEnded { _ in
                        withAnimation { isOpen = false }
                    })
                    .padding(.top, 60)
                    .padding(.horizontal)
                    .task {
                        if profileViewModel.profile == nil {
                            await profileViewModel.loadProfile()
                        }
                    }
                    
                    Divider().background(Color.white.opacity(0.1))
                    
                    VStack(alignment: .leading, spacing: 22) {
                        if let profile = profileViewModel.profile {
                            let role = profile.role.lowercased()
                            
                            if role == "user" {
                                NavigationLink(destination: FavoriteBarsView()) {
                                    HStack(spacing: 16) {
                                        Image(systemName: "building.2.fill")
                                            .foregroundColor(.blue)
                                        Text("Мои Бары")
                                        Spacer()
                                    }
                                    .foregroundColor(.white)
                                    .font(.body)
                                }
                                .simultaneousGesture(TapGesture().onEnded { _ in
                                    withAnimation { isOpen = false }
                                })
                                
                                NavigationLink(destination: FavoriteDrinksView()) {
                                    HStack(spacing: 16) {
                                        Image(systemName: "wineglass.fill")
                                            .foregroundColor(.blue)
                                        Text("Избранные напитки")
                                        Spacer()
                                    }
                                    .foregroundColor(.white)
                                    .font(.body)
                                }
                                .simultaneousGesture(TapGesture().onEnded { _ in
                                    withAnimation { isOpen = false }
                                })
                                
                            } else {
                                NavigationLink(destination: ManagementDashboardView()) {
                                    HStack(spacing: 16) {
                                        Image(systemName: "briefcase.fill")
                                            .foregroundColor(.orange)
                                        Text(role == "administrator" ? "Управление сетью" : "Управление баром")
                                        Spacer()
                                    }
                                    .foregroundColor(.white)
                                    .font(.body)
                                }
                                .simultaneousGesture(TapGesture().onEnded { _ in
                                    withAnimation { isOpen = false }
                                })
                                
                                if role == "administrator" {
                                    NavigationLink(destination: UsersManagementView()) {
                                        HStack(spacing: 16) {
                                            Image(systemName: "person.2.fill")
                                                .foregroundColor(.red)
                                            Text("Пользователи")
                                            Spacer()
                                        }
                                        .foregroundColor(.white)
                                        .font(.body)
                                    }
                                    .simultaneousGesture(TapGesture().onEnded { _ in
                                        withAnimation { isOpen = false }
                                    })
                                }
                            }
                        }
                        
                        NavigationLink(destination: SettingsView()) {
                            HStack(spacing: 16) {
                                Image(systemName: "gearshape.fill")
                                    .foregroundColor(.gray)
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
                .background(Color(red: 0.1, green: 0.1, blue: 0.12).ignoresSafeArea())
                                .offset(x: isOpen ? 0 : -280)
                                .animation(.spring(), value: isOpen)
                                
                                Spacer()
                            }
                        }
                    }
                    
                    private func roleText(_ role: String) -> some View {
                        let text: String
                        let color: Color
                        
                        switch role {
                        case "administrator":
                            text = "Администратор"
                            color = .red
                        case "manager":
                            text = "Менеджер"
                            color = .orange
                        default:
                            text = "Посетитель"
                            color = .gray
                        }
                        
                        return Text(text)
                            .font(.caption2)
                            .bold()
                            .foregroundColor(color)
                    }
                }
                
