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
    @State private var selectedUser: AdminUserItem? = nil
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.users) { user in
                    HStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.title2)
                            .foregroundColor(user.role.lowercased() == "administrator" ? .red : (user.role.lowercased() == "manager" ? .blue : .gray))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(user.username.uppercased())
                                .font(.system(.subheadline, design: .rounded)).bold()
                            Text(user.email)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(user.displayRole)
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(6)
                        
                        Button(action: { selectedUser = user }) {
                            Text("Изменить")
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
            .navigationTitle("Пользователи")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Поиск по никнейму...")
            .onChange(of: searchText) { newValue in
                Task { await viewModel.loadUsers(search: newValue) }
            }
            .task {
                await viewModel.loadUsers()
            }
            .sheet(item: $selectedUser) { user in
                EditUserRightsView(user: user) {
                    Task { await viewModel.loadUsers(search: searchText) }
                }
            }
        }
    }
}
