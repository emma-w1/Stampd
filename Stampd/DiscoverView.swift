//
//  DiscoverView.swift
//  Stampd
//
//  Created by Adishree Das on 10/11/25.
//

import SwiftUI
import FirebaseFirestore

// customer program data
struct CustomerProgram: Identifiable, Codable {
    @DocumentID var id: String?
    var claimed: Bool
    var currentStamps: Int
    var prizesClaimed: Int
}

struct ProgramWithBusiness: Identifiable {
    let id: String // businessId
    let program: CustomerProgram
    let business: Business
}

//all business info from firebase
struct Business: Identifiable, Codable, Hashable {
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
    
    static func==(lhs: Business, rhs: Business) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

//fetch customer programs from Firebase
class CustomerProgramFetcher: ObservableObject {
    @Published var programsWithBusinesses: [ProgramWithBusiness] = []
    @Published var isLoading = false
    
    private var db = Firestore.firestore()
    
    func fetchPrograms(for customerId: String) {
        print("🔍 Fetching programs for customer: \(customerId)")
        isLoading = true
        
        // Access subcollection: users/{userId}/programs
        db.collection("users").document(customerId).collection("programs")
            .getDocuments { [weak self] (querySnapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error fetching programs: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                    return
                }
                
                let programs = querySnapshot?.documents.compactMap { document -> CustomerProgram? in
                    do {
                        var program = try document.data(as: CustomerProgram.self)
                        program.id = document.documentID // businessId
                        return program
                    } catch {
                        print("❌ Decoding program error: \(error)")
                        return nil
                    }
                } ?? []
                
                print("✅ Found \(programs.count) programs, now fetching business details...")
                
                // business details from each program
                let dispatchGroup = DispatchGroup()
                var combinedPrograms: [ProgramWithBusiness] = []
                
                for program in programs {
                    guard let businessId = program.id else { continue }
                    
                    dispatchGroup.enter()
                    self.db.collection("businesses").document(businessId).getDocument { (document, error) in
                        defer { dispatchGroup.leave() }
                        
                        if let error = error {
                            print("❌ Error fetching business \(businessId): \(error.localizedDescription)")
                            return
                        }
                        
                        guard let document = document, document.exists else {
                            print("⚠️ Business \(businessId) not found")
                            return
                        }
                        
                        do {
                            var business = try document.data(as: Business.self)
                            business.id = document.documentID
                            let combined = ProgramWithBusiness(id: businessId, program: program, business: business)
                            combinedPrograms.append(combined)
                            print("✅ Loaded business: \(business.businessName)")
                        } catch {
                            print("❌ Error decoding business: \(error)")
                        }
                    }
                }
                
                dispatchGroup.notify(queue: .main) {
                    self.programsWithBusinesses = combinedPrograms
                    self.isLoading = false
                    print("✅ Total combined programs: \(self.programsWithBusinesses.count)")
                }
            }
    }
}

//get firebase business info
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
    @StateObject var businessFetcher = BusinessDataFetcher()
    @StateObject var programFetcher = CustomerProgramFetcher()
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.stampdGradientTop, Color.stampdGradientBottom]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                
                ScrollView {
                    TopNavbar()
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // stamps section
                        Text("My Stamp Programs")
                            .font(.custom("Jersey15-Regular", size: 42))
                            .foregroundColor(Color.stampdTextPink)
                            .padding(.top, 10)
                        
                        if programFetcher.programsWithBusinesses.isEmpty {
                            Text("Join a stamp program by discovering local businesses")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.vertical, 40)
                                .frame(maxWidth: .infinity)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(programFetcher.programsWithBusinesses) { programWithBusiness in
                                        ProgramStampCardView(programWithBusiness: programWithBusiness)
                                    }
                                }
                            }
                            .frame(height: 180)
                        }
                        
                        // businesses section
                        Text("Discover:")
                            .font(.custom("Jersey15-Regular", size: 42))
                            .foregroundColor(Color.stampdTextPink)
                            .padding(.top, 10)
                        
                        if businessFetcher.isLoading {
                            ProgressView("Fetching nearby businesses...")
                                .padding(.vertical, 50)
                                .frame(maxWidth: .infinity)
                        } else if let error = businessFetcher.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .padding(.vertical, 50)
                        } else if businessFetcher.businesses.isEmpty {
                            Text("No businesses found")
                                .foregroundColor(.gray)
                                .padding(.vertical, 50)
                        } else {
                            VStack(spacing: 15) {
                                ForEach(businessFetcher.businesses) { business in
                                    NavigationLink(destination: BusinessInfoView(business: business)) {
                                        BusinessCardView(business: business)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.bottom, 20)
                        }
                    }
                    .padding(25)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .onAppear {
                if let customerId = authManager.currentUser?.uid {
                    programFetcher.fetchPrograms(for: customerId)
                }
            }
        }
    }
}

// program stamp card view
struct ProgramStampCardView: View {
    let programWithBusiness: ProgramWithBusiness
    
    var body: some View {
        VStack(spacing: 10) {
            // business logo
            AsyncImage(url: URL(string: programWithBusiness.business.logoUrl)) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 140, height: 80)
                        .cornerRadius(8)
                        .overlay(ProgressView())
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 140, height: 80)
                        .cornerRadius(8)
                        .clipped()
                case .failure:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 140, height: 80)
                        .cornerRadius(8)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                                .font(.system(size: 30))
                        )
                @unknown default:
                    EmptyView()
                }
            }
            
            Text(programWithBusiness.business.prizeOffered)
                .font(.custom("Jersey15-Regular", size: 18))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
            
            // stamps progress 
            Text("\(programWithBusiness.business.stampsNeeded - programWithBusiness.program.currentStamps) stamps away")
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
        NavigationLink (destination: BusinessInfoView(business: business)){
            HStack(spacing: 15) {
                // logo from url
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
                
                // business info
                VStack(alignment: .leading, spacing: 5) {
                    Text(business.businessName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Text(business.location)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                    
                    HStack(spacing: 10) {
                        Text(business.category)
                            .font(.system(size: 12))
                            .foregroundColor(Color.stampdTextPink)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.stampdPinkLight)
                            .cornerRadius(8)
                        
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
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    DiscoverView()
        .environmentObject(AuthManager())
}
