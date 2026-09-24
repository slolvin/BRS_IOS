//
//  EditProfileView.swift
//  BRS
//
//  Created by Haris York on 18.09.2026.
//

import SwiftUI

struct EditProfileView: View {
    // 🌟 Теперь передаем честный, актуальный объект из вашей кодовой базы
    let currentProfile: UserProfileResponse
    var onUpdateSuccess: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var email: String
    @State private var realName: String
    @State private var location: String
    @State private var aboutMe: String
    
    // Блок раскрывающейся плашки безопасности
    @State private var isSecurityExpanded = false
    @State private var password = ""
    @State private var passwordConfirm = ""
    
    @State private var isSaving = false
    @State private var errorMessage: String? = nil
    private let drinkService = DrinkService()
    
    init(currentProfile: UserProfileResponse, onUpdateSuccess: @escaping () -> Void) {
        self.currentProfile = currentProfile
        self.onUpdateSuccess = onUpdateSuccess
        
        // Безопасно предзаполняем поля из опционалов модели данных БРС
        _email = State(initialValue: currentProfile.email ?? "")
        _realName = State(initialValue: currentProfile.name ?? "")
        _location = State(initialValue: currentProfile.location ?? "")
        _aboutMe = State(initialValue: currentProfile.aboutMe ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Личные данные")) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    
                    TextField("Реальное имя", text: $realName)
                    TextField("Город проживания", text: $location)
                    TextField("О себе", text: $aboutMe, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                // РАСКРЫВАЮЩАЯСЯ ПЛАШКА БЕЗОПАСНОСТИ
                Section {
                    DisclosureGroup("Безопасность аккаунта", isExpanded: $isSecurityExpanded) {
                        VStack(spacing: 12) {
                            SecureField("Новый пароль", text: $password)
                                .textFieldStyle(.roundedBorder)
                                .textInputAutocapitalization(.never)
                            
                            SecureField("Повторите пароль", text: $passwordConfirm)
                                .textFieldStyle(.roundedBorder)
                                .textInputAutocapitalization(.never)
                        }
                        .padding(.vertical, 8)
                    }
                    .tint(.blue)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error).foregroundColor(.red).font(.caption)
                    }
                }
            }
            .navigationTitle("Редактировать профиль")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        Task { await saveProfileChanges() }
                    }
                    .bold()
                    .disabled(email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
            }
            .overlay {
                if isSaving { ProgressView("Обновляем Postgres...").padding().background(.ultraThinMaterial).cornerRadius(10) }
            }
        }
    }
    
    private func saveProfileChanges() async {
        isSaving = true
        errorMessage = nil
        
        let body: [String: Any] = [
            "email": email.trimmingCharacters(in: .whitespacesAndNewlines),
            "name": realName.trimmingCharacters(in: .whitespacesAndNewlines),
            "location": location.trimmingCharacters(in: .whitespacesAndNewlines),
            "about_me": aboutMe.trimmingCharacters(in: .whitespacesAndNewlines),
            "password": password,
            "password_confirm": passwordConfirm
        ]
        
        do {
            try await drinkService.postEditOwnProfile(body: body)
            onUpdateSuccess()
            dismiss()
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}
