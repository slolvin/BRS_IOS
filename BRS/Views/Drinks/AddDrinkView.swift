//
//  AddDrinkView.swift
//  BRS
//
//  Created by Haris York on 13.09.2026.
//

import SwiftUI
import PhotosUI
import Combine

struct AddDrinkView: View {
    let barId: Int
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddDrinkViewModel()
    
    @State private var selectedItem: PhotosPickerItem? = nil
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Фотография").foregroundColor(.blue)) {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            if let selectedImage = viewModel.selectedUiImage {
                                Image(uiImage: selectedImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .shadow(radius: 4)
                            } else {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.04))
                                        .frame(width: 120, height: 120)
                                    Image(systemName: "camera.fill")
                                        .font(.largeTitle)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                Text(viewModel.selectedUiImage == nil ? "Выбрать фото" : "Изменить фото")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.clear)
                
                Section(header: Text("Параметры напитка").foregroundColor(.blue)) {
                    TextField("Название", text: $viewModel.name)
                    
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
                }
                
                Section(header: Text("Описание напитка").foregroundColor(.blue)) {
                    TextField("Заметки, вкус, особенности подачи...", text: $viewModel.description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                if let error = viewModel.errorMessage {
                    Text(error).foregroundColor(.red)
                }
            }
            .navigationTitle("Добавить Напиток")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        viewModel.selectedUiImage = uiImage
                    }
                }
            }
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

@MainActor
class AddDrinkViewModel: ObservableObject {
    @Published var name = ""
    @Published var type = "Пиво"
    @Published var abv = ""
    @Published var description = ""
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var selectedUiImage: UIImage? = nil
    
    private let service = DrinkService()
    
    func createDrink(forBarId barId: Int) async -> Bool {
        self.isLoading = true
        self.errorMessage = nil
        
        let abvValue = Double(abv.replacingOccurrences(of: ",", with: ".")) ?? 0.0
        let imageData = selectedUiImage?.jpegData(compressionQuality: 0.7)
        
        let boundary = "Boundary-\(UUID().uuidString)"
        var requestBody = Data()
        
        func appendTextField(name: String, value: String) {
            requestBody.append("--\(boundary)\r\n".data(using: .utf8)!)
            requestBody.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            requestBody.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        appendTextField(name: "name", value: name.trimmingCharacters(in: .whitespacesAndNewlines))
        appendTextField(name: "type", value: type)
        appendTextField(name: "description", value: description.trimmingCharacters(in: .whitespacesAndNewlines))
        appendTextField(name: "volume", value: "0")
        appendTextField(name: "abv", value: String(abvValue))
        
        if let data = imageData {
            requestBody.append("--\(boundary)\r\n".data(using: .utf8)!)
            requestBody.append("Content-Disposition: form-data; name=\"file\"; filename=\"drink_photo.jpg\"\r\n".data(using: .utf8)!)
            requestBody.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            requestBody.append(data)
            requestBody.append("\r\n".data(using: .utf8)!)
        }
        
        requestBody.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        do {
            try await service.createNewDrink(barId: barId, body: requestBody, boundary: boundary)
            self.isLoading = false
            return true
        } catch {
            self.errorMessage = "Не удалось сохранить напиток"
            self.isLoading = false
            return false
        }
    }
}
