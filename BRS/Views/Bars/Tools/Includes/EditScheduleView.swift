//
//  EditScheduleView.swift
//  BRS
//
//  Created by Haris York on 23.09.2026.
//
import SwiftUI

struct EditScheduleView: View {
    @ObservedObject var viewModel: BarDetailViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var hours: OpeningHours
    
    init(viewModel: BarDetailViewModel) {
        self.viewModel = viewModel
        // 🌟 ИСПРАВЛЕНО: Берём расписание напрямую из полной карточки бара (BarDetail)
        _hours = State(initialValue: viewModel.bar?.openingHours ?? OpeningHours())
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Часы работы заведения").foregroundColor(.gray)) {
                    dayRow(day: "Понедельник", text: $hours.mon)
                    dayRow(day: "Вторник", text: $hours.tue)
                    dayRow(day: "Среда", text: $hours.wed)
                    dayRow(day: "Четверг", text: $hours.thu)
                    dayRow(day: "Пятница", text: $hours.fri)
                    dayRow(day: "Суббота", text: $hours.sat)
                    dayRow(day: "Воскресенье", text: $hours.sun)
                }
            }
            .navigationTitle("Настройка времени")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        // Локальная неизменяемая копия для безопасной передачи в поток
                        let updatedHours = hours
                        Task {
                            // 🌟 ИСПРАВЛЕНО: Вызываем метод сохранения у оригинального viewModel
                            await viewModel.saveOpeningHours(hours: updatedHours)
                            dismiss()
                        }
                    }
                    .foregroundColor(.orange)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
    
    private func dayRow(day: String, text: Binding<String>) -> some View {
        HStack {
            Text(day).foregroundColor(.white)
            Spacer()
            TextField("12:00-02:00", text: text)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .frame(width: 140)
        }
        .listRowBackground(Color.white.opacity(0.02))
    }
}
