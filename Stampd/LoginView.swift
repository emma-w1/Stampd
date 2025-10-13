//
//  LoginView.swift
//  Stampd
//
//  Created by Adishree Das on 9/27/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseCore

//user profile data
struct UserProfile: Identifiable, Codable {
    @DocumentID var id: String?
    let uid: String
    let email: String
    let phoneNumber: String?
    let accountType: AccountType
    let createdAt: Date
    
    enum AccountType: String, Codable, CaseIterable {
        case customer = "Customer"
        case business = "Business"
    }
}

//empty fields for now
struct LoginView: View {
        @State private var email = ""
        @State private var password = ""
        @State private var phoneNumber = ""
        @State private var selectedAccountType: UserProfile.AccountType = .customer
        
        @State private var errorMessage: String? = nil
        @State private var isLoading = false
        @State private var isSigningUp = false
        
        @EnvironmentObject var authManager: AuthManager
        
    //sign up function
    private func signUp() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter an email and a password."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let uid = result.user.uid
            
            let newProfile = UserProfile(
                uid: uid,
                email: email,
                phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
                accountType: selectedAccountType,
                createdAt: Date()
            )
            
            let db = Firestore.firestore()
            try db.collection("users").document(uid).setData(from: newProfile)
        } catch let error {
            print("Sign Up Error: \(error.localizedDescription)")
            errorMessage = "Sign Up failed. \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    //signing in
    private func signIn() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter an email and a password."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            let _ = result.user.uid
            
        } catch let error {
            print("Login Error: \(error.localizedDescription)")
            errorMessage = "Login failed. Please check your credentials."
        }
        
        isLoading = false
    }
    
    
    var body: some View {
        ZStack {
            //shows form items (emailpassword)
                VStack(spacing: 20) {
                    Spacer()
                    Image("StampdLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 150)
                    Group {
                        Text("email")
                            .font(.custom("Jersey15-Regular", size: 34))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(Color.stampdTextPink)
                        TextField("Email Address", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.stampdTextPink, lineWidth: 2)
                            )
                            .padding(.bottom, 20)
                        Text("password")
                            .font(.custom("Jersey15-Regular", size: 34))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(Color.stampdTextPink)
                        SecureField("Password", text: $password)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.stampdTextPink, lineWidth: 2)
                            )
                        //enter phone number only when signing up
                        if isSigningUp {
                            Text("phone number")
                                .font(.custom("Jersey15-Regular", size: 34))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundColor(Color.stampdTextPink)
                            TextField("Phone Number", text: $phoneNumber)
                                .keyboardType(.phonePad)
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.stampdTextPink, lineWidth: 2)
                                )
                        }
                    }
                    .disabled(isLoading)
                //enter account type only when signing up
                    if isSigningUp {
                        VStack(alignment: .leading) {
                                Picker("Account Type", selection: $selectedAccountType) {
                                    ForEach(UserProfile.AccountType.allCases, id: \.self) { type in
                                        Text(type.rawValue)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .tint(Color.stampdPink)
                            }
                            .padding(.vertical, 5)
                        }
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.callout)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 5)
                    }
                    
                    //manage sign up vs/sign in
                    Button(action: {
                        Task {
                            if isSigningUp {
                                await signUp()
                            } else {
                                await signIn()
                            }
                        }
                    }) {
                        Text(isSigningUp ? "sign up" : "login")
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
                    
                    Button {
                        withAnimation {
                            isSigningUp.toggle()
                            errorMessage = nil
                            password = ""
                            phoneNumber = ""
                        }
                    } label: {
                        Text(isSigningUp ?
                             "login" :
                             "sign up")
                        .font(.custom("Jersey15-Regular", size: 28))
                                .foregroundColor(Color.stampdTextPink)
                    }
                    
                    Spacer()
                    
                }
                .padding(25)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.stampdGradientTop, Color.stampdGradientBottom]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                )
            
            //loading page
            if isLoading {
                ProgressView("Processing...")
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
            }
        }
    }
}

#Preview {
    LoginView()
}
