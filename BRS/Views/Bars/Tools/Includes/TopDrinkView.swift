//
//  TopDrinkView.swift
//  BRS
//
//  Created by Haris York on 20.09.2026.
//

import SwiftUI

struct TopDrinkView: View {
    let drinkName: String
    
    var body: some View {
        if drinkName != "Нет продаж" {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "wineglass.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 16, weight: .bold))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Самый популярный напиток")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Text(drinkName)
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.white.opacity(0.02))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.1), lineWidth: 1)
            )
            .transition(.opacity.combined(with: .scale))
        }
    }
}
