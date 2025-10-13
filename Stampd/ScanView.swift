//
//  ScanView.swift
//  Stampd
//
//  Created by Adishree Das on 10/13/25.
//

import SwiftUI

struct ScanView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.stampdGradientTop, Color.stampdGradientBottom]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack {
                // back button
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(Color.stampdTextPink)
                    }
                    .padding()
                    
                    Spacer()
                }
                
                Spacer()
                
                //in progress
                Text("QR Scanner")
                    .font(.custom("Jersey15-Regular", size: 42))
                    .foregroundColor(Color.stampdTextPink)
                
                Text("Coming soon!")
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
                    .padding()
                
                Spacer()
            }
        }
    }
}

#Preview {
    ScanView()
}

