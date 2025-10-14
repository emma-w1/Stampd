//
//  BusinessView.swift
//  Stampd
//
//  Created by Adishree Das on 10/13/25.
//

import SwiftUI
import FirebaseFirestore


//business
struct BusinessView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showingScanView = false
    @State private var showingEditView = false
    @State private var rewardsToday = 12
    @State private var stampsToday = 45
    @State private var businessData: Business?
    @State private var isLoadingBusiness = true
    
    private var db = Firestore.firestore()
    
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
                    .padding(.top, 30)
                    
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
                    
                    if isLoadingBusiness {
                        ProgressView()
                            .padding(.vertical, 50)
                    } else if let business = businessData {
                            VStack(spacing: 12) {
                                AsyncImage(url: URL(string: business.logoUrl)) { phase in
                                    switch phase {
                                    case .empty:
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(height: 100)
                                            .cornerRadius(8)
                                            .overlay(ProgressView())
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(height: 100)
                                            .clipped()
                                            .cornerRadius(8)
                                    case .failure:
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(height: 100)
                                            .cornerRadius(8)
                                            .overlay(
                                                Image(systemName: "photo")
                                                    .foregroundColor(.gray)
                                                    .font(.system(size: 30))
                                            )
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                                
                                Text(business.prizeOffered)
                                    .font(.custom("Jersey15-Regular", size: 20))
                                    .foregroundColor(.black)
                                
                                Text("\(business.stampsNeeded) stamps needed")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                
                                Text("Min: $\(String(format: "%.2f", business.minimumPurchase))")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                            .padding(.horizontal, 25)
                        
                            Button(action: {
                                showingEditView = true
                            }) {
                                Text("Edit")
                                    .font(.custom("Jersey15-Regular", size: 18))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(Color.stampdButtonPink)
                                    .cornerRadius(12)
                                    .padding(.horizontal, 25)
                                    .shadow(color: Color.stampdButtonShadow, radius: 5, x: 0, y: 2)
                            }
                            

                    } else {
                        Text("Unable to load business info")
                            .foregroundColor(.gray)
                            .padding()
                    }
                }
            }
        }
        .sheet(isPresented: $showingScanView) {
            ScanView()
        }
        .sheet(isPresented: $showingEditView) {
            if let business = businessData {
                BusinessEditView(business: business)
            }
        }
        .onChange(of: showingEditView) { oldValue, newValue in
            // Refresh data when edit sheet is dismissed
            if oldValue == true && newValue == false {
                fetchBusinessData()
            }
        }
        .onAppear {
            fetchBusinessData()
        }
    }
    
    func fetchBusinessData() {
        guard let uid = authManager.currentUser?.uid else {
            isLoadingBusiness = false
            return
        }
        
        db.collection("businesses").document(uid).getDocument { (document, error) in
            guard let document = document,
                  document.exists,
                  var business = try? document.data(as: Business.self) else {
                self.isLoadingBusiness = false
                return
            }
            
            business.id = document.documentID
            self.businessData = business
            self.isLoadingBusiness = false
        }
    }
}

#Preview {
    BusinessView()
        .environmentObject(AuthManager())
}

