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
