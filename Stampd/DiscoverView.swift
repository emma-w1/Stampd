//
//  DiscoverView.swift
//  Stampd
//
//  Created by Adishree Das on 10/11/25.
//

import SwiftUI

struct DiscoverView: View {
    var body: some View {
        ZStack {
                VStack(spacing: 20) {
                    
                }
                .padding(25)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.stampdGradientTop, Color.stampdGradientBottom]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
}

#Preview {
    DiscoverView()
}
