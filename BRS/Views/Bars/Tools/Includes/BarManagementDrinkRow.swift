//
//  arManagementDrinkRow.swift
//  BRS
//
//  Created by Haris York on 20.09.2026.
//
import SwiftUI

struct BarManagementDrinkRow: View {
    let drink: Drink
    var onRefreshRequired: () -> Void
    
    var body: some View {
       NavigationLink(destination: DrinkManagementDetailView(drink: drink, onSaveSuccess: onRefreshRequired)) {
           HStack(alignment: .center) { // Центрируем элементы по вертикали внутри строки
               VStack(alignment: .leading, spacing: 4) {
                   // 1. Название напитка
                   Text(drink.name)
                       .font(.subheadline)
                       .bold()
                       .foregroundColor(.white)
                   
                   // 2. 🌟 ИСПРАВЛЕНО: Компактная строчка параметров в старом стиле
                   // Убрали тяжелый .body, .padding и объединили в красивую строку
                   Text("\(drink.formattedVolume) мл • \(drink.formattedAbv)%")
                       .font(.caption2)
                       .foregroundColor(.gray)
               }
               
               Spacer()
               
               // 3. Категория напитка (Тег справа)
               Text(drink.type)
                   .font(.caption2)
                   .bold()
                   .padding(.horizontal, 8)
                   .padding(.vertical, 4)
                   .background(Color.blue.opacity(0.15))
                   .foregroundColor(.blue)
                   .cornerRadius(6)
           }
           .padding()
           .background(Color.white.opacity(0.02))
           .cornerRadius(12)
       }
       .buttonStyle(PlainButtonStyle())
   }
}
