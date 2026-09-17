//
//  AddDrinkFormView.swift
//  BRS
//
//  Created by Haris York on 18.09.2026.
//

import SwiftUI

struct AddDrinkFormView: View {
    let barId: Int
    var onSaveSuccess: () -> Void // 🌟 Добавляем этот параметр
    
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var drinkType = "Cocktail"
    @State private var volume = ""
    @State private var abv = ""
    @State private var description = ""
    @State private var isSaving = false
    
    let types = ["Cocktail", "Spirits", "Beer", "Wine", "Modifiers"]
    private let drinkService = DrinkService()
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Основная информация")) {
                    TextField("Название напитка", text: $name)
                    Picker("Тип напитка", selection: $drinkType) {
                        ForEach(types, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                }
                Section(header: Text("Характеристики")) {
                    TextField("Объем (мл)", text: $volume).keyboardType(.numberPad)
                    TextField("Крепость (%)", text: $abv).keyboardType(.decimalPad)
                }
                Section(header: Text("Описание напитка")) {
                    TextField("Заметки, вкус, особенности подачи...", text: $description, axis: .vertical)
                        .lineLimit(3...6) // Позволит полю красиво расширяться при вводе длинного текста
                }
            }
            .navigationTitle("Новый напиток")
            .navigationBarTitleDisplayMode(.inline)
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
        let body: [String: Any] = [
            "name": name.trimmingCharacters(in: .whitespacesAndNewlines),
            "type": drinkType,
            "description": description,
            "volume": Int(volume) ?? 0,
            "abv": Double(abv.replacingOccurrences(of: ",", with: ".")) ?? 0.0,
            "image_url": ""
        ]
        
        do {
            // Отправляем на новый роут Flask
            try await drinkService.postNewDrink(barId: barId, body: body)
            
            // 🌟 УСПЕХ: Вызываем обновление главного экрана и закрываемся!
            onSaveSuccess()
            dismiss()
        } catch {
            print("❌ Ошибка БРС: \(error.localizedDescription)")
        }
        isSaving = false
    }
}
