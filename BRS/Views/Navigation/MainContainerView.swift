//
//  MainContainerView.swift
//  BRS
//
//  Created by Haris York on 06.06.2026.
//

import SwiftUI

struct MainContainerView: View {
    @State private var isMenuOpen = false
    
    var body: some View {
        NavigationView {
            ZStack {
                //  Карта теперь является подложкой главного экрана
                MainMapView()
                    .disabled(isMenuOpen)
                
                SideMenuView(isOpen: $isMenuOpen)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        withAnimation { isMenuOpen.toggle() }
                    }) {
                        Image(systemName: isMenuOpen ? "xmark" : "line.3.horizontal")
                            .font(.title3)
                            // Делаем кнопку контрастной, чтобы её было видно поверх карты
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}
#Preview {
    MainContainerView()
}
