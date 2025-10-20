import SwiftUI
import AVFoundation
import FirebaseFirestore

struct SmartScannerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    @State private var scannedCode: String?
    @State private var isScanning = true
    @State private var isProcessing = false
    @State private var statusMessage = "Scan customer QR code"
    @State private var showSuccess = false
    @State private var actionTaken = "" 
    
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
        
        isProcessing = true
        let db = Firestore.firestore()
        
        let programRef = db.collection("users").document(userId)
            .collection("programs").document(businessId)
        
        //get user program data
        programRef.getDocument { (document, error) in
            if let error = error {
                self.statusMessage = "Error: Customer not found"
                self.isProcessing = false
                self.showSuccess = true
                return
            }
            
            guard let document = document, document.exists else {
                self.statusMessage = "Customer not in your program"
                self.isProcessing = false
                self.showSuccess = true
                return
            }
            
            // check if they can claim a prize
            let currentStamps = document.data()?["currentStamps"] as? Int ?? 0
            let prizesClaimed = document.data()?["prizesClaimed"] as? Int ?? 0
            
            
            // check stampsNeeded
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
                
                // add stamp or redeem prize
                if currentStamps >= stampsNeeded && !(document.data()?["claimed"] as? Bool ?? false) {
                    self.redeemPrize(programRef: programRef, customerId: userId)
                } else if currentStamps < stampsNeeded {
                    self.addStamp(programRef: programRef)
                } else {
                    self.statusMessage = "Customer already claimed their prize"
                    self.isProcessing = false
                    self.showSuccess = true
                }
            }
        }
    }
    
    func addStamp(programRef: DocumentReference) {
        
        programRef.updateData([
            "currentStamps": FieldValue.increment(Int64(1))
        ]) { error in
            self.isProcessing = false
            
            if let error = error {
                self.statusMessage = "Failed to add stamp"
            } else {
                self.actionTaken = "stamp"
                self.statusMessage = "Stamp added successfully!"
            }
            
            self.showSuccess = true
        }
    }
    
    func redeemPrize(programRef: DocumentReference, customerId: String) {
        // reset and add prize 
        programRef.updateData([
            "claimed": true,
            "currentStamps": 0,
            "prizesClaimed": FieldValue.increment(Int64(1))
        ]) { error in
            self.isProcessing = false
            
            if let error = error {
                self.statusMessage = "Failed to redeem prize"
            } else {
                self.actionTaken = "prize"
                self.statusMessage = "Prize redeemed successfully!"
                
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
            }
        }
    }
}
