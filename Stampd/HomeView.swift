//
//  HomeView.swift
//  Stampd
//
//  Created by Adishree Das on 9/27/25.
//
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseCore

struct HomeView: View {
    let profile: UserProfile
    let signOutAction: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Header Section
                    VStack(spacing: 15) {
                        Image(systemName: "checkmark.seal.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(Color.stampdPink)
                        
                        Text("Welcome back!")
                            .font(.custom("Jersey15-Regular", size: 34))
                            .bold()
                            .foregroundColor(Color.stampdTextPrimary)
                        
                        Text(profile.email)
                            .font(.custom("Jersey15-Regular", size: 20))
                            .foregroundColor(Color.stampdTextSecondary)
                    }
                    .padding(.top, 20)
                    
                    // Account Info Card
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Account Information")
                            .font(.custom("Jersey15-Regular", size: 17))
                            .bold()
                            .foregroundColor(Color.stampdTextPink)
                        
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(Color.stampdActionBlue)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Account Type")
                                    .font(.custom("Jersey15-Regular", size: 12))
                                    .foregroundColor(Color.stampdTextSecondary)
                                Text(profile.accountType.rawValue)
                                    .font(.custom("Jersey15-Regular", size: 20))
                                    .bold()
                                    .foregroundColor(Color.stampdTextPink)
                            }
                            Spacer()
                        }
                        
                        HStack {
                            Image(systemName: "calendar.circle.fill")
                                .foregroundColor(Color.stampdActionGreen)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Member Since")
                                    .font(.custom("Jersey15-Regular", size: 12))
                                    .foregroundColor(Color.stampdTextSecondary)
                                Text(profile.createdAt, style: .date)
                                    .font(.custom("Jersey15-Regular", size: 15))
                                    .bold()
                            }
                            Spacer()
                        }
                        
                        Divider()
                        
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color.stampdActionGreen)
                            Text("Profile verified with Firebase")
                                .font(.custom("Jersey15-Regular", size: 15))
                                .foregroundColor(Color.stampdTextSecondary)
                            Spacer()
                        }
                    }
                    .padding(20)
                    .background(Color.stampdCardBackground)
                    .cornerRadius(15)
                    .shadow(color: Color.stampdCardShadow, radius: 5, x: 0, y: 2)
                    
                    // Quick Actions
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Quick Actions")
                            .font(.custom("Jersey15-Regular", size: 17))
                            .bold()
                            .foregroundColor(Color.stampdTextPink)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 15) {
                            QuickActionButton(
                                icon: "gearshape.fill",
                                title: "Settings",
                                color: Color.stampdActionBlue
                            ) {
                                // Placeholder action
                            }
                            
                            QuickActionButton(
                                icon: "bell.fill",
                                title: "Notifications",
                                color: Color.stampdActionOrange
                            ) {
                                // Placeholder action
                            }
                            
                            QuickActionButton(
                                icon: "heart.fill",
                                title: "Favorites",
                                color: Color.stampdActionRed
                            ) {
                                // Placeholder action
                            }
                            
                            QuickActionButton(
                                icon: "questionmark.circle.fill",
                                title: "Help",
                                color: Color.stampdActionPurple
                            ) {
                                // Placeholder action
                            }
                        }
                    }
                    .padding(.horizontal, 5)
                    
                    Spacer(minLength: 50)
                    
                    // Sign Out Button
                    Button("Sign Out") {
                        signOutAction()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.red)
                    .cornerRadius(12)
                    .shadow(color: Color.red.opacity(0.3), radius: 5, x: 0, y: 3)
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.custom("Jersey15-Regular", size: 12))
                    .bold()
                    .foregroundColor(.stampdTextPrimary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.stampdCardShadow, radius: 3, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
//
//#Preview {
//    HomeView(profile: StampdApp.user, signOutAction: StampdApp.AuthManager.signOut)
//}
