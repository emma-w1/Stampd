//
//  DiscoverView.swift
//  Stampd
//
//  Created by Adishree Das on 10/11/25.
//

import SwiftUI
import FirebaseFirestore

// Filler data for stamps
struct StampCard: Identifiable {
    let id = UUID()
    let businessName: String
    let reward: String
    let stampsAway: Int
}

struct Business: Identifiable, Codable {
    var id: String?
    let businessId: String
    let businessName: String
    let location: String
    let category: String
    let logoUrl: String
    let description: String
    let email: String
    let phoneNumber: String
    let hours: String
    let prizeOffered: String
    let stampsNeeded: Int
    let minimumPurchase: Double
    let accountType: String
    let createdAt: Date
    let totalCustomers: Int
    let totalStampsGiven: Int
    let rewardsRedeemed: Int
}

class BusinessDataFetcher: ObservableObject{
    @Published var businesses: [Business] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var db = Firestore.firestore()
    
    init() {
        fetchBusinesses()
    }
    
    func fetchBusinesses() {
        print("🔍 Fetching businesses from Firebase...")
        isLoading = true
        errorMessage = nil
        
        db.collection("businesses").getDocuments { [weak self] (querySnapshot, error) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("❌ Error fetching businesses: \(error.localizedDescription)")
                    self.errorMessage = "Failed to fetch businesses."
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("⚠️ No documents found in businesses collection")
                    self.businesses = []
                    return
                }
                
                print("📦 Found \(documents.count) business documents")
                
                self.businesses = documents.compactMap { document in
                    do {
                        var business = try document.data(as: Business.self)
                        business.id = document.documentID
                        print("✅ Loaded: \(business.businessName)")
                        return business
                    } catch {
                        print("❌ Decoding error for \(document.documentID): \(error)")
                        return nil
                    }
                }
                
                print("✅ Successfully loaded \(self.businesses.count) businesses")
            }
        }
    }
}

struct DiscoverView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject var dataFetcher = BusinessDataFetcher()
    
    // Filler data
    let stampCards = [
        StampCard(businessName: "Coffee Shop", reward: "FREE COFFEE", stampsAway: 3),
        StampCard(businessName: "Pizza Place", reward: "FREE PIZZA", stampsAway: 5),
        StampCard(businessName: "Ice Cream", reward: "FREE SCOOP", stampsAway: 2),
        StampCard(businessName: "Burger Joint", reward: "FREE BURGER", stampsAway: 7),
        StampCard(businessName: "Smoothie Bar", reward: "FREE SMOOTHIE", stampsAway: 4)
    ]
    
    var body: some View {
        ZStack {
            TopNavbar()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Color.clear.frame(height: 50)
                    
                    // stamps section
                    Text("My Stamps")
                        .font(.custom("Jersey15-Regular", size: 36))
                        .foregroundColor(Color.stampdTextPink)
                        .padding(.top, 10)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(stampCards) { card in
                                StampCardView(card: card)
                            }
                        }
                    }
                    .frame(height: 180)
                    
                    // businesses section
                    Text("Discover:")
                        .font(.custom("Jersey15-Regular", size: 36))
                        .foregroundColor(Color.stampdTextPink)
                        .padding(.top, 10)
                    
                    if dataFetcher.isLoading {
                        ProgressView("Fetching nearby businesses...")
                            .padding(.vertical, 50)
                            .frame(maxWidth: .infinity)
                    } else if let error = dataFetcher.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding(.vertical, 50)
                    } else if dataFetcher.businesses.isEmpty {
                        Text("No businesses found")
                            .foregroundColor(.gray)
                            .padding(.vertical, 50)
                    } else {
                        VStack(spacing: 15) {
                            ForEach(dataFetcher.businesses) { business in
                                BusinessCardView(business: business)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
                .padding(25)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.stampdGradientTop, Color.stampdGradientBottom]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
        }
    }
}

//  stamp card
struct StampCardView: View {
    let card: StampCard
    
    var body: some View {
        VStack(spacing: 10) {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 140, height: 80)
                .cornerRadius(8)
                .overlay(
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                        .font(.system(size: 30))
                )
            
            Text(card.reward)
                .font(.custom("Jersey15-Regular", size: 18))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
            
            Text("\(card.stampsAway) stamps away")
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .frame(width: 140)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

//  business card
struct BusinessCardView: View {
    let business: Business
    
    var body: some View {
        HStack(spacing: 15) {
            // Business logo from URL
            AsyncImage(url: URL(string: business.logoUrl)) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 80)
                        .cornerRadius(8)
                        .overlay(
                            ProgressView()
                        )
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .cornerRadius(8)
                        .clipped()
                case .failure:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 80)
                        .cornerRadius(8)
                        .overlay(
                            Image(systemName: "storefront")
                                .foregroundColor(.gray)
                                .font(.system(size: 30))
                        )
                @unknown default:
                    EmptyView()
                }
            }
            
            // Business info
            VStack(alignment: .leading, spacing: 5) {
                Text(business.businessName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                
                Text(business.location)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                HStack(spacing: 10) {
                    // Category tag
                    Text(business.category)
                        .font(.system(size: 12))
                        .foregroundColor(Color.stampdTextPink)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.stampdPinkLight)
                        .cornerRadius(8)
                    
                    // Stamps needed
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .foregroundColor(Color.stampdTextPink)
                            .font(.system(size: 10))
                        Text("\(business.stampsNeeded) stamps")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    DiscoverView()
        .environmentObject(AuthManager())
}
