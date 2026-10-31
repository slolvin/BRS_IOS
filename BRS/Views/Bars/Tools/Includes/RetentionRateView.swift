//
//  RetentionRateView.swift
//  BRS
//
//  Created by Haris York on 23.09.2026.
//
import SwiftUI

struct RetentionRateView: View {
    let rate: Double

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Вернулись в течение недели")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                Text(String(format: "%.1f%% гостей", rate))
                    .font(.title3)
                    .bold()
                    .foregroundColor(.white)
            }
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.05), lineWidth: 4)
                    .frame(width: 36, height: 36)
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(rate / 100.0, 1.0)))
                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 36, height: 36)
                    .rotationEffect(Angle(degrees: -90))
            }
        }
        .padding()
        .background(Color.white.opacity(0.02))
        .cornerRadius(12)
    }
}
