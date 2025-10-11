//
//  DiscoverView.swift
//  Stampd
//
//  Created by Adishree Das on 10/11/25.
//

import SwiftUI

// Filler data for stamps
struct StampCard: Identifiable {
    let id = UUID()
    let businessName: String
    let reward: String
    let stampsAway: Int
}

// Filler data for businesses
struct Business: Identifiable {
    let id = UUID()
    let name: String
    let distance: Double
    let rating: Double
    let category: String
}

struct DiscoverView: View {
    @EnvironmentObject var authManager: AuthManager
    
    // Filler data
    let stampCards = [
        StampCard(businessName: "Coffee Shop", reward: "FREE COFFEE", stampsAway: 3),
        StampCard(businessName: "Pizza Place", reward: "FREE PIZZA", stampsAway: 5),
        StampCard(businessName: "Ice Cream", reward: "FREE SCOOP", stampsAway: 2),
        StampCard(businessName: "Burger Joint", reward: "FREE BURGER", stampsAway: 7),
        StampCard(businessName: "Smoothie Bar", reward: "FREE SMOOTHIE", stampsAway: 4)
    ]
    
    let businesses = [
        Business(name: "Starbucks", distance: 0.5, rating: 4.5, category: "Coffee"),
        Business(name: "Joe's Pizza", distance: 1.2, rating: 4.8, category: "Pizza"),
        Business(name: "Sweet Treats", distance: 0.8, rating: 4.3, category: "Dessert"),
        Business(name: "The Burger Place", distance: 2.1, rating: 4.6, category: "Burgers"),
        Business(name: "Fresh Smoothies", distance: 0.3, rating: 4.7, category: "Drinks"),
        Business(name: "Thai Kitchen", distance: 1.5, rating: 4.4, category: "Thai"),
        Business(name: "Sushi Express", distance: 1.8, rating: 4.9, category: "Sushi"),
        Business(name: "Taco Fiesta", distance: 0.7, rating: 4.2, category: "Mexican")
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
                    
                    VStack(spacing: 15) {
                        ForEach(businesses) { business in
                            BusinessCardView(business: business)
                        }
                    }
                    .padding(.bottom, 20)
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
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 80, height: 80)
                .cornerRadius(8)
                .overlay(
                    Image(systemName: "storefront")
                        .foregroundColor(.gray)
                        .font(.system(size: 30))
                )
            
            VStack(alignment: .leading, spacing: 5) {
                Text(business.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                
                Text("\(String(format: "%.1f", business.distance)) miles away")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                HStack(spacing: 10) {
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 12))
                        Text(String(format: "%.1f", business.rating))
                            .font(.system(size: 14))
                            .foregroundColor(.black)
                    }
                    
                    Text(business.category)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
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
