//
//  LoginView.swift
//  BRS
//
//  Created by Haris York on 06.06.2026.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var isPasswordVisible = false
    // 🌟 ИСПРАВЛЕНО: Объявляем стейт для вызова шторки регистрации
    @State private var isShowingSignUp = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Глубокий темный фон всей экосистемы БРС
                Color(red: 0.1, green: 0.1, blue: 0.12)
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    // Шапка экрана / Логотип
                    VStack(spacing: 12) {
                        Image(systemName: "wineglass.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                        
                        Text("БРС СИСТЕМА")
                            .font(.largeTitle)
                            .fontWeight(.black)
                            .foregroundColor(.white)
                            .tracking(2)
                        
                        Text("Авторизация мобильного приложения")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    // Форма ввода
                    VStack(spacing: 16) {
                        // Поле ввода Email
                        HStack(spacing: 12) {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.gray)
                                .frame(width: 20)
                            
                            TextField("Email", text: $viewModel.email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.05), lineWidth: 1))
                        
                        // Поле ввода Пароля с переключателем видимости
                        HStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.gray)
                                .frame(width: 20)
                            
                            if isPasswordVisible {
                                TextField("Пароль", text: $viewModel.password)
                                    .foregroundColor(.white)
                            } else {
                                SecureField("Пароль", text: $viewModel.password)
                                    .foregroundColor(.white)
                            }
                            
                            Button(action: { isPasswordVisible.toggle() }) {
                                Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.05), lineWidth: 1))
                    }
                    .padding(.horizontal, 24)
                    
                    // Вывод ошибок валидации/сервера
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    
                    // Кнопка отправки формы
                    Button(action: {
                        Task {
                            _ = await viewModel.performLogin()
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Войти в аккаунт")
                                    .fontWeight(.bold)
                                Image(systemName: "arrow.right.circle.fill")
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(14)
                        .shadow(color: Color.blue.opacity(0.3), radius: 10, y: 5)
                    }
                    .disabled(viewModel.isLoading)
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    // Кнопка переключения на регистрацию
                    Button(action: {
                        isShowingSignUp = true
                    }) {
                        Text("Еще нет аккаунта? Зарегистрироваться")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .padding(.bottom, 16)
                    .sheet(isPresented: $isShowingSignUp) {
                        SignUpView()
                    }
                }
            }
        }
    }
}

#Preview {
    LoginView()
}
