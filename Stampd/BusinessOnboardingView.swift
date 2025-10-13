//
//  BusinessOnboardingView.swift
//  Stampd
//
//  Created by Adishree Das on 10/13/25.
//

import SwiftUI
import FirebaseFirestore

struct BusinessOnboardingView: View {
    @EnvironmentObject var authManager: AuthManager
    
    @State private var businessName = ""
    @State private var category = ""
    @State private var location = ""
    @State private var phoneNumber = ""
    @State private var description = ""
    @State private var hours = ""
    @State private var prizeOffered = ""
    @State private var stampsNeeded = ""
    @State private var minimumPurchase = ""
    @State private var logoUrl = ""
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.stampdGradientTop, Color.stampdGradientBottom]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    Spacer().frame(height: 20)
                    
                    Image("StampdLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120)
                    
                    Text("Set Up Your Business")
                        .font(.custom("Jersey15-Regular", size: 36))
                        .foregroundColor(Color.stampdTextPink)
                        .padding(.bottom, 10)
                    
                    // Business Info Section
                    Group {
                        Text("business name")
                            .font(.custom("Jersey15-Regular", size: 28))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(Color.stampdTextPink)
                        TextField("Business Name", text: $businessName)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.stampdTextPink, lineWidth: 2)
                            )
                        
                        Text("category")
                            .font(.custom("Jersey15-Regular", size: 28))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(Color.stampdTextPink)
                        TextField("e.g. Coffee Shop, Restaurant", text: $category)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.stampdTextPink, lineWidth: 2)
                            )
                        
                        Text("location")
                            .font(.custom("Jersey15-Regular", size: 28))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(Color.stampdTextPink)
                        TextField("Full Address", text: $location)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.stampdTextPink, lineWidth: 2)
                            )
                        
                        Text("phone number")
                            .font(.custom("Jersey15-Regular", size: 28))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(Color.stampdTextPink)
                        TextField("+1-555-0100", text: $phoneNumber)
                            .keyboardType(.phonePad)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.stampdTextPink, lineWidth: 2)
                            )
                        
                        Text("description")
                            .font(.custom("Jersey15-Regular", size: 28))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(Color.stampdTextPink)
                        TextField("Brief description of your business", text: $description)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.stampdTextPink, lineWidth: 2)
                            )
                        
                        Text("hours")
                            .font(.custom("Jersey15-Regular", size: 28))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(Color.stampdTextPink)
                        TextField("e.g. Mon-Fri: 8AM-6PM", text: $hours)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.stampdTextPink, lineWidth: 2)
                            )
                    }
                    
                    // Stamp Program Section
                    Text("stamp program")
                        .font(.custom("Jersey15-Regular", size: 32))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(Color.stampdTextPink)
                        .padding(.top, 10)
                    
                    Group {
                        Text("prize offered")
                            .font(.custom("Jersey15-Regular", size: 28))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(Color.stampdTextPink)
                        TextField("e.g. FREE COFFEE", text: $prizeOffered)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.stampdTextPink, lineWidth: 2)
                            )
                        
                        Text("stamps needed")
                            .font(.custom("Jersey15-Regular", size: 28))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(Color.stampdTextPink)
                        TextField("e.g. 10", text: $stampsNeeded)
                            .keyboardType(.numberPad)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.stampdTextPink, lineWidth: 2)
                            )
                        
                        Text("minimum purchase")
                            .font(.custom("Jersey15-Regular", size: 28))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(Color.stampdTextPink)
                        TextField("e.g. 5.00", text: $minimumPurchase)
                            .keyboardType(.decimalPad)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.stampdTextPink, lineWidth: 2)
                            )
                        
                        Text("logo url")
                            .font(.custom("Jersey15-Regular", size: 28))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(Color.stampdTextPink)
                        TextField("https://example.com/logo.png", text: $logoUrl)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.stampdTextPink, lineWidth: 2)
                            )
                    }
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.callout)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 5)
                    }
                    
                    Button(action: {
                        Task {
                            await saveBusinessInfo()
                        }
                    }) {
                        Text("complete setup")
                            .font(.custom("Jersey15-Regular", size: 28))
                            .foregroundColor(Color.stampdTextWhite)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(isLoading ? Color.stampdButtonPinkDisabled : Color.stampdButtonPink)
                            .cornerRadius(12)
                            .shadow(color: Color.stampdButtonShadow, radius: 8, x: 0, y: 4)
                    }
                    .padding(.top, 10)
                    .disabled(isLoading)
                    
                    Spacer().frame(height: 30)
                }
                .padding(25)
            }
            
            if isLoading {
                ProgressView("Saving...")
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
            }
        }
    }
    
    func saveBusinessInfo() async {
        // Validate required fields
        guard !businessName.isEmpty, !category.isEmpty, !location.isEmpty,
              !phoneNumber.isEmpty, !description.isEmpty, !hours.isEmpty,
              !prizeOffered.isEmpty, !stampsNeeded.isEmpty, !minimumPurchase.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        guard let stampsInt = Int(stampsNeeded), stampsInt > 0 else {
            errorMessage = "Stamps needed must be a valid number"
            return
        }
        
        guard let minPurchase = Double(minimumPurchase), minPurchase >= 0 else {
            errorMessage = "Minimum purchase must be a valid amount"
            return
        }
        
        guard let uid = authManager.currentUser?.uid,
              let email = authManager.currentUser?.email else {
            errorMessage = "User not found"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let db = Firestore.firestore()
        
        // Create business document with uid as businessId
        let businessData: [String: Any] = [
            "businessId": uid,
            "businessName": businessName,
            "category": category,
            "location": location,
            "email": email,
            "phoneNumber": phoneNumber,
            "description": description,
            "hours": hours,
            "prizeOffered": prizeOffered,
            "stampsNeeded": stampsInt,
            "minimumPurchase": minPurchase,
            "logoUrl": logoUrl.isEmpty ? "https://via.placeholder.com/150" : logoUrl,
            "accountType": "Business",
            "createdAt": Timestamp(date: Date()),
            "totalCustomers": 0,
            "totalStampsGiven": 0,
            "rewardsRedeemed": 0
        ]
        
        do {
            try await db.collection("businesses").document(uid).setData(businessData)
            print("✅ Business profile created successfully")
            isLoading = false
            // The app will automatically refresh and show BusinessView
        } catch {
            print("❌ Error saving business: \(error.localizedDescription)")
            errorMessage = "Failed to save business info. Please try again."
            isLoading = false
        }
    }
}

#Preview {
    BusinessOnboardingView()
        .environmentObject(AuthManager())
}

