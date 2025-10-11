//
//  MainContentView.swift
//  Stampd
//
//  Created by Adishree Das on 10/11/25.
//

import SwiftUI

struct MainContentView: View {
    @State private var selectedTab: Tab = .discover
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content based on selected tab
            ZStack {
                switch selectedTab {
                case .discover:
                    DiscoverView()
                case .settings:
                    SettingsView()
                }
            }
            
            // Bottom Navbar
            BottomNavbar(selectedTab: $selectedTab)
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}

#Preview {
    MainContentView()
        .environmentObject(AuthManager())
}

