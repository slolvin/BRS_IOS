//
//  AddDrinkView.swift
//  BRS
//
//  Created by Haris York on 13.09.2026.
//
import Combine
import SwiftUI

struct AddDrinkView: View {
    let barId: Int
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddDrinkViewModel()
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Параметры напитка").foregroundColor(.blue)) {
                    TextField("Название (например: IPA)", text: $viewModel.name)
                    
                    Picker("Категория", selection: $viewModel.type) {
                        Text("Пиво").tag("Пиво")
                        Text("Коктейли").tag("Коктейли")
                        Text("Вино").tag("Вино")
                        Text("Крепкий алкоголь").tag("Крепкий алкоголь")
                    }
                    
                    HStack {
                        Text("Крепость (ABV %)")
                        Spacer()
                        TextField("0.0", text: $viewModel.abv)
                            .keyboardType(.decimalPad)
                            .frame(width: 60)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    TextField("Ссылка на изображение (URL)", text: $viewModel.imageUrl)
                        .keyboardType(.URL)
                }
                
                if let error = viewModel.errorMessage {
                    Text(error).foregroundColor(.red)
                }
            }
            .navigationTitle("Добавить напиток")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Добавить") {
                        Task {
                            let success = await viewModel.createDrink(forBarId: barId)
                            if success { dismiss() }
                        }
                    }
                    .disabled(viewModel.name.isEmpty || viewModel.abv.isEmpty || viewModel.isLoading)
                }
            }
        }
    }
}

// Вью-модель для напитка
@MainActor
class AddDrinkViewModel: ObservableObject {
    @Published var name = ""
    @Published var type = "Пиво"
    @Published var abv = ""
    @Published var imageUrl = ""
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    private let service = DrinkService()
    
    func createDrink(forBarId barId: Int) async -> Bool {
        self.isLoading = true
        
        // Согласно JSON спецификации из паспорта, крепость должна улетать как Float/Double
        let abvValue = Double(abv.replacingOccurrences(of: ",", with: ".")) ?? 0.0
        
        let body: [String: Any] = [
            "name": name,
            "type": type,
            "abv": abvValue,
            "image_url": imageUrl.isEmpty ? "https://placeholder.com" : imageUrl
        ]
        
        do {
            try await service.createNewDrink(barId: barId, params: body)
            self.isLoading = false
            return true
        } catch {
            self.errorMessage = "Не удалось сохранить напиток"
            self.isLoading = false
            return false
        }
    }
}
