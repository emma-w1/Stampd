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
        
        isProcessing = true
        let db = Firestore.firestore()
        
        let programRef = db.collection("users").document(customerId)
            .collection("programs").document(businessId)
        
        // get customer program data
        programRef.getDocument { (document, error) in
            if let error = error {
                self.statusMessage = "Error: Customer not found"
                self.isProcessing = false
                self.showSuccess = true
                return
            }
            
            guard let document = document, document.exists else {
                self.addCustomerToProgram(customerId: customerId, businessId: businessId)
                return
            }
            
            // check if they can claim a prize
            let currentStamps = document.data()?["currentStamps"] as? Int ?? 0
            let alreadyClaimed = document.data()?["claimed"] as? Bool ?? false
            
            if alreadyClaimed {
                self.statusMessage = "Customer already claimed their prize"
                self.isProcessing = false
                self.showSuccess = true
                return
            }
            
            // get business info
            db.collection("businesses").document(businessId).getDocument { (businessDoc, businessError) in
                if let businessError = businessError {
                    self.statusMessage = "Error: Could not load program info"
                    self.isProcessing = false
                    self.showSuccess = true
                    return
                }
                
                guard let businessDoc = businessDoc,
                      let businessData = businessDoc.data(),
                      let stampsNeeded = businessData["stampsNeeded"] as? Int else {
                    self.statusMessage = "Error: Invalid program configuration"
                    self.isProcessing = false
                    self.showSuccess = true
                    return
                }
                
                // check if customer has enough stamps
                if currentStamps >= stampsNeeded {
                    self.processPrizeRedemption(programRef: programRef, customerId: customerId)
                } else {
                    self.statusMessage = "Customer needs \(stampsNeeded - currentStamps) more stamps"
                    self.isProcessing = false
                    self.showSuccess = true
                }
            }
        }
    }
    
    func processPrizeRedemption(programRef: DocumentReference, customerId: String) {
        // mark as claimed, reset stamps and etc
        programRef.updateData([
            "claimed": true,
            "currentStamps": 0,
            "prizesClaimed": FieldValue.increment(Int64(1))
        ]) { error in
            self.isProcessing = false
            
            if let error = error {
                self.statusMessage = "Failed to redeem prize"
            } else {
                self.statusMessage = "Prize redeemed successfully!"
                self.trackDailyReward(rewardType: "prize", count: 1)
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
        ])
    }
    
    func addCustomerToProgram(customerId: String, businessId: String) {
        let db = Firestore.firestore()
        let programRef = db.collection("users").document(customerId)
            .collection("programs").document(businessId)
        
        // new program entry
        let programData: [String: Any] = [
            "claimed": false,
            "currentStamps": 1,
            "prizesClaimed": 0
        ]
        
        programRef.setData(programData) { error in
            self.isProcessing = false
            
            if let error = error {
                self.statusMessage = "Failed to add customer to program"
            } else {
                self.statusMessage = "Customer added to program! 1st stamp given!"
                self.trackDailyReward(rewardType: "stamp", count: 1)
            }
            
            self.showSuccess = true
        }
    }
    
    func trackDailyReward(rewardType: String, count: Int) {
        guard let businessId = authManager.currentUser?.uid else {
            return 
        }
        
        let db = Firestore.firestore()
        let today = Calendar.current.startOfDay(for: Date())
        let dateString = ISO8601DateFormatter().string(from: today)
        
        let dailyRewardsRef = db.collection("businesses")
            .document(businessId)
            .collection("dailyRewards")
            .document(dateString)
        
        let fieldName = rewardType == "stamp" ? "stampsGiven" : "prizesRedeemed"
        
        dailyRewardsRef.setData([
            "date": Timestamp(date: today),
            fieldName: FieldValue.increment(Int64(count))
        ], merge: true)
    }
}
