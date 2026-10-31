//
//  BarQRCodeView.swift
//  BRS
//
//  Created by Haris York on 17.09.2026.
//

import SwiftUI

struct BarQRCodeView: View {
    let barName: String
    let qrSecretHash: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var qrImage: UIImage? = nil
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                VStack(spacing: 8) {
                    Text(barName)
                        .font(.title).bold()
                        .multilineTextAlignment(.center)
                    
                    Text("Покажите этот код гостю для чекина")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                ZStack {
                    Color.white
                        .frame(width: 260, height: 260)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    
                    if let qrImage = qrImage {
                        Image(uiImage: qrImage)
                            .resizable()
                            .interpolation(.none)
                            .frame(width: 220, height: 220)
                    } else {
                        ProgressView()
                            .frame(width: 220, height: 220)
                    }
                }
                .padding(.vertical, 20)
                
                VStack(spacing: 6) {
                    Text("Отладочный хэш БРС:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(qrSecretHash)
                        .font(.system(size: 10, weight: .light, design: .monospaced))
                        .foregroundColor(.blue)
                        .lineLimit(1)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                        .onTapGesture {
                            UIPasteboard.general.string = qrSecretHash
                        }
                }
                
                Spacer()
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                DispatchQueue.global(qos: .userInitiated).async {
                    let generated = QRCodeGenerator.generate(from: qrSecretHash)
                    DispatchQueue.main.async {
                        self.qrImage = generated
                    }
                }
            }
        }
    }
}

#Preview {
    BarQRCodeView(
        barName: "IDOL, бар",
        qrSecretHash: "8f7e2a9b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f"
    )
    .preferredColorScheme(.dark)
}
