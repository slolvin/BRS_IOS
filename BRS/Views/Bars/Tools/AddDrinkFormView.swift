//
//  AddDrinkFormView.swift
//  BRS
//
//  Created by Haris York on 18.09.2026.
//

import Combine
import SwiftUI
import PhotosUI

struct AddDrinkFormView: View {
    let barId: Int
    var onSaveSuccess: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var drinkType = "Cocktail"
    @State private var volume = ""
    @State private var abv = ""
    @State private var description = ""
    @State private var isSaving = false
    
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedUiImage: UIImage? = nil
    
    let types = ["Cocktail", "Spirits", "Beer", "Wine", "Modifiers"]
    private let drinkService = DrinkService()
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Фотография напитка")) {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            if let selectedImage = selectedUiImage {
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
                                Text(selectedUiImage == nil ? "Выбрать фото" : "Изменить фото")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.clear)
                
                Section(header: Text("Основная информация")) {
                    TextField("Название напитка", text: $name)
                    Picker("Тип напитка", selection: $drinkType) {
                        ForEach(types, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                }
                
                Section(header: Text("Характеристики")) {
                    TextField("Объем (мл)", text: $volume)
                        .keyboardType(.numberPad)
                    TextField("Крепость (%)", text: $abv)
                        .keyboardType(.decimalPad)
                }
                
                Section(header: Text("Описание напитка")) {
                    TextField("Заметки, вкус, особенности подачи...", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Новый напиток")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        selectedUiImage = uiImage
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Создать") { Task { await saveDrink() } }
                    .bold()
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
            }
        }
    }
    
    private func saveDrink() async {
        isSaving = true
        
        let abvValue = Double(abv.replacingOccurrences(of: ",", with: ".")) ?? 0.0
        let volumeValue = Int(volume) ?? 0
        let imageData = selectedUiImage?.jpegData(compressionQuality: 0.7)
        
        let boundary = "Boundary-\(UUID().uuidString)"
        var requestBody = Data()
        
        func appendField(name: String, value: String) {
            requestBody.append("--\(boundary)\r\n".data(using: .utf8)!)
            requestBody.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            requestBody.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        appendField(name: "name", value: name.trimmingCharacters(in: .whitespacesAndNewlines))
        appendField(name: "type", value: drinkType)
        appendField(name: "description", value: description)
        appendField(name: "volume", value: String(volumeValue))
        appendField(name: "abv", value: String(abvValue))
        
        if let data = imageData {
            requestBody.append("--\(boundary)\r\n".data(using: .utf8)!)
            requestBody.append("Content-Disposition: form-data; name=\"file\"; filename=\"drink_photo.jpg\"\r\n".data(using: .utf8)!)
            requestBody.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            requestBody.append(data)
            requestBody.append("\r\n".data(using: .utf8)!)
        }
        
        requestBody.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        do {
            try await drinkService.createNewDrink(barId: barId, body: requestBody, boundary: boundary)
            
            onSaveSuccess()
            dismiss()
        } catch {
            print("❌ Ошибка БРС: \(error.localizedDescription)")
        }
        isSaving = false
    }
}
