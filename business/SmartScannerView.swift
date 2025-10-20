import SwiftUI
import AVFoundation
import FirebaseFirestore
import reusable

struct SmartScannerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    @State private var scannedCode: String?
    @State private var isProcessing = false
    @State private var statusMessage = "Scan customer QR code"
    @State private var showSuccess = false
    @State private var actionTaken = "" // "stamp" or "prize"
    
    var body: some View {
        ZStack {
            QRScannerView(scannedCode: $scannedCode)
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
                            Image(systemName: actionTaken == "stamp" ? "star.fill" : "gift.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.green)
                            
                            Text(actionTaken == "stamp" ? "Stamp Added!" : "Prize Redeemed!")
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
                processCustomer(userId: userId)
            }
        }
    }
    
    func processCustomer(userId: String) {
        guard let businessId = authManager.currentUser?.uid else {
            statusMessage = "Error: Business not found"
            return
        }
        
        print("🔍 Processing customer scan:")
        print("   Customer ID: \(userId)")
        print("   Business ID: \(businessId)")
        
        isProcessing = true
        let db = Firestore.firestore()
        
        let programRef = db.collection("users").document(userId)
            .collection("programs").document(businessId)
        
        print("📍 Checking path: users/\(userId)/programs/\(businessId)")
        
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
                print("⚠️ Program document does not exist")
                self.statusMessage = "Customer not in your program"
                self.isProcessing = false
                self.showSuccess = true
                return
            }
            
            // Get current stamps and check if they can claim a prize
            let currentStamps = document.data()?["currentStamps"] as? Int ?? 0
            let prizesClaimed = document.data()?["prizesClaimed"] as? Int ?? 0
            
            print("✅ Program found - Current stamps: \(currentStamps), Prizes claimed: \(prizesClaimed)")
            
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
                
                // Decide whether to add stamp or redeem prize
                if currentStamps >= stampsNeeded && !(document.data()?["claimed"] as? Bool ?? false) {
                    // Customer can claim a prize
                    self.redeemPrize(programRef: programRef, customerId: userId)
                } else if currentStamps < stampsNeeded {
                    // Customer needs more stamps
                    self.addStamp(programRef: programRef)
                } else {
                    // Customer already claimed their prize
                    self.statusMessage = "Customer already claimed their prize"
                    self.isProcessing = false
                    self.showSuccess = true
                }
            }
        }
    }
    
    func addStamp(programRef: DocumentReference) {
        print("🎯 Adding stamp to customer")
        
        programRef.updateData([
            "currentStamps": FieldValue.increment(Int64(1))
        ]) { error in
            self.isProcessing = false
            
            if let error = error {
                print("❌ Error adding stamp: \(error.localizedDescription)")
                self.statusMessage = "Failed to add stamp"
            } else {
                print("✅ Stamp added successfully!")
                self.actionTaken = "stamp"
                self.statusMessage = "Stamp added successfully!"
            }
            
            self.showSuccess = true
        }
    }
    
    func redeemPrize(programRef: DocumentReference, customerId: String) {
        print("🎁 Redeeming prize for customer")
        
        // Mark as claimed and increment prizes claimed
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
                self.actionTaken = "prize"
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
}
