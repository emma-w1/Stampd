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
                    return
                }
                
                guard let document = document, document.exists else {
                    print("⚠️ User profile document doesn't exist, creating default profile")
                    return
                }
                
                do {
                    let profile = try document.data(as: UserProfile.self)
                    print("✅ User profile loaded successfully: \(profile.email)")
                    self?.currentUser = profile
                } catch {
                    print("❌ Error decoding user profile: \(error.localizedDescription)")
                }
            }
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
                        MainContentView()
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
