//
//  SharedModels.swift
//  Stampd
//
//  Created by Adishree Das on 10/13/25.
//

import SwiftUI
import FirebaseFirestore

// User profile data
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

// Business data from Firebase
struct Business: Identifiable, Codable, Hashable {
    var id: String?
    let businessId: String
    let businessName: String
    let location: String
    let category: String
    let logoUrl: String
    let description: String
    let email: String
    let phoneNumber: String?
    let hours: String
    let prizeOffered: String
    let stampsNeeded: Int
    let minimumPurchase: Double
    let accountType: String
    let createdAt: Date
    let totalCustomers: Int
    let totalStampsGiven: Int
    let rewardsRedeemed: Int
    
    static func==(lhs: Business, rhs: Business) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// Customer program progress (subcollection under user)
struct CustomerProgram: Identifiable, Codable {
    @DocumentID var id: String?
    var claimed: Bool
    var currentStamps: Int
    var prizesClaimed: Int
}

// Combined program with business info for display
struct ProgramWithBusiness: Identifiable {
    let id: String
    let program: CustomerProgram
    let business: Business
}

// Business categories
enum BusinessCategory: String, CaseIterable, Hashable {
    case foodDrink = "Food & Drink"
    case retailApparel = "Retail & Apparel"
    case beautyWellness = "Beauty & Wellness"
    case entertainment = "Entertainment"
    case localServices = "Local Services"
    case other = "Other"
    
    var id: String { self.rawValue }
}

