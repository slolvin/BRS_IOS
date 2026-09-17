//
//  BarManagementDetailView.swift
//  BRS
//
//  Created by Haris York on 18.09.2026.
//
import SwiftUI

struct BarManagementDetailView: View {
    let barId: Int
    let barName: String
    let currentAddress: String
    
    @StateObject private var viewModel = BarDetailViewModel(barId: 0) // Переиспользуем для загрузки меню
    @State private var isShowingAddDrinkForm = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // === БЛОК ОБЩИХ ДАННЫХ И ЗАТЫЧЕК ===
                VStack(alignment: .leading, spacing: 16) {
                    Text("Общая информация").font(.headline).foregroundColor(.secondary)
                    
                    // Затычка 1: Изменение фотографии заведения
                    Button(action: { /* Затычка выбора файла */ }) {
                        HStack {
                            Image(systemName: "photo.badge.plus")
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Обновить фотографию заведения")
                                    .font(.subheadline).bold()
                                Text("Файл не выбран").font(.caption).foregroundColor(.gray)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption).foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(red: 0.16, green: 0.16, blue: 0.20))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Затычка 2: Время работы и календарь
                    HStack(spacing: 14) {
                        Image(systemName: "clock.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Время работы заведения")
                                .font(.subheadline).bold()
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                Text("Сегодня: Закрыты")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color(red: 0.16, green: 0.16, blue: 0.20))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Divider().background(Color.white.opacity(0.1)).padding(.horizontal)
                
                // === АССОРТИМЕНТ И МЕНЮ БАРА ===
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Ассортимент и меню")
                            .font(.title3).bold()
                        Spacer()
                        
                        // Кнопка добавления напитка
                        Button(action: { isShowingAddDrinkForm = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                Text("Напиток")
                            }
                            .font(.system(size: 14, weight: .bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                        }
                    }
                    
                    if viewModel.isLoading {
                        ProgressView().frame(maxWidth: .infinity).padding()
                    } else if let drinks = viewModel.bar?.drinks, !drinks.isEmpty {
                        // Рендерим нативный список позиций (Ячейки из веб-версии Jagenmeister/Smirnoff)
                        VStack(spacing: 12) {
                            ForEach(drinks, id: \.id) { drink in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(drink.name)
                                            .font(.headline)
                                            .bold()
                                            .foregroundColor(.white)
                                        
                                        // Чистый вывод без математического форматирования внутри верстки
                                        Text("\(drink.volume) мл • \(drink.formattedAbv)%")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    
                                    Text(drink.type)
                                        .font(.caption2)
                                        .bold()
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.2))
                                        .foregroundColor(.blue)
                                        .cornerRadius(6)
                                }
                                .padding()
                                .background(Color(red: 0.16, green: 0.16, blue: 0.20))
                                .cornerRadius(12)
                            }
                        }
                    } else {
                        Text("Меню бара пусто. Добавьте первый напиток.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 20)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(red: 0.12, green: 0.12, blue: 0.15).ignoresSafeArea()) // Наша темная тема
        .navigationTitle(barName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Для отображения текущего ассортимента просто переиспользуем логику загрузки карточки бара
            // Создаем кастомный таск на лету, подменяя внутренний ID
            let vm = BarDetailViewModel(barId: barId)
            vm.loadBarDetails()
            self.viewModel.bar = vm.bar
        }
        .sheet(isPresented: $isShowingAddDrinkForm) {
            AddDrinkFormView(barId: barId) {
                // Замыкание обновления: когда форма закрывается, перечитываем меню заново
                let vm = BarDetailViewModel(barId: barId)
                Task {
                    vm.loadBarDetails()
                    self.viewModel.bar = vm.bar
                }
            }
        }
    }
}
