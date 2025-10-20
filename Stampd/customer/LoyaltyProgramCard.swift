import SwiftUI

struct LoyaltyProgramCard: View {
    let programWithBusiness: ProgramWithBusiness
    @State private var isFlipped = false
    
    var body: some View {
        ZStack {
            // front
            if !isFlipped {
                CardFrontView(programWithBusiness: programWithBusiness)
            }
            
            // Back
            if isFlipped {
                CardBackView(programWithBusiness: programWithBusiness)
            }
        }
        .frame(height: 140)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .rotation3DEffect(
            .degrees(isFlipped ? 180 : 0),
            axis: (x: 0, y: 1, z: 0)
        )
        .animation(.easeInOut(duration: 0.6), value: isFlipped)
        .onTapGesture {
            withAnimation {
                isFlipped.toggle()
            }
        }
    }
}

struct CardFrontView: View {
    let programWithBusiness: ProgramWithBusiness
    
    var body: some View {
        HStack(spacing: 15) {
            // business logo
            AsyncImage(url: URL(string: programWithBusiness.business.logoUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "building.2")
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 80, height: 80)
            .clipShape(Circle())
            
            //business info
            VStack(alignment: .leading, spacing: 8) {
                Text(programWithBusiness.business.businessName)
                    .font(.custom("Jersey15-Regular", size: 20))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(programWithBusiness.business.category)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                // progress bar
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Progress")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(programWithBusiness.program.currentStamps)/\(programWithBusiness.business.stampsNeeded)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    
                    ProgressView(value: Double(programWithBusiness.program.currentStamps), total: Double(programWithBusiness.business.stampsNeeded))
                        .progressViewStyle(LinearProgressViewStyle(tint: Color.stampdButtonPink))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                }
                
                // prize
                Text("Prize: \(programWithBusiness.business.prizeOffered)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // tap to flip
            VStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 16))
                    .foregroundColor(.stampdButtonPink)
                
                Text("Tap to flip")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(15)
    }
}

struct CardBackView: View {
    let programWithBusiness: ProgramWithBusiness
    
    var body: some View {
        ZStack {
            // stamp image
            StampImageView(stampCount: programWithBusiness.program.currentStamps)
                .frame(maxHeight: .infinity)
                .clipped()
        }
        .frame(maxHeight: .infinity)
        .scaleEffect(x: -1, y: 1) 
    }
}

struct StampImageView: View {
    let stampCount: Int
    
    var body: some View {
        let imageName = getStampImageName(for: stampCount)
        
        Image(imageName)
            .resizable()
            .frame(maxHeight: .infinity)
    }
    
    private func getStampImageName(for count: Int) -> String {
        let clampedCount = min(max(count, 0), 15)
        return "\(clampedCount)-stamps"
    }
}

#Preview {
    let sampleBusiness = Business(
        id: "sample",
        businessId: "sample",
        businessName: "Sample Coffee Shop",
        location: "123 Main St",
        category: "Food & Drink",
        logoUrl: "",
        description: "Great coffee",
        email: "contact@sample.com",
        phoneNumber: "555-1234",
        hours: "7AM-7PM",
        prizeOffered: "Free Coffee",
        stampsNeeded: 10,
        minimumPurchase: 5.0,
        accountType: "Business",
        createdAt: Date(),
        totalCustomers: 100,
        totalStampsGiven: 500,
        rewardsRedeemed: 50
    )
    
    let sampleProgram = CustomerProgram(
        id: "sample",
        claimed: false,
        currentStamps: 7,
        prizesClaimed: 0
    )
    
    let sampleProgramWithBusiness = ProgramWithBusiness(
        id: "sample",
        program: sampleProgram,
        business: sampleBusiness
    )
    
    return LoyaltyProgramCard(programWithBusiness: sampleProgramWithBusiness)
        .padding()
}
