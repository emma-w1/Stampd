//
//  BusinessInfoView.swift
//  Stampd
//
//  Created by Adishree Das on 10/13/25.
//

import SwiftUI
import FirebaseFirestore

struct BusinessInfoView: View {
    let business: Business
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    @State private var isJoined = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.stampdGradientTop, Color.stampdGradientBottom]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // back button heading
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(Color.white)
                        .font(.system(size: 16))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 25)
                .padding(.vertical, 15)
                .background(Color.pink)
                
                ScrollView {
                    VStack {
                        //print all business info
                        VStack(spacing: 15) {
                            AsyncImage(url: URL(string: business.logoUrl)) { phase in
                                switch phase {
                                case .empty:
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 120, height: 120)
                                        .cornerRadius(20)
                                        .overlay(ProgressView())
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 120, height: 120)
                                        .cornerRadius(20)
                                        .clipped()
                                case .failure:
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 120, height: 120)
                                        .cornerRadius(20)
                                        .overlay(
                                            Image(systemName: "storefront")
                                                .foregroundColor(.gray)
                                                .font(.system(size: 40))
                                        )
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            
                            Text(business.businessName)
                                .font(.custom("Jersey15-Regular", size: 36))
                                .foregroundColor(Color.stampdTextPink)
                            
                            Text(business.category)
                                .font(.system(size: 16))
                                .foregroundColor(Color.white)
                                .padding(5)
                                .background(Color.pink)
                                .cornerRadius(12)

                        }
                        .padding(.top, 20)
                        
                        VStack (alignment: .leading) {
                                Text(business.description)
                                    .font(.system(size: 16, weight: .semibold))
                            HStack {
                                Image(systemName: "mappin")
                                    .foregroundColor(Color.stampdTextPink)
                                    .frame(width: 30)
                                Text(business.location)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(Color.stampdTextPink)
                                    .frame(width: 30)
                                Text(business.hours)
                                    .font(.system(size: 16, weight: .semibold))
                            }

                            if let phone = business.phoneNumber {
                                HStack {
                                    Image(systemName: "phone.fill")
                                        .foregroundColor(Color.stampdTextPink)
                                        .frame(width: 30)
                                    Text(phone)
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(Color.stampdTextPink)
                                    .frame(width: 30)
                                Text(business.email)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .padding(.horizontal, 25)
                        .padding(.bottom, 20)
                        
                        // stamp program section
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Stamp Program")
                                .font(.custom("Jersey15-Regular", size: 32))
                                .foregroundColor(Color.stampdTextPink)
                            
                            VStack(spacing: 15) {
//details
                                VStack(spacing: 12) {
                                    HStack {
                                        Image(systemName: "gift.fill")
                                            .foregroundColor(Color.stampdTextPink)
                                            .font(.system(size: 24))
                                        
                                        Text(business.prizeOffered)
                                            .font(.custom("Jersey15-Regular", size: 24))
                                            .foregroundColor(.black)
                                        
                                        Spacer()
                                    }
                                    
                                    Divider()
                                    
                                    HStack {
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text("Stamps Needed")
                                                .font(.system(size: 12))
                                                .foregroundColor(.gray)
                                            HStack(spacing: 5) {
                                                Image(systemName: "star.fill")
                                                    .foregroundColor(Color.stampdTextPink)
                                                    .font(.system(size: 16))
                                                Text("\(business.stampsNeeded)")
                                                    .font(.system(size: 20, weight: .bold))
                                                    .foregroundColor(.black)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text("Min. Purchase")
                                                .font(.system(size: 12))
                                                .foregroundColor(.gray)
                                            Text("$\(String(format: "%.2f", business.minimumPurchase))")
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(.black)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                                
                                // JOIN button
                                Button(action: {
                                    joinProgram()
                                }) {
                                    HStack {
                                        Image(systemName: isJoined ? "checkmark.circle.fill" : "plus.circle.fill")
                                        Text(isJoined ? "JOINED" : "JOIN PROGRAM")
                                            .font(.custom("Jersey15-Regular", size: 24))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(isJoined ? Color.green : Color.stampdButtonPink)
                                    .cornerRadius(12)
                                    .shadow(color: (isJoined ? Color.green : Color.stampdButtonShadow).opacity(0.4), radius: 8, x: 0, y: 4)
                                }
                                .disabled(isJoined)
                            }
                        }
                        .padding(.horizontal, 25)
                        .padding(.bottom, 30)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    func joinProgram() {
        guard let customerId = authManager.currentUser?.uid else {
            print("❌ No customer ID found")
            return
        }
        
        let db = Firestore.firestore()
        
        // adds to firebase
        let programData: [String: Any] = [
            "claimed": false,
            "currentStamps": 0,
            "prizesClaimed": 0
        ]
        
        db.collection("users").document(customerId).collection("programs")
            .document(business.businessId)
            .setData(programData) { error in
                if let error = error {
                    print("❌ Error joining program: \(error.localizedDescription)")
                    return
                }
                
                print("✅ Successfully joined program for \(business.businessName)")
                withAnimation {
                    isJoined = true
                }
            }
    }
}

#Preview {
    BusinessInfoView(business: Business(
        id: "1",
        businessId: "test",
        businessName: "Test Cafe",
        location: "123 Main St",
        category: "Coffee",
        logoUrl: "https://example.com/logo.png",
        description: "Great coffee shop",
        email: "test@cafe.com",
        phoneNumber: nil,
        hours: "Mon-Fri: 8AM-6PM",
        prizeOffered: "FREE COFFEE",
        stampsNeeded: 10,
        minimumPurchase: 5.00,
        accountType: "Business",
        createdAt: Date(),
        totalCustomers: 0,
        totalStampsGiven: 0,
        rewardsRedeemed: 0
    ))
    .environmentObject(AuthManager())
}
