import SwiftUI
import AVFoundation
import FirebaseFirestore

struct PrizeScannerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    @State private var scannedCode: String?
    @State private var isScanning = true
    @State private var isProcessing = false
    @State private var statusMessage = "Scan customer QR code to redeem prize"
    @State private var showSuccess = false
    
    var body: some View {
        ZStack {
            QRScannerView(scannedCode: $scannedCode, isScanning: $isScanning)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                VStack(spacing: 15) {
                    Text(statusMessage)
                        .font(.custom("Jersey15-Regular", size: 30))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    if isProcessing {
                        ProgressView()
                            .tint(.white)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.7))
                .cornerRadius(15)
                .padding()
                
                if showSuccess {
                    VStack(spacing: 15) {
                        HStack(spacing: 10) {
                            Image(systemName: "gift.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.green)
                            
                            Text("Prize Redeemed!")
                                .font(.custom("Jersey15-Regular", size: 24))
                                .foregroundColor(.white)
                        }
                        
                        Button(action: { dismiss() }) {
                            Text("Done")
                                .font(.custom("Jersey15-Regular", size: 20))
                                .foregroundColor(.white)
                                .padding(.horizontal, 40)
                                .padding(.vertical, 12)
                                .background(Color.stampdButtonPink)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(15)
                    .padding()
                }
                
                Spacer()
            }
        }
        .onChange(of: scannedCode) { oldValue, newValue in
            if let userId = newValue {
                redeemPrize(for: userId)
            }
        }
    }
    
    func redeemPrize(for customerId: String) {
        guard let businessId = authManager.currentUser?.uid else {
            statusMessage = "Error: Business not found"
            return
        }
        
        print("🎁 Attempting to redeem prize:")
        print("   Customer ID: \(customerId)")
        print("   Business ID: \(businessId)")
        
        isProcessing = true
        let db = Firestore.firestore()
        
        let programRef = db.collection("users").document(customerId)
            .collection("programs").document(businessId)
        
        print("📍 Checking path: users/\(customerId)/programs/\(businessId)")
        
        // First, get the customer's current program data
        programRef.getDocument { (document, error) in
            if let error = error {
                print("❌ Error fetching program: \(error.localizedDescription)")
                self.statusMessage = "Error: Customer not found"
                self.isProcessing = false
                self.showSuccess = true
                return
            }
            
            guard let document = document, document.exists else {
                print("⚠️ Program document does not exist - adding customer to program")
                self.addCustomerToProgram(customerId: customerId, businessId: businessId)
                return
            }
            
            // Get current stamps and check if they can claim a prize
            let currentStamps = document.data()?["currentStamps"] as? Int ?? 0
            let alreadyClaimed = document.data()?["claimed"] as? Bool ?? false
            
            print("✅ Program found - Current stamps: \(currentStamps), Already claimed: \(alreadyClaimed)")
            
            if alreadyClaimed {
                self.statusMessage = "Customer already claimed their prize"
                self.isProcessing = false
                self.showSuccess = true
                return
            }
            
            // Get business info to check stampsNeeded
            db.collection("businesses").document(businessId).getDocument { (businessDoc, businessError) in
                if let businessError = businessError {
                    print("❌ Error fetching business info: \(businessError.localizedDescription)")
                    self.statusMessage = "Error: Could not load program info"
                    self.isProcessing = false
                    self.showSuccess = true
                    return
                }
                
                guard let businessDoc = businessDoc,
                      let businessData = businessDoc.data(),
                      let stampsNeeded = businessData["stampsNeeded"] as? Int else {
                    print("❌ Could not get stampsNeeded from business")
                    self.statusMessage = "Error: Invalid program configuration"
                    self.isProcessing = false
                    self.showSuccess = true
                    return
                }
                
                print("📊 Program requires \(stampsNeeded) stamps, customer has \(currentStamps)")
                
                // Check if customer has enough stamps
                if currentStamps >= stampsNeeded {
                    // Customer can claim a prize
                    self.processPrizeRedemption(programRef: programRef, customerId: customerId)
                } else {
                    // Customer needs more stamps
                    self.statusMessage = "Customer needs \(stampsNeeded - currentStamps) more stamps"
                    self.isProcessing = false
                    self.showSuccess = true
                }
            }
        }
    }
    
    func processPrizeRedemption(programRef: DocumentReference, customerId: String) {
        print("🎁 Redeeming prize for customer")
        
        // Mark as claimed, reset stamps, and increment prizes claimed
        programRef.updateData([
            "claimed": true,
            "currentStamps": 0, // Reset stamps after claiming
            "prizesClaimed": FieldValue.increment(Int64(1))
        ]) { error in
            self.isProcessing = false
            
            if let error = error {
                print("❌ Error redeeming prize: \(error.localizedDescription)")
                self.statusMessage = "Failed to redeem prize"
            } else {
                print("✅ Prize redeemed successfully!")
                self.statusMessage = "Prize redeemed successfully!"
                
                // Also update business analytics
                self.updateBusinessAnalytics()
            }
            
            self.showSuccess = true
        }
    }
    
    func updateBusinessAnalytics() {
        guard let businessId = authManager.currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("businesses").document(businessId).updateData([
            "rewardsRedeemed": FieldValue.increment(Int64(1))
        ]) { error in
            if let error = error {
                print("❌ Error updating business analytics: \(error.localizedDescription)")
            } else {
                print("✅ Business analytics updated")
            }
        }
    }
    
    func addCustomerToProgram(customerId: String, businessId: String) {
        print("➕ Adding customer to business program")
        
        let db = Firestore.firestore()
        let programRef = db.collection("users").document(customerId)
            .collection("programs").document(businessId)
        
        // Create new program entry with initial values
        let programData: [String: Any] = [
            "claimed": false,
            "currentStamps": 1, // Give them their first stamp
            "prizesClaimed": 0
        ]
        
        programRef.setData(programData) { error in
            self.isProcessing = false
            
            if let error = error {
                print("❌ Error adding customer to program: \(error.localizedDescription)")
                self.statusMessage = "Failed to add customer to program"
            } else {
                print("✅ Customer added to program with first stamp!")
                self.statusMessage = "Customer added to program! First stamp given!"
            }
            
            self.showSuccess = true
        }
    }
}