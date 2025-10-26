//
//  BusinessMainContentView.swift
//  Stampd
//
//  Created by Adishree Das on 10/13/25.
//

import SwiftUI

struct BusinessMainContentView: View {
    @State private var selectedTab: Tab = .discover
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        VStack(spacing: 0) {
            switch selectedTab {
            case .discover:
                BusinessView()
            case .settings:
                SettingsView()
            case .claim:
                ClaimView()
            case .analytics:
                AnalyticsView()
            }
            
            BottomNavbar(selectedTab: $selectedTab)
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}

#Preview {
    BusinessMainContentView()
        .environmentObject(AuthManager())
}

