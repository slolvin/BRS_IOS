//
//   DrinkRowView.swift
//  BRS
//
//  Created by Haris York on 06.06.2026.
//

import SwiftUI

struct DrinkRowView: View {
    let drink: Drink
    
    var body: some View {
        HStack(spacing: 16) {
            if let urlString = drink.imageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable()
                             .aspectRatio(contentMode: .fill)
                    case .failure, .empty:
                        placeholderIcon
                    @unknown default:
                        placeholderIcon
                    }
                }
                .frame(width: 70, height: 70)
                .cornerRadius(12)
                .clipped()
            } else {
                placeholderIcon
                    .frame(width: 70, height: 70)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(drink.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Text(drink.type ?? "Cocktail")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.15))
                        .foregroundColor(.blue)
                        .cornerRadius(20)
                }
                
                Text(drink.description ?? "Состав держится в секрете...")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    var placeholderIcon: some View {
        ZStack {
            Color.white.opacity(0.05)
            Image(systemName: "wineglass.fill")
                .foregroundColor(.gray)
        }
        .cornerRadius(12)
    }
}
