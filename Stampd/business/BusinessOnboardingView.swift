//
//  BusinessOnboardingView.swift
//  Stampd
//
//  Created by Adishree Das on 10/13/25.
//

import SwiftUI
import FirebaseFirestore

//make stamp values only integers
extension Binding where Value == Int {
    var doubleValue: Binding<Double> {
        return Binding<Double>(
            get: { Double(self.wrappedValue) },
            set: { self.wrappedValue = Int(round($0)) }
        )
    }
}

struct BusinessOnboardingView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showLogoutAlert = false
    @State private var currentPage = 1
    @State private var businessName = ""
    @State private var category: BusinessCategory = .foodDrink
    @State private var location = ""
    @State private var description = ""
    @State private var hours = ""
    @State private var prizeOffered = ""
    @State private var stampsNeeded: Int = 1
    @State private var minimumPurchase = ""
    @State private var logoUrl = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var isUploadingImage = false
    
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
            
            VStack(spacing: 0) {
                // top bar with back button
                HStack {
                    Button(action: {
                        showLogoutAlert = true
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                            Text("Back")
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
                        
                        //switch between pages
                        if currentPage == 1 {
                        businessInfoPage
                    } else {
                        stampProgramPage
                    }
                    
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
        .alert("Go Back to Login?", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) {
                authManager.signOut()
            }
        } message: {
            Text("Your progress will be lost.")
        }
    }
    
    
    //page 1
    var businessInfoPage: some View {
        Group {
            Group {
                        Text("business name")
                            .font(.custom("Jersey15-Regular", size: 26))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(Color.stampdTextPink)
                            .padding(.bottom, 5)
                        TextField("Business Name", text: $businessName)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.stampdTextPink, lineWidth: 2)
                            )
                            .padding(.bottom, 8)
                        
                        Text("category")
                            .font(.custom("Jersey15-Regular", size: 26))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(Color.stampdTextPink)
                            .padding(.bottom, 5)
                
                    //dropdown picker
                        Menu {
                            ForEach(BusinessCategory.allCases, id: \.self) { cat in
                                Button(action: {
                                    category = cat
                                }) {
                                    Text(cat.rawValue)
                                }
                            }
                        } label: {
                            HStack {
                                Text(category.rawValue)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(Color.stampdTextPink)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.stampdTextPink, lineWidth: 2)
                            )
                        }
                        .padding(.bottom, 8)
                        
                        Text("location")
                            .font(.custom("Jersey15-Regular", size: 26))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(Color.stampdTextPink)
                            .padding(.bottom, 5)
                        TextField("Full Address", text: $location)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.stampdTextPink, lineWidth: 2)
                            )
                            .padding(.bottom, 8)
                          
                          Text("description")
                              .font(.custom("Jersey15-Regular", size: 26))
                              .frame(maxWidth: .infinity, alignment: .leading)
                              .foregroundColor(Color.stampdTextPink)
                              .padding(.bottom, 5)
                        TextField("Brief description of business", text: $description)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.stampdTextPink, lineWidth: 2)
                            )
                            .padding(.bottom, 8)
                        
                        Text("hours")
                            .font(.custom("Jersey15-Regular", size: 26))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(Color.stampdTextPink)
                            .padding(.bottom, 5)
                        TextField("ex: Mon-Fri: 8AM-6PM", text: $hours)
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
                    //next button
                    Button(action: {
                        validateAndGoToPage2()
                    }) {
                        Text("next")
                            .font(.custom("Jersey15-Regular", size: 28))
                            .foregroundColor(Color.stampdTextWhite)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.stampdButtonPink)
                            .cornerRadius(12)
                            .shadow(color: Color.stampdButtonShadow, radius: 8, x: 0, y: 4)
                    }
                    .padding(.top, 10)
                }
            }
    
    
    //page 2
    var stampProgramPage: some View {
        Group {
                Text("prize offered")
                    .font(.custom("Jersey15-Regular", size: 26))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(Color.stampdTextPink)
                    .padding(.bottom, 5)
                TextField("ex: Free Coffee", text: $prizeOffered)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.stampdTextPink, lineWidth: 2)
                    )
                    .padding(.bottom, 8)
                    
                Text("stamps needed (\(stampsNeeded))")
                    .font(.custom("Jersey15-Regular", size: 26))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(Color.stampdTextPink)
                    .padding(.bottom, 5)
                VStack(spacing: 8) {
                    Slider(
                        value: $stampsNeeded.doubleValue,
                        in: 1...15,
                        step: 1
                    ) {
                        Text("Stamps Needed")
                    } minimumValueLabel: {
                        Text("1").foregroundStyle(Color.stampdTextPink).font(.caption)
                    } maximumValueLabel: {
                        Text("15").foregroundColor(Color.stampdTextPink).font(.caption)
                    }
                    .tint(Color.stampdButtonPink)
                    
                    HStack {
                        Text("Selected: **\(stampsNeeded)** stamps ")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
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
                TextField("ex: $5.00", text: $minimumPurchase)
                    .keyboardType(.decimalPad)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.stampdTextPink, lineWidth: 2)
                    )
                    .padding(.bottom, 8)
                    
                Text("business logo")
                    .font(.custom("Jersey15-Regular", size: 26))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(Color.stampdTextPink)
                    .padding(.bottom, 5)
                    
            //image picker
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
                            Image(systemName: "photo")
                                .foregroundColor(Color.stampdTextPink)
                            Text("Select from Photos")
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
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.callout)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 5)
                    }
                    
                    HStack(spacing: 15) {
                        Button(action: {
                            withAnimation {
                                currentPage = 1
                            }
                        }) {
                            Text("back")
                                .font(.custom("Jersey15-Regular", size: 28))
                                .foregroundColor(Color.stampdTextPink)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.stampdTextPink, lineWidth: 2)
                                )
                        }
                        
                        //finish button
                        Button(action: {
                            Task {
                                await saveBusinessInfo()
                            }
                        }) {
                            Text("complete setup")
                                .font(.custom("Jersey15-Regular", size: 25))
                                .foregroundColor(Color.stampdTextWhite)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(isLoading ? Color.stampdButtonPinkDisabled : Color.stampdButtonPink)
                                .cornerRadius(12)
                                .shadow(color: Color.stampdButtonShadow, radius: 8, x: 0, y: 4)
                        }
                        .disabled(isLoading)
                    }
                    .padding(.top, 10)
                }
            }
    
    
    //check if fields are filled in
    func validateAndGoToPage2() {
        guard !businessName.isEmpty, !location.isEmpty, !description.isEmpty, !hours.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        errorMessage = nil
        withAnimation {
            currentPage = 2
        }
    }
    
    func saveBusinessInfo() async {
        // validate required fields
        guard !businessName.isEmpty, !location.isEmpty, !description.isEmpty, !hours.isEmpty,
              !prizeOffered.isEmpty, !minimumPurchase.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        // check if still uploading
        if isUploadingImage {
            errorMessage = "Please wait for image upload to complete"
            return
        }
        
        // check if image selected
        if logoUrl.isEmpty {
            errorMessage = "Please select a business logo"
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
        
        // create business document
        let businessData: [String: Any] = [
            "businessId": uid,
            "businessName": businessName,
            "category": category.rawValue,
            "location": location,
            "email": email,
            "description": description,
            "hours": hours,
            "prizeOffered": prizeOffered,
            "stampsNeeded": stampsNeeded,
            "minimumPurchase": minPurchase,
            "logoUrl": logoUrl,
            "accountType": "Business",
            "createdAt": Timestamp(date: Date()),
            "totalCustomers": 0,
            "totalStampsGiven": 0,
            "rewardsRedeemed": 0
        ]
        
        do {
            try await db.collection("businesses").document(uid).setData(businessData)
            await MainActor.run {
                authManager.businessNeedsOnboarding = false
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to save. Please try again."
                isLoading = false
            }
        }
    }
}

#Preview {
    BusinessOnboardingView()
        .environmentObject(AuthManager())
}

