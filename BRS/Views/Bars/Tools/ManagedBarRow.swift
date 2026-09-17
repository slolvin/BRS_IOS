//
//  ManagedBarRow.swift
//  BRS
//
//  Created by Haris York on 17.09.2026.
//

import SwiftUI

struct ManagedBarRow: View {
    let barName: String
    let address: String
    let rating: Double
    let qrHash: String
    
    // Состояние для открытия шторки с QR конкретно этого бара
    @State private var isShowingQR = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Левая часть: Название, адрес и звездный рейтинг бара БРС
            VStack(alignment: .leading, spacing: 6) {
                Text(barName)
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white) // Под темную тему сайдбара
                
                Text(address)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    Text(String(format: "%.1f", rating))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Правая часть: Заветная кнопка «Код» для менеджера
            Button(action: {
                isShowingQR = true
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "qrcode")
                        .font(.title2)
                    Text("Код")
                        .font(.system(size: 10, weight: .bold))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.15))
                .foregroundColor(.blue)
                .cornerRadius(10)
            }
        }
        .padding()
        // Используем глубокий темный цвет под стать вашему сайдбару
        .background(Color(red: 0.16, green: 0.16, blue: 0.20))
        .cornerRadius(14)
        // При тапе на кнопку "Код" плавно выкатывается созданная ранее шторка с генерацией QR-кода
        .sheet(isPresented: $isShowingQR) {
            BarQRCodeView(barName: barName, qrSecretHash: qrHash)
        }
    }
}

// MARK: - Превью для Xcode компилятора
#Preview {
    ZStack {
        Color(red: 0.12, green: 0.12, blue: 0.15).ignoresSafeArea()
        ManagedBarRow(
            barName: "IDOL, бар",
            address: "ул. Молодогвардейская, 204",
            rating: 4.8,
            qrHash: "test_secret_hash_brs"
        )
        .padding()
    }
}
