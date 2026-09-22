//
//  UserLogActionRow.swift
//  BRS
//
//  Created by Haris York on 23.09.2026.
//

import SwiftUI

struct UserLogActionRow: View {
    let log: UserLogAction
    let isLast: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(log.safeActionType.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.gray)
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Text(log.displayTimestamp)
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
                
                Text(log.safeDescription)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 4)
            
            if !isLast {
                Divider()
                    .background(Color.white.opacity(0.05))
            }
        }
    }
}
