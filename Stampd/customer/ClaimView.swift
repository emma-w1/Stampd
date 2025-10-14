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
            LinearGradient(
                gradient: Gradient(colors: [Color.stampdGradientTop, Color.stampdGradientBottom]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                TopNavbar(showSearchIcon: false)

                VStack(spacing: 25) {
                    
                    // qr code header/text
                    Text("My QR Code")
                        .font(.custom("Jersey15-Regular", size: 42))
                        .foregroundColor(Color.stampdTextPink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Show this QR code to businesses to collect stamps and claim rewards")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    //qr code card
                    if let user = authManager.currentUser {
                        VStack(spacing: 20) {
                            // QR Code
                            QRCodeView(data: user.uid, size: 250)
                                .padding(20)
                                .background(Color.white)
                                .cornerRadius(20)
                                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                            
                            // instructions
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(Color.stampdTextPink)
                                    Text("How it works")
                                        .font(.custom("Jersey15-Regular", size: 20))
                                        .foregroundColor(Color.stampdTextPink)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    NumberedStep(number: "1", text: "Make a purchase at a participating business")
                                    NumberedStep(number: "2", text: "Show your QR code to the cashier")
                                    NumberedStep(number: "3", text: "Collect stamps and claim free rewards!")
                                }
                                .padding(.leading, 5)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        }
                    } else {
                        ProgressView("Loading your QR code...")
                            .padding()
                    }
                    
                    Spacer()
                }
                .padding(25)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    ClaimView()
        .environmentObject(AuthManager())
}
