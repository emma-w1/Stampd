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
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error loading user profile: \(error.localizedDescription)")
                    // Still try to create a profile even if there's an error
                    self.createMissingProfile(uid: uid)
                    return
                }
                
                // Check if profile exists
                if let document = document, document.exists {
                    // Profile exists, decode it
                    do {
                        let profile = try document.data(as: UserProfile.self)
                        print("✅ User profile loaded: \(profile.email)")
                        self.currentUser = profile
                    } catch {
                        print("❌ Error decoding user profile: \(error.localizedDescription)")
                        // Profile is corrupt, recreate it
                        self.createMissingProfile(uid: uid)
                    }
                } else {
                    // Profile doesn't exist, create it
                    print("⚠️ User profile doesn't exist in Firestore. Creating now...")
                    self.createMissingProfile(uid: uid)
                }
            }
        }
    }
    
    private func createMissingProfile(uid: String) {
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ Cannot create profile: no authenticated user")
            return
        }
        
        let email = currentUser.email ?? "unknown@email.com"
        
        // Create a default customer profile
        let newProfile = UserProfile(
            uid: uid,
            email: email,
            phoneNumber: nil,
            accountType: .customer,
            createdAt: Date()
        )
        
        let db = Firestore.firestore()
        
        do {
            // Save to Firestore
            try db.collection("users").document(uid).setData(from: newProfile) { [weak self] error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Failed to save profile to Firestore: \(error.localizedDescription)")
                        // Set the profile anyway so user can continue
                        self?.currentUser = newProfile
                    } else {
                        print("✅ Successfully created profile in Firestore for \(email)")
                        self?.currentUser = newProfile
                    }
                }
            }
        } catch {
            print("❌ Failed to encode profile: \(error.localizedDescription)")
            // Set the profile anyway so user can continue
            self.currentUser = newProfile
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
                    if user.accountType == .customer {
                        MainContentView()
                    } else {
                        BusinessMainContentView()
                    }
                } else { //loading
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
