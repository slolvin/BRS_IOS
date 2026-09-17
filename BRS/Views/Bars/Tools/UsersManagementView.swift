//
//  UsersManagementView.swift
//  BRS
//
//  Created by Haris York on 18.09.2026.
//

import SwiftUI

struct UsersManagementView: View {
    @StateObject private var viewModel = UsersManagementViewModel()
    @State private var searchText = ""
    @State private var selectedUser: AdminUserItem? = nil // Триггер для модалки редактирования
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.users) { user in
                    HStack(spacing: 12) {
                        // Аватарка-затычка
                        Image(systemName: "person.crop.circle.fill")
                            .font(.title2)
                            .foregroundColor(user.role.lowercased() == "administrator" ? .red : (user.role.lowercased() == "manager" ? .blue : .gray))
                        
                        // Ник и Email
                        VStack(alignment: .leading, spacing: 2) {
                            Text(user.username.uppercased())
                                .font(.system(.subheadline, design: .rounded)).bold()
                            Text(user.email)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Бейдж Роли (как серая плашка в вебе)
                        Text(user.displayRole)
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(6)
                        
                        // Кнопка EDIT (Кнопка Действия из веба)
                        Button(action: { selectedUser = user }) {
                            Text("EDIT")
                                .font(.system(size: 12, weight: .bold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.15))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.vertical, 2)
                }
            }
            .navigationTitle("Пользователи системы")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Поиск по никнейму...")
            // Срабатывает на лету при вводе текста в поиск, имитируя веб-фильтр ilike
            .onChange(of: searchText) { newValue in
                Task { await viewModel.loadUsers(search: newValue) }
            }
            .task {
                await viewModel.loadUsers()
            }
            // Вызываем модальное окно «Управление правами» поверх списка
            .sheet(item: $selectedUser) { user in
                EditUserRightsView(user: user) {
                    // Замыкание успеха: обновляем список после сохранения прав
                    Task { await viewModel.loadUsers(search: searchText) }
                }
            }
        }
    }
}
