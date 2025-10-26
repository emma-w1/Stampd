//
//  AnalyticsView.swift
//  Stampd
//
//  Created by Adishree Das on 10/20/25.
//

import SwiftUI
import FirebaseFirestore

enum TimePeriod: String, CaseIterable {
    case lastDay = "Last Day"
    case lastWeek = "Last Week" 
    case lastMonth = "Last Month"
    case lastYear = "Last Year"
}

struct ScanDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let prizeCount: Int
    let stampCount: Int
}

struct AnalyticsView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedTimePeriod: TimePeriod = .lastWeek
    @State private var scanData: [ScanDataPoint] = []
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.stampdGradientTop, Color.stampdGradientBottom]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                TopNavbar(showSearchIcon: true)
                VStack(spacing: 25){
                    Text("Rewards Over Time")
                        .font(.custom("Jersey15-Regular", size: 42))
                        .foregroundStyle(Color.stampdTextPink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // select the time period
                    VStack(spacing: 15) {
                        HStack {
                            Text("Time Period")
                                .font(.custom("Jersey15-Regular", size: 24))
                                .foregroundColor(.stampdTextPink)
                            
                            Spacer()
                        }
                        
                        HStack(spacing: 10) {
                            ForEach(TimePeriod.allCases, id: \.self) { period in
                                Button(action: {
                                    selectedTimePeriod = period
                                    loadScanData()
                                }) {
                                    Text(period.rawValue)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(selectedTimePeriod == period ? .white : .stampdTextPink)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            selectedTimePeriod == period ? 
                                            Color.stampdButtonPink : 
                                            Color.white.opacity(0.3)
                                        )
                                        .cornerRadius(20)
                                }
                            }
                        }
                    }
                    
                    // chart
                    if isLoading {
                        ProgressView("Loading analytics...")
                            .frame(height: 300)
                    } else if scanData.isEmpty {
                        VStack(spacing: 15) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            
                            Text("No data available for selected period")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }
                        .frame(height: 300)
                    } else {
                        InteractiveRewardsChart(data: scanData, timePeriod: selectedTimePeriod)
                            .frame(height: 300)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(15)
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                }
                .padding(25)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            loadScanData()
        }
    }
    
    func loadScanData() {
        guard let businessId = authManager.currentUser?.uid else {
            isLoading = false
            return
        }
        
        isLoading = true
        let db = Firestore.firestore()
        
        let endDate = Date()
        let startDate: Date
        
        switch selectedTimePeriod {
        case .lastDay:
            startDate = Calendar.current.date(byAdding: .day, value: -1, to: endDate) ?? endDate
        case .lastWeek:
            startDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: endDate) ?? endDate
        case .lastMonth:
            startDate = Calendar.current.date(byAdding: .month, value: -1, to: endDate) ?? endDate
        case .lastYear:
            startDate = Calendar.current.date(byAdding: .year, value: -1, to: endDate) ?? endDate
        }
        
        // Fetch real scan data from Firestore
        fetchRealScanData(businessId: businessId, startDate: startDate, endDate: endDate)
    }
    
    func fetchRealScanData(businessId: String, startDate: Date, endDate: Date) {
        let db = Firestore.firestore()
        
        // daily rewards
        db.collection("businesses")
            .document(businessId)
            .collection("dailyRewards")
            .whereField("date", isGreaterThanOrEqualTo: startDate)
            .whereField("date", isLessThanOrEqualTo: endDate)
            .order(by: "date")
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        self.scanData = []
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self.scanData = []
                        return
                    }
                                        
                    var data: [ScanDataPoint] = []
                    
                    for document in documents {
                        let data_dict = document.data()
                        let date = (data_dict["date"] as? Timestamp)?.dateValue() ?? Date()
                        let stampsGiven = data_dict["stampsGiven"] as? Int ?? 0
                        let prizesRedeemed = data_dict["prizesRedeemed"] as? Int ?? 0
                                                
                        data.append(ScanDataPoint(
                            date: date,
                            prizeCount: prizesRedeemed, // Actual prizes redeemed
                            stampCount: stampsGiven
                        ))
                    }
                                        
                    self.scanData = self.fillMissingDates(data: data, startDate: startDate, endDate: endDate)
                }
            }
    }
    
    func fillMissingDates(data: [ScanDataPoint], startDate: Date, endDate: Date) -> [ScanDataPoint] {
        let calendar = Calendar.current
        var result: [ScanDataPoint] = []
        
        var currentDate = startDate
        while currentDate <= endDate {
            let existingData = data.first { calendar.isDate($0.date, inSameDayAs: currentDate) }
            
            if let existing = existingData {
                result.append(existing)
            } else {
                result.append(ScanDataPoint(
                    date: currentDate,
                    prizeCount: 0,
                    stampCount: 0
                ))
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return result
    }
}

// interactive chart
struct InteractiveRewardsChart: View {
    let data: [ScanDataPoint]
    let timePeriod: TimePeriod
    @State private var selectedDataPoint: ScanDataPoint?
    
    var displayData: [ScanDataPoint] {
        let maxPoints = 15
        if data.count <= maxPoints {
            return data
        }
        
        let step = data.count / maxPoints
        var sampled: [ScanDataPoint] = []
        for i in stride(from: 0, to: data.count, by: step) {
            sampled.append(data[i])
        }
        if let last = data.last, sampled.last?.id != last.id {
            sampled.append(last)
        }
        return sampled
    }
    
    var body: some View {
        VStack(spacing: 15) {
            // title
            HStack {
                Text("Rewards Given")
                    .font(.custom("Jersey15-Regular", size: 18))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let selected = selectedDataPoint {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(formatDate(selected.date))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Text("Stamps: \(selected.stampCount)")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                        Text("Prizes: \(selected.prizeCount)")
                            .font(.system(size: 10))
                            .foregroundColor(.stampdButtonPink)
                    }
                }
            }
            
            // chart area w axes
            HStack(spacing: 0) {
                VStack(alignment: .trailing, spacing: 0) {
                    let maxValue = max(displayData.map { $0.prizeCount }.max() ?? 1, displayData.map { $0.stampCount }.max() ?? 1)
                    let roundedMax = ((maxValue + 4) / 5) * 5 // Round up to nearest 5
                    
                    ForEach((0...5).reversed(), id: \.self) { i in
                        let value = CGFloat(i) * CGFloat(roundedMax) / 5
                        Text("\(Int(value))")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                            .frame(height: 32.5)
                    }
                }
                .frame(width: 30)
                .padding(.trailing, 8)
                
                VStack(spacing: 0) {
                    GeometryReader { geometry in
                        ZStack {
                            ChartGrid(maxValue: max(displayData.map { $0.prizeCount }.max() ?? 1, displayData.map { $0.stampCount }.max() ?? 1))
                            LineChart(data: displayData, selectedPoint: $selectedDataPoint)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(height: 200)
                    
                    HStack(spacing: 0) {
                        ForEach(Array(displayData.enumerated()), id: \.element.id) { index, point in
                            let labelCount = min(4, displayData.count)
                            let step = max(1, displayData.count / labelCount)
                            
                            if index % step == 0 || index == displayData.count - 1 {
                                Text(formatDate(point.date))
                                    .font(.system(size: 8))
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: true, vertical: false)
                                    .frame(maxWidth: .infinity)
                            } else {
                                Spacer()
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .frame(height: 25)
                    .padding(.leading, 8)
                    .clipped()
                }
            }
            
            // legend
            HStack(spacing: 30) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.stampdButtonPink)
                        .frame(width: 8, height: 8)
                    Text("Prizes Redeemed")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                    Text("Stamps Given")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        switch timePeriod {
        case .lastDay:
            formatter.dateFormat = "HH:mm"
        case .lastWeek:
            formatter.dateFormat = "MMM dd"
        case .lastMonth, .lastYear:
            formatter.dateFormat = "MMM dd"
        }
        return formatter.string(from: date)
    }
}

// grid
struct ChartGrid: View {
    let maxValue: Int
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<6, id: \.self) { i in
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 1)
                }
                .frame(maxHeight: .infinity)
            }
        }
    }
}

// line chart
struct LineChart: View {
    let data: [ScanDataPoint]
    @Binding var selectedPoint: ScanDataPoint?
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let maxPrizes = data.map { $0.prizeCount }.max() ?? 1
            let maxStamps = data.map { $0.stampCount }.max() ?? 1
            let maxValue = max(maxPrizes, maxStamps, 1)
            let roundedMax = ((maxValue + 4) / 5) * 5
            
            ZStack {
                // prizes line
                Path { path in
                    for (index, point) in data.enumerated() {
                        let x = CGFloat(index) * (width / CGFloat(max(data.count - 1, 1)))
                        let y = height - (CGFloat(point.prizeCount) / CGFloat(roundedMax)) * height
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color.stampdButtonPink, lineWidth: 3)
                
                // stamps line
                Path { path in
                    for (index, point) in data.enumerated() {
                        let x = CGFloat(index) * (width / CGFloat(max(data.count - 1, 1)))
                        let y = height - (CGFloat(point.stampCount) / CGFloat(roundedMax)) * height
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color.orange, lineWidth: 3)
                
                // prize points
                ForEach(Array(data.enumerated()), id: \.element.id) { index, point in
                    let x = CGFloat(index) * (width / CGFloat(max(data.count - 1, 1)))
                    let y = height - (CGFloat(point.prizeCount) / CGFloat(roundedMax)) * height
                    
                    Circle()
                        .fill(selectedPoint?.id == point.id ? Color.stampdButtonPink : Color.white)
                        .frame(width: 5, height: 5)
                        .overlay(
                            Circle()
                                .stroke(Color.stampdButtonPink, lineWidth: 1.5)
                        )
                        .position(x: x, y: y)
                        .onTapGesture {
                            selectedPoint = point
                        }
                }
                
                // stamp points
                ForEach(Array(data.enumerated()), id: \.element.id) { index, point in
                    let x = CGFloat(index) * (width / CGFloat(max(data.count - 1, 1)))
                    let y = height - (CGFloat(point.stampCount) / CGFloat(roundedMax)) * height
                    
                    Circle()
                        .fill(selectedPoint?.id == point.id ? Color.orange : Color.white)
                        .frame(width: 5, height: 5)
                        .overlay(
                            Circle()
                                .stroke(Color.orange, lineWidth: 1.5)
                        )
                        .position(x: x, y: y)
                        .onTapGesture {
                            selectedPoint = point
                        }
                }
            }
        }
    }
}

// stats
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.custom("Jersey15-Regular", size: 20))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(10)
    }
}

#Preview {
    AnalyticsView()
        .environmentObject(AuthManager())
}
