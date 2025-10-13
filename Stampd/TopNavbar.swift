//
//  TopNavbar.swift
//  Stampd
//
//  Created by Adishree Das on 10/11/25.
//

import SwiftUI

struct TopNavbar: View {
    @EnvironmentObject var authManager: AuthManager
    var showSearchIcon: Bool = true
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image("StampdLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 35)
                
                Spacer()
                
                // search for customer
                if showSearchIcon && authManager.currentUser?.accountType == .customer {
                    Button(action: {
                        print("Search tapped")
                    }) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 22))
                            .foregroundColor(Color.stampdTextPink)
                    }
                }
            }
            .padding(.horizontal, 25)
            .padding(.vertical, 12)
//            .background(Color.white.opacity(0.95))
            
            Spacer()
        }
    }
}

#Preview {
    TopNavbar()
        .environmentObject(AuthManager())
}
