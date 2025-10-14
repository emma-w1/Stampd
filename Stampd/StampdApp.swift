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
        return true
    }
}

//auth manager
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: UserProfile?
    @Published var businessNeedsOnboarding = false
    
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
                        self.currentUser = profile
                        
                        if profile.accountType == .business {
                            self.checkBusinessOnboarding(uid: uid)
                        }
                    } catch {
                        print("❌ Profile decode error: \(error.localizedDescription)")
                        self.createMissingProfile(uid: uid)
                    }
                } else {
                    self.createMissingProfile(uid: uid)
                }
            }
        }
    }
    
    private func checkBusinessOnboarding(uid: String) {
        let db = Firestore.firestore()
        
        db.collection("businesses").document(uid).getDocument { [weak self] (document, error) in
            DispatchQueue.main.async {
                self?.businessNeedsOnboarding = !(document?.exists ?? false)
            }
        }
    }
    
    private func createMissingProfile(uid: String) {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        let newProfile = UserProfile(
            uid: uid,
            email: currentUser.email ?? "unknown@email.com",
            phoneNumber: nil,
            accountType: .customer,
            createdAt: Date()
        )
        
        let db = Firestore.firestore()
        
        do {
            try db.collection("users").document(uid).setData(from: newProfile) { [weak self] error in
                DispatchQueue.main.async {
                    self?.currentUser = newProfile
                }
            }
        } catch {
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
                        // Business account
                        if authManager.businessNeedsOnboarding {
                            BusinessOnboardingView()
                        } else {
                            BusinessMainContentView()
                        }
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
