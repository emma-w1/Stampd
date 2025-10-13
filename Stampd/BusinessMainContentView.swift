//
//  BusinessMainContentView.swift
//  Stampd
//
//  Created by Adishree Das on 10/13/25.
//

import SwiftUI

//manages what business screens look like
struct BusinessMainContentView: View {
    @State private var selectedTab: Tab = .discover
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content based on selected tab
            ZStack {
                switch selectedTab {
                case .discover:
                    BusinessView()
                case .settings:
                    SettingsView()
                case .claim:
                    ClaimView()
                }
            }
            
            // navbar
            BottomNavbar(selectedTab: $selectedTab)
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}

#Preview {
    BusinessMainContentView()
        .environmentObject(AuthManager())
}

