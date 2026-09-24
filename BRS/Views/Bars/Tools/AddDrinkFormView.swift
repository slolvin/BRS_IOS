//
//  AddDrinkFormView.swift
//  BRS
//
//  Created by Haris York on 18.09.2026.
//

import Combine
import SwiftUI
import PhotosUI // 🌟 Для работы с галереей iOS 16+

struct AddDrinkFormView: View {
    let barId: Int
    var onSaveSuccess: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    // Поля ввода
    @State private var name = ""
    @State private var drinkType = "Cocktail"
    @State private var volume = ""
    @State private var abv = ""
    @State private var description = ""
    @State private var isSaving = false
    
    // Стейты для загрузки фото
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedUiImage: UIImage? = nil
    
    // Списки типов для пикера (Xcode автоматически занесет их в String Catalog)
    let types = ["Cocktail", "Spirits", "Beer", "Wine", "Modifiers"]
    private let drinkService = DrinkService()
    
    var body: some View {
        NavigationStack {
            Form {
                // СЕКЦИЯ 1: ЗАГРУЗКА И ПРЕВЬЮ ФОТО
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
                .listRowBackground(Color.clear) // Убираем белый фон формы для блока фотографии
                
                // СЕКЦИЯ 2: ОСНОВНАЯ ИНФОРМАЦИЯ
                Section(header: Text("Основная информация")) {
                    TextField("Название напитка", text: $name)
                    Picker("Тип напитка", selection: $drinkType) {
                        ForEach(types, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                }
                
                // СЕКЦИЯ 3: ХАРАКТЕРИСТИКИ
                Section(header: Text("Характеристики")) {
                    TextField("Объем (мл)", text: $volume)
                        .keyboardType(.numberPad)
                    TextField("Крепость (%)", text: $abv)
                        .keyboardType(.decimalPad)
                }
                
                // СЕКЦИЯ 4: ОПИСАНИЕ
                Section(header: Text("Описание напитка")) {
                    TextField("Заметки, вкус, особенности подачи...", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Новый напиток")
            .navigationBarTitleDisplayMode(.inline)
            // Конвертируем выбранный PhotosPickerItem в UIImage
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
        
        // Генерируем уникальную границу (boundary) для Multipart
        let boundary = "Boundary-\(UUID().uuidString)"
        var requestBody = Data()
        
        // Функция-помощник для упаковки полей формы
        func appendField(name: String, value: String) {
            requestBody.append("--\(boundary)\r\n".data(using: .utf8)!)
            requestBody.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            requestBody.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        // Собираем текстовые поля для Flask ручки add_drink_to_bar
        appendField(name: "name", value: name.trimmingCharacters(in: .whitespacesAndNewlines))
        appendField(name: "type", value: drinkType)
        appendField(name: "description", value: description)
        appendField(name: "volume", value: String(volumeValue))
        appendField(name: "abv", value: String(abvValue))
        
        // Добавляем файл, если менеджер выбрал картинку
        if let data = imageData {
            requestBody.append("--\(boundary)\r\n".data(using: .utf8)!)
            requestBody.append("Content-Disposition: form-data; name=\"file\"; filename=\"drink_photo.jpg\"\r\n".data(using: .utf8)!)
            requestBody.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            requestBody.append(data)
            requestBody.append("\r\n".data(using: .utf8)!)
        }
        
        // Закрываем Multipart
        requestBody.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        do {
            // Отправляем данные на нашу универсальную ручку через проверенный метод
            try await drinkService.createNewDrink(barId: barId, body: requestBody, boundary: boundary)
            
            // 🌟 УСПЕХ: Вызываем замыкание обновления и закрываем шторку
            onSaveSuccess()
            dismiss()
        } catch {
            print("❌ Ошибка БРС: \(error.localizedDescription)")
        }
        isSaving = false
    }
}
