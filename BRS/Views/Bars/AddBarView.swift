//
//  AddBarView.swift
//  BRS
//
//  Created by Haris York on 13.09.2026.
//

import SwiftUI

struct AddBarView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddBarViewModel()
    @AppStorage("isDarkMode") private var isDarkMode = true
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Основная информация").foregroundColor(.blue)) {
                    TextField("Название бара", text: $viewModel.name)
                        .autocorrectionDisabled()
                    
                    // ИСПРАВЛЕНО: Используем нативный prompt для красивого отображения подсказки серого цвета
                    TextField(
                        "Адрес",
                        text: $viewModel.address,
                        prompt: Text("ул. Куйбышева, 81").foregroundColor(.gray.opacity(0.4))
                    )
                    .autocorrectionDisabled()
                    
                    TextField("Город", text: $viewModel.city)
                        .autocorrectionDisabled()
                }
                
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle("Новое заведение")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Создать") {
                        Task {
                            let success = await viewModel.createBar()
                            if success { dismiss() }
                        }
                    }
                    .disabled(viewModel.name.isEmpty || viewModel.address.isEmpty || viewModel.isLoading)
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.15))
                }
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}
