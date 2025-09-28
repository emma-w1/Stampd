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
        
        docRef.getDocument(as: UserProfile.self) { [weak self] (result: Result<UserProfile, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let profile):
                    self?.currentUser = profile
                case .failure(let error):
                    print("Error loading user profile: \(error)")
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
            if authManager.isAuthenticated, let user = authManager.currentUser {
                HomeView(profile: user, signOutAction: authManager.signOut)
            } else {
                LoginView()
            }
        }
        .environmentObject(authManager)
    }
}
