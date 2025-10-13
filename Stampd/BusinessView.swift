//
//  BusinessView.swift
//  Stampd
//
//  Created by Adishree Das on 10/13/25.
//

import SwiftUI
import FirebaseFirestore

struct BusinessView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showingScanView = false
    @State private var rewardsToday = 12//placeholder
    @State private var stampsToday = 45 //placeholder
    
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
                
                VStack(spacing: 20) {
                    // scan button
                    Button(action: {
                        showingScanView = true
                    }) {
                        HStack(spacing: 15) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 30))
                                .foregroundColor(Color.stampdTextPink)
                            
                            Text("SCAN")
                                .font(.custom("Jersey15-Regular", size: 32))
                                .foregroundColor(Color.stampdTextPink)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 25)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 25)
                    .padding(.top, 60)
                    
                    //quick stats
                    HStack(spacing: 15) {
                        VStack(spacing: 10) {
                            Text("\(rewardsToday)")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(Color.stampdTextPink)
                            
                            Text("rewards today")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        
                        VStack(spacing: 10) {
                            Text("\(stampsToday)")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(Color.stampdTextPink)
                            
                            Text("stamps today")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    }
                    .padding(.horizontal, 25)
                    
                    // loyalty Program description
                    Text("Stamp Programs")
                        .font(.custom("Jersey15-Regular", size: 36))
                        .foregroundColor(Color.stampdTextPink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 25)
                        .padding(.top, 10)
                    
                    HStack(alignment: .top, spacing: 15) {
                        VStack(spacing: 12) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 100)
                                .cornerRadius(8)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 30))
                                )
                            
                            Text("FREE COFFEE")
                                .font(.custom("Jersey15-Regular", size: 20))
                                .foregroundColor(.black)
                            
                            Text("10 stamps needed")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        
                        VStack(spacing: 15) {
                            Spacer()
                            Button(action: {
                                // edit button
                                print("Edit tapped")
                            }) {
                                Text("Edit")
                                    .font(.custom("Jersey15-Regular", size: 18))
                                    .foregroundColor(.white)
                                    .frame(width: 80)
                                    .padding(.vertical, 10)
                                    .background(Color.stampdButtonPink)
                                    .cornerRadius(10)
                                    .shadow(color: Color.stampdButtonShadow, radius: 5, x: 0, y: 2)
                            }
                            
                            // logo (maybe change this idk what to put here)
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 80, height: 80)
                                .cornerRadius(8)
                                .overlay(
                                    Image(systemName: "building.2.fill")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 30))
                                )
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 25)
                    .padding(.bottom, 30)
                }
            }
        }
        .sheet(isPresented: $showingScanView) {
            ScanView()
        }
    }
}

#Preview {
    BusinessView()
        .environmentObject(AuthManager())
}

