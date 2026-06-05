//
//  LoginView.swift
//  BRS
//
//  Created by Haris York on 06.06.2026.
//

import SwiftUI

struct LoginView: View {
    @State private var inputUsername = "sl@sl"
    @State private var inputPassword = "sl"
    @ObservedObject private var authManager = AuthManager.shared
    
    var body: some View {
        ZStack {
            // Темный фон
            Color(red: 0.1, green: 0.1, blue: 0.12)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Логотип/Иконка
                VStack(spacing: 12) {
                    Image(systemName: "wineglass.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    Text("BRS SYSTEM")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .tracking(2)
                }
                .padding(.bottom, 20)
                
                // Инпуты
                VStack(alignment: .leading, spacing: 16) {
                    // Логин
                    VStack(alignment: .leading, spacing: 6) {
                        Text("ЛОГИН")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .fontWeight(.bold)
                        
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                            TextField("Введите логин", text: $inputUsername)
                                .foregroundColor(.white)
                                .autocapitalization(.none)
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                    }
                    
                    // Пароль
                    VStack(alignment: .leading, spacing: 6) {
                        Text("ПАРОЛЬ")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .fontWeight(.bold)
                        
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.gray)
                            SecureField("Введите пароль", text: $inputPassword)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                // Кнопка Войти
                Button(action: {
                    if !inputUsername.isEmpty && !inputPassword.isEmpty {
                        authManager.login(user: inputUsername, pass: inputPassword)
                    }
                }) {
                    Text("ВОЙТИ В СИСТЕМУ")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .greatestFiniteMagnitude)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.top, 10)
            }
            .padding()
        }
    }
}

#Preview {
    LoginView()
}
