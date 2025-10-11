//
//  ClaimView.swift
//  Stampd
//
//  Created by Adishree Das on 10/11/25.
//

import SwiftUI

struct ClaimView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        ZStack {
            TopNavbar(showSearchIcon: false)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Color.clear.frame(height: 50)
                    
                    // claim page
                    Text("Claim Rewards")
                        .font(.custom("Jersey15-Regular", size: 42))
                        .foregroundColor(Color.stampdTextPink)
                        .padding(.top, 10)
                    
                    Text("Coming soon!")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                    
                    Spacer()
                }
                .padding(25)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.stampdGradientTop, Color.stampdGradientBottom]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
        }
    }
}

#Preview {
    ClaimView()
        .environmentObject(AuthManager())
}
