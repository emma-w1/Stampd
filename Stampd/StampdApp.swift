//
//  StampdApp.swift
//  Stampd
//
//  Created by Adishree Das on 9/27/25.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

//configure firebase
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        print("✅ Firebase successfully configured.")
        return true
    }
}

//auth manager
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: UserProfile?
    
    init() {
        checkAuthState()
    }
    
    private func checkAuthState() {
        _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.isAuthenticated = user != nil
                if let user = user {
                    self?.loadUserProfile(uid: user.uid)
                } else {
                    self?.currentUser = nil
                }
            }
        }
    }
    
    private func loadUserProfile(uid: String) {
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(uid)
        
        docRef.getDocument { [weak self] (document, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error loading user profile: \(error.localizedDescription)")
                    // Create a default customer profile if profile doesn't exist
                    self?.createDefaultProfile(uid: uid)
                    return
                }
                
                guard let document = document, document.exists else {
                    print("⚠️ User profile document doesn't exist, creating default profile")
                    // Create a default customer profile if profile doesn't exist
                    self?.createDefaultProfile(uid: uid)
                    return
                }
                
                do {
                    let profile = try document.data(as: UserProfile.self)
                    print("✅ User profile loaded successfully: \(profile.email)")
                    self?.currentUser = profile
                } catch {
                    print("❌ Error decoding user profile: \(error.localizedDescription)")
                    // Create a default customer profile if decoding fails
                    self?.createDefaultProfile(uid: uid)
                }
            }
        }
    }
    
    private func createDefaultProfile(uid: String) {
        guard let email = Auth.auth().currentUser?.email else {
            print("❌ Cannot create default profile: no email found")
            return
        }
        
        let defaultProfile = UserProfile(
            uid: uid,
            email: email,
            phoneNumber: nil,
            accountType: .customer,
            createdAt: Date()
        )
        
        let db = Firestore.firestore()
        do {
            try db.collection("users").document(uid).setData(from: defaultProfile)
            self.currentUser = defaultProfile
            print("✅ Created default customer profile for \(email)")
        } catch {
            print("❌ Error creating default profile: \(error.localizedDescription)")
            // Even if Firestore fails, set the profile in memory so user can continue
            self.currentUser = defaultProfile
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            print("Sign out error: \(error)")
        }
    }
}

///main app struct
@main
struct StampdApp: App {
    @StateObject private var authManager = AuthManager()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                if let user = authManager.currentUser {
                    // Show appropriate view based on account type
                    if user.accountType == .customer {
                        MainContentView()
                    } else {
                        // Business view - placeholder for now
                        MainContentView() // Replace with BusinessView later
                    }
                } else {
                    // Loading state while user profile loads
                    ZStack {
                        LinearGradient(
                            gradient: Gradient(colors: [Color.stampdGradientTop, Color.stampdGradientBottom]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()
                        
                        ProgressView("Loading...")
                            .tint(Color.stampdTextPink)
                    }
                }
            } else {
                LoginView()
            }
        }
        .environmentObject(authManager)
    }
}
