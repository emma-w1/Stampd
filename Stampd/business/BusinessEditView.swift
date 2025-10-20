//
//  BusinessEditView.swift
//  Stampd
//
//  Created by Adishree Das on 10/14/25.
//

import SwiftUI
import FirebaseFirestore

struct BusinessEditView: View {
    let business: Business
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    @State private var prizeOffered: String
    @State private var stampsNeeded: String
    @State private var minimumPurchase: String
    @State private var logoUrl: String
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var isUploadingImage = false
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    init(business: Business) {
        self.business = business
        _prizeOffered = State(initialValue: business.prizeOffered)
        _stampsNeeded = State(initialValue: String(business.stampsNeeded))
        _minimumPurchase = State(initialValue: String(format: "%.2f", business.minimumPurchase))
        _logoUrl = State(initialValue: business.logoUrl)
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.stampdGradientTop, Color.stampdGradientBottom]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // top bar
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                            Text("Cancel")
                        }
                        .foregroundColor(Color.stampdTextPink)
                        .font(.system(size: 16))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 25)
                .padding(.vertical, 15)
                
                ScrollView {
                    VStack(spacing: 15) {
                        Image("StampdLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100)
                            .padding(.top, 10)
                        
                        Text("Edit Stamp Program")
                            .font(.custom("Jersey15-Regular", size: 32))
                            .foregroundColor(Color.stampdTextPink)
                            .padding(.bottom, 10)
                        
                        Group {
                            Text("prize offered")
                                .font(.custom("Jersey15-Regular", size: 26))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundColor(Color.stampdTextPink)
                                .padding(.bottom, 5)
                            TextField("e.g. FREE COFFEE", text: $prizeOffered)
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.stampdTextPink, lineWidth: 2)
                                )
                                .padding(.bottom, 8)
                            
                            Text("stamps needed")
                                .font(.custom("Jersey15-Regular", size: 26))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundColor(Color.stampdTextPink)
                                .padding(.bottom, 5)
                            TextField("e.g. 10", text: $stampsNeeded)
                                .keyboardType(.numberPad)
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.stampdTextPink, lineWidth: 2)
                                )
                                .padding(.bottom, 8)
                            
                            Text("minimum purchase")
                                .font(.custom("Jersey15-Regular", size: 26))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundColor(Color.stampdTextPink)
                                .padding(.bottom, 5)
                            TextField("e.g. 5.00", text: $minimumPurchase)
                                .keyboardType(.decimalPad)
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.stampdTextPink, lineWidth: 2)
                                )
                                .padding(.bottom, 8)
                            
                            Text("business logo / product image")
                                .font(.custom("Jersey15-Regular", size: 26))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundColor(Color.stampdTextPink)
                                .padding(.bottom, 5)
                            
                            Button(action: {
                                showImagePicker = true
                            }) {
                                HStack {
                                    if isUploadingImage {
                                        ProgressView()
                                            .frame(width: 60, height: 60)
                                        Text("Uploading...")
                                            .foregroundColor(.gray)
                                    } else if let image = selectedImage {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 60, height: 60)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                        Text("Change Image")
                                            .foregroundColor(.primary)
                                    } else {
                                        AsyncImage(url: URL(string: business.logoUrl)) { phase in
                                            switch phase {
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 60, height: 60)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                            default:
                                                Image(systemName: "photo")
                                                    .foregroundColor(Color.stampdTextPink)
                                            }
                                        }
                                        Text("Change Image")
                                            .foregroundColor(.primary)
                                    }
                                    Spacer()
                                    if !isUploadingImage {
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(Color.stampdTextPink)
                                    }
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.stampdTextPink, lineWidth: 2)
                                )
                            }
                            .disabled(isUploadingImage)
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
                                await saveChanges()
                            }
                        }) {
                            Text("save changes")
                                .font(.custom("Jersey15-Regular", size: 25))
                                .foregroundColor(Color.stampdTextWhite)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(isLoading ? Color.stampdButtonPinkDisabled : Color.stampdButtonPink)
                                .cornerRadius(12)
                                .shadow(color: Color.stampdButtonShadow, radius: 8, x: 0, y: 4)
                        }
                        .padding(.top, 10)
                        .disabled(isLoading)
                        
                        Spacer().frame(height: 20)
                    }
                    .padding(.horizontal, 25)
                    .padding(.bottom, 20)
                }
            }
            
            if isLoading {
                ProgressView("Saving...")
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage, logoUrl: $logoUrl, isUploading: $isUploadingImage)
        }
    }
    
    func saveChanges() async {
        guard !prizeOffered.isEmpty, !stampsNeeded.isEmpty, !minimumPurchase.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        // Check if still uploading
        if isUploadingImage {
            errorMessage = "Please wait for image upload to complete"
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
        
        guard let uid = authManager.currentUser?.uid else {
            errorMessage = "User not found"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let db = Firestore.firestore()
        
        let updateData: [String: Any] = [
            "prizeOffered": prizeOffered,
            "stampsNeeded": stampsInt,
            "minimumPurchase": minPurchase,
            "logoUrl": logoUrl
        ]
        
        do {
            try await db.collection("businesses").document(uid).updateData(updateData)
            await MainActor.run {
                isLoading = false
                dismiss()
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to save changes."
                isLoading = false
            }
        }
    }
}

#Preview {
    BusinessEditView(business: Business(
        id: "1",
        businessId: "test",
        businessName: "Test Cafe",
        location: "123 Main St",
        category: "Coffee",
        logoUrl: "https://example.com/logo.png",
        description: "Great coffee",
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

