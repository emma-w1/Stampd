//
//  BottomNavbar.swift
//  Stampd
//
//  Created by Adishree Das on 10/11/25.
//

import SwiftUI

enum Tab {
    case discover
    case settings
}

struct BottomNavbar: View {
    @Binding var selectedTab: Tab
    
    var body: some View {
        HStack {
            // Discover Tab
            Button(action: {
                selectedTab = .discover
            }) {
                VStack(spacing: 5) {
                    Image(systemName: selectedTab == .discover ? "house.fill" : "house")
                        .font(.system(size: 24))
                    Text("Discover")
                        .font(.system(size: 12))
                }
                .foregroundColor(selectedTab == .discover ? Color.stampdTextPink : Color.gray)
                .frame(maxWidth: .infinity)
            }
            
            // Settings Tab
            Button(action: {
                selectedTab = .settings
            }) {
                VStack(spacing: 5) {
                    Image(systemName: selectedTab == .settings ? "gearshape.fill" : "gearshape")
                        .font(.system(size: 24))
                    Text("Settings")
                        .font(.system(size: 12))
                }
                .foregroundColor(selectedTab == .settings ? Color.stampdTextPink : Color.gray)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
    }
}

#Preview {
    BottomNavbar(selectedTab: .constant(.discover))
}

