//
//  BarCheckInView.swift
//  BRS
//
//  Created by Haris York on 15.09.2026.
//

import SwiftUI
import AVFoundation

struct BarCheckInView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var qrInputText = "" // Для ручного ввода в симуляторе
    @State private var statusMessage: String? = nil
    @State private var isError = false
    @State private var isLoading = false
    
    let service = DrinkService()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 1. ЗОНА СКАНЕРА КАМЕРЫ (Для реального устройства)
                #if targetEnvironment(simulator)
                VStack(spacing: 12) {
                    Image(systemName: "camera.metering.unknown")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("Камера недоступна в симуляторе Xcode")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 250)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                .padding(.horizontal)
                #else
                // 🌟 ИСПРАВЛЕНО: Вместо заглушки вызываем наш живой слой камеры AVFoundation
                QRScannerCameraView { qrHash in
                    // Как только камера считала хэш с экрана менеджера — мгновенно запускаем чекин во Flask!
                    self.processCheckIn(hash: qrHash)
                }
                .frame(maxWidth: .infinity, minHeight: 250)
                .background(Color.black)
                .cornerRadius(16)
                .padding(.horizontal)
                #endif
                
                // 2. ОБХОДНОЙ ПУТЬ ДЛЯ СИМУЛЯТОРА (Наш отладочный чит-код)
                VStack(alignment: .leading, spacing: 8) {
                    Text("ОТЛАДКА: Ручной ввод хэша")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    
                    HStack {
                        TextField("Вставьте qr_secret_hash бара", text: $qrInputText)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        
                        Button("Чекин") {
                            processCheckIn(hash: qrInputText)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                        .disabled(qrInputText.isEmpty || isLoading)
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // 3. Вывод статуса ответа бэкенда
                if let msg = statusMessage {
                    Text(msg)
                        .font(.subheadline)
                        .foregroundColor(isError ? .red : .green)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                
                Spacer()
            }
            .navigationTitle("Чекин в заведении")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
            .overlay {
                if isLoading { ProgressView().scaleEffect(1.5) }
            }
        }
    }
    
    // Логика отправки данных во Flask
    private func processCheckIn(hash: String) {
        isLoading = true
        statusMessage = nil
        
        Task {
            do {
                let successMessage = try await service.checkInAtBar(qrHash: hash)
                isError = false
                statusMessage = successMessage
                
                // Плавно закрываем экран после успешного чекина через секунду
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    dismiss()
                }
            } catch {
                isError = true
                statusMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
