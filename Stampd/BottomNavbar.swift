//
//  BottomNavbar.swift
//  Stampd
//
//  Created by Adishree Das on 10/13/25.
//

import SwiftUI

enum Tab {
    case discover
    case settings
    case claim
    case analytics
}

struct BottomNavbar: View {
    @Binding var selectedTab: Tab
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        HStack {
            Button(action: { selectedTab = .discover }) {
                VStack(spacing: 5) {
                    Image(systemName: selectedTab == .discover ? "house.fill" : "house")
                        .font(.system(size: 24))
                    Text("Discover")
                        .font(.system(size: 12))
                }
                .foregroundColor(selectedTab == .discover ? Color.lightPink : Color.white)
                .frame(maxWidth: .infinity)
            }
            
            // Show Claim for customers, Analytics for businesses
            if authManager.currentUser?.accountType == .customer {
                Button(action: { selectedTab = .claim }) {
                    VStack(spacing: 5) {
                        Image(systemName: selectedTab == .claim ? "star.circle.fill" : "star.circle")
                            .font(.system(size: 24))
                        Text("Claim")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(selectedTab == .claim ? Color.lightPink : Color.white)
                    .frame(maxWidth: .infinity)
                }
            } else {
                Button(action: { selectedTab = .analytics }) {
                    VStack(spacing: 5) {
                        Image(systemName: selectedTab == .analytics ? "chart.bar.fill" : "chart.bar")
                            .font(.system(size: 24))
                        Text("Analytics")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(selectedTab == .analytics ? Color.lightPink : Color.white)
                    .frame(maxWidth: .infinity)
                }
            }
            
            Button(action: { selectedTab = .settings }) {
                VStack(spacing: 5) {
                    Image(systemName: selectedTab == .settings ? "gearshape.fill" : "gearshape")
                        .font(.system(size: 24))
                    Text("Settings")
                        .font(.system(size: 12))
                }
                .foregroundColor(selectedTab == .settings ? Color.lightPink : Color.white)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
        .background(Color.stampdTextPink)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
    }
}

#Preview {
    BottomNavbar(selectedTab: .constant(.discover))
        .environmentObject(AuthManager())
}

