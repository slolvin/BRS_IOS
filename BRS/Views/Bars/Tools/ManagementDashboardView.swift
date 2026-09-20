//
//  ManagementDashboardView.swift
//  BRS
//
//  Created by Haris York on 17.09.2026.
//

import SwiftUI

struct ManagementDashboardView: View {
    @StateObject private var viewModel = ManagementDashboardViewModel()
    // 🌟 Добавляем профиль для точной проверки роли на клиенте
    @StateObject private var profileViewModel = ProfileViewModel()
    @State private var isShowingAddBar = false
    
    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                ProgressView("Загрузка ваших заведений...")
                    .padding(.top, 40)
            } else if viewModel.managedBars.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("Нет баров под управлением")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if profileViewModel.profile?.role.lowercased() == "administrator" {
                        Text("Нажмите на кнопку '+' в верхнем углу, чтобы зарегистрировать своё первое заведение в БРС.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    } else {
                        Text("За вашим аккаунтом пока не закреплено ни одного заведения БРС. Обратитесь к главному администратору системы.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }
                .padding(.top, 60)
            } else {
                LazyVStack(spacing: 14) {
                    ForEach(viewModel.managedBars) { bar in
                        NavigationLink(destination: BarManagementDetailView(barId: bar.id, barName: bar.name, currentAddress: bar.address)) {
                            ManagedBarRow(
                                barName: bar.name,
                                address: bar.address,
                                rating: bar.rate,
                                qrHash: bar.qrSecretHash
                            )
                        }
                        .buttonStyle(PlainButtonStyle()) // Убирает дефолтное синее окрашивание текста ссылки
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Управление")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Параллельно загружаем и бары, и профиль для сверки роли
            await viewModel.loadManagedBars()
            await profileViewModel.loadProfile()
        }
        .toolbar {
            // 🌟 КРИТИЧЕСКИЙ ФИКС: Кнопка "+" рендерится ТОЛЬКО для администратора
            if let role = profileViewModel.profile?.role.lowercased(), role == "administrator" {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isShowingAddBar = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingAddBar) {
            AddBarView()
                .onDisappear {
                    Task { await viewModel.loadManagedBars() }
                }
        }
    }
}
