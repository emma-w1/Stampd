//
//  ClaimView.swift
//  Stampd
//
//  Created by Adishree Das on 10/11/25.
//

import SwiftUI
import FirebaseFirestore

struct ClaimView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var userPrograms: [ProgramWithBusiness] = []
    @State private var isLoadingPrograms = true
    
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
                            
                            
                        }
                    } else {
                        ProgressView("Loading your QR code...")
                            .padding()
                    }
                    
                    // loyalty programs
                    if !isLoadingPrograms && !userPrograms.isEmpty {
                        VStack(spacing: 20) {
                            Text("My Loyalty Programs")
                                .font(.custom("Jersey15-Regular", size: 32))
                                .foregroundColor(Color.stampdTextPink)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            LazyVStack(spacing: 15) {
                                ForEach(userPrograms) { programWithBusiness in
                                    LoyaltyProgramCard(programWithBusiness: programWithBusiness)
                                }
                            }
                        }
                    } else if isLoadingPrograms {
                        ProgressView("Loading your programs...")
                            .padding()
                    }
                    
                    Spacer()
                }
                .padding(25)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            loadUserPrograms()
        }
    }
    
    func loadUserPrograms() {
        guard let userId = authManager.currentUser?.uid else {
            isLoadingPrograms = false
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("programs").getDocuments { [self] snapshot, error in
            DispatchQueue.main.async {
                self.isLoadingPrograms = false
                
                guard let documents = snapshot?.documents else {
                    return
                }
                
                var programs: [ProgramWithBusiness] = []
                let group = DispatchGroup()
                
                for document in documents {
                    group.enter()
                    let businessId = document.documentID
                    
                    let programData = document.data()
                    let program = CustomerProgram(
                        id: document.documentID,
                        claimed: programData["claimed"] as? Bool ?? false,
                        currentStamps: programData["currentStamps"] as? Int ?? 0,
                        prizesClaimed: programData["prizesClaimed"] as? Int ?? 0
                    )
                    
                    db.collection("businesses").document(businessId).getDocument { businessDoc, businessError in
                        defer { group.leave() }
                        
                        guard let businessDoc = businessDoc,
                              let businessData = businessDoc.data() else {
                            return
                        }
                        
                        let business = Business(
                            id: businessId,
                            businessId: businessId,
                            businessName: businessData["businessName"] as? String ?? "Unknown Business",
                            location: businessData["location"] as? String ?? "",
                            category: businessData["category"] as? String ?? "",
                            logoUrl: businessData["logoUrl"] as? String ?? "",
                            description: businessData["description"] as? String ?? "",
                            email: businessData["email"] as? String ?? "",
                            phoneNumber: businessData["phoneNumber"] as? String,
                            hours: businessData["hours"] as? String ?? "",
                            prizeOffered: businessData["prizeOffered"] as? String ?? "",
                            stampsNeeded: businessData["stampsNeeded"] as? Int ?? 10,
                            minimumPurchase: businessData["minimumPurchase"] as? Double ?? 0.0,
                            accountType: businessData["accountType"] as? String ?? "Business",
                            createdAt: (businessData["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                            totalCustomers: businessData["totalCustomers"] as? Int ?? 0,
                            totalStampsGiven: businessData["totalStampsGiven"] as? Int ?? 0,
                            rewardsRedeemed: businessData["rewardsRedeemed"] as? Int ?? 0
                        )
                        
                        let programWithBusiness = ProgramWithBusiness(
                            id: businessId,
                            program: program,
                            business: business
                        )
                        
                        programs.append(programWithBusiness)
                    }
                }
                
                group.notify(queue: .main) {
                    self.userPrograms = programs.sorted { $0.business.businessName < $1.business.businessName }
                }
            }
        }
    }
}

#Preview {
    ClaimView()
        .environmentObject(AuthManager())
}
