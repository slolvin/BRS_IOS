//
//  SignUpView.swift
//  BRS
//
//  Created by Haris York on 15.09.2026.
//

import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var successMessage: String? = nil
    
    private let service = DrinkService()
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Данные профиля")) {
                    TextField("Имя пользователя", text: $username)
                        .autocorrectionDisabled()
                    
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                
                Section(header: Text("Безопасность"), footer: Text("Пароль должен быть не менее 6 символов.")) {
                    SecureField("Пароль", text: $password)
                    SecureField("Повторите пароль", text: $confirmPassword)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.subheadline)
                    }
                }
                
                if let success = successMessage {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "envelope.badge.shield.half.filled")
                                    .foregroundColor(.green)
                                Text("Успешно!")
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                            Text(success)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Button(action: handleSignUp) {
                    HStack {
                        Spacer()
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Зарегистрироваться")
                                .fontWeight(.bold)
                        }
                        Spacer()
                    }
                }
                .disabled(isLoading || successMessage != nil)
            }
            .navigationTitle("Создать аккаунт")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
        }
    }
    
    private func handleSignUp() {
        errorMessage = nil
        
        let cleanUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleanUsername.isEmpty, !cleanEmail.isEmpty, !password.isEmpty else {
            errorMessage = "Пожалуйста, заполните все поля."
            return
        }
        
        guard password.count >= 6 else {
            errorMessage = "Пароль слишком короткий."
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "Пароли не совпадают."
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let msg = try await service.registerUser(
                    username: cleanUsername,
                    email: cleanEmail,
                    password: password
                )
                successMessage = msg
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    dismiss()
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
