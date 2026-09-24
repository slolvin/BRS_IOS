//
//  EditUserRightsView.swift
//  BRS
//
//  Created by Haris York on 18.09.2026.
//

import SwiftUI

struct EditUserRightsView: View {
    let user: AdminUserItem
    var onSaveSuccess: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var username: String
    @State private var email: String
    @State private var role: String
    @State private var realName: String
    @State private var location: String
    @State private var aboutMe: String
    @State private var isSaving = false
    
    let roles = ["user", "manager", "administrator"]
    private let drinkService = DrinkService() // Используем ваш сетевой слой
    
    init(user: AdminUserItem, onSaveSuccess: @escaping () -> Void) {
        self.user = user
        self.onSaveSuccess = onSaveSuccess
        // Предзаполняем поля текущими данными из БД при GET-рендере модалки
        _username = State(initialValue: user.username)
        _email = State(initialValue: user.email)
        _role = State(initialValue: user.role.lowercased())
        _realName = State(initialValue: user.name)
        _location = State(initialValue: user.location)
        _aboutMe = State(initialValue: user.aboutMe)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Системные данные")) {
                    TextField("Никнейм", text: $username)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                }
                
                Section(header: Text("Уровень доступа / Роль")) {
                    Picker("Выбрать роль", selection: $role) {
                        Text("Обычный пользователь (User)").tag("user")
                        Text("Менеджер (Manager)").tag("manager")
                        Text("Администратор (Administrator)").tag("administrator")
                    }
                }
                
                Section(header: Text("Личная информация")) {
                    TextField("Реальное имя", text: $realName)
                    TextField("Город проживания", text: $location)
                    TextField("О пользователе", text: $aboutMe, axis: .vertical)
                        .lineLimit(3...5)
                }
            }
            .navigationTitle("Управление правами")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        Task { await saveUserRights() }
                    }
                    .bold()
                    .disabled(isSaving || username.isEmpty || email.isEmpty)
                }
            }
            .overlay {
                if isSaving { ProgressView("Сохраняем изменения в СУБД...").padding().background(.ultraThinMaterial).cornerRadius(10) }
            }
        }
    }
    
    private func saveUserRights() async {
        isSaving = true
        let body: [String: Any] = [
            "username": username,
            "email": email,
            "role": role,
            "name": realName,
            "location": location,
            "about_me": aboutMe
        ]
        
        do {
            // Отправляем изменения по новому эндпоинту админа
            try await drinkService.postEditUserRights(userId: user.id, body: body)
            onSaveSuccess()
            dismiss()
        } catch {
            print("❌ Ошибка администрирования БРС: \(error.localizedDescription)")
        }
        isSaving = false
    }
}
