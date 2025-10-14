//
//  SettingsView.swift
//  Stampd
//
//  Created by Adishree Das on 10/13/25.

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showLogoutAlert = false
    
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

                VStack(alignment: .leading, spacing: 20) {
                    
                    // header
                    Text("Settings")
                        .font(.custom("Jersey15-Regular", size: 42))
                        .foregroundColor(Color.stampdTextPink)
                        .padding(.top, 10)
                    
                    // user info
                    if let user = authManager.currentUser {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Account Info")
                                .font(.custom("Jersey15-Regular", size: 28))
                                .foregroundColor(Color.stampdTextPink)
                            
                            VStack(spacing: 12) {
                                SettingsRow(icon: "envelope.fill", title: "Email", value: user.email)
                                SettingsRow(icon: "person.fill", title: "Account Type", value: user.accountType.rawValue)
                                if let phone = user.phoneNumber {
                                    SettingsRow(icon: "phone.fill", title: "Phone", value: phone)
                                }
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        
                        // how to section (customers only)
                        if user.accountType == .customer {
                            VStack(alignment: .leading, spacing: 15) {
                                Text("How To")
                                    .font(.custom("Jersey15-Regular", size: 28))
                                    .foregroundColor(Color.stampdTextPink)
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    NumberedStep(number: "1", text: "Join loyalty programs through the Discover page")
                                    NumberedStep(number: "2", text: "Collect stamps by showing cashiers your QR code when checking out")
                                    NumberedStep(number: "3", text: "Redeem free prize when you collect enough stamps by scanning your QR code")
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        }
                    }
                    
                    // logout
                    Button(action: {
                        showLogoutAlert = true
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 20))
                            Text("Log Out")
                                .font(.custom("Jersey15-Regular", size: 24))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 55)
                        .background(Color.stampdButtonPink)
                        .cornerRadius(12)
                        .shadow(color: Color.stampdButtonShadow, radius: 8, x: 0, y: 4)
                    }
                    .padding(.top, 20)
                    
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
        .alert("Log Out", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) {
                authManager.signOut()
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
    }
}

// Settings info row
struct SettingsRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color.stampdTextPink)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                Text(value)
                    .font(.system(size: 16))
                    .foregroundColor(.black)
            }
            
            Spacer()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthManager())
}

