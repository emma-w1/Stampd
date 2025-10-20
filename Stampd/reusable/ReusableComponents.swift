//
//  ReusableComponents.swift
//  Stampd
//
//  Created by Adishree Das on 10/13/25.
//

import SwiftUI

// Reusable form field with label
struct StampdTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: UITextAutocapitalizationType = .sentences
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.custom("Jersey15-Regular", size: 26))
                .foregroundColor(Color.stampdTextPink)
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(autocapitalization == .none ? .never : .sentences)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.stampdTextPink, lineWidth: 2)
                )
        }
        .padding(.bottom, 8)
    }
}

// reusable business logo
struct BusinessLogoView: View {
    let logoUrl: String
    let size: CGFloat
    var cornerRadius: CGFloat = 8
    
    var body: some View {
        AsyncImage(url: URL(string: logoUrl)) { phase in
            switch phase {
            case .empty:
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: size, height: size)
                    .cornerRadius(cornerRadius)
                    .overlay(ProgressView())
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .cornerRadius(cornerRadius)
                    .clipped()
            case .failure:
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: size, height: size)
                    .cornerRadius(cornerRadius)
                    .overlay(
                        Image(systemName: "storefront")
                            .foregroundColor(.gray)
                            .font(.system(size: size * 0.4))
                    )
            @unknown default:
                EmptyView()
            }
        }
    }
}

// reusable section header
struct SectionHeader: View {
    let text: String
    var size: CGFloat = 36
    
    var body: some View {
        Text(text)
            .font(.custom("Jersey15-Regular", size: size))
            .foregroundColor(Color.stampdTextPink)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// reusable white info card
struct WhiteCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// reusable pink button
struct StampdButton: View {
    let text: String
    let action: () -> Void
    var isDisabled: Bool = false
    var isOutline: Bool = false
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.custom("Jersey15-Regular", size: 25))
                .foregroundColor(isOutline ? Color.stampdTextPink : Color.stampdTextWhite)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(isOutline ? Color.white : (isDisabled ? Color.stampdButtonPinkDisabled : Color.stampdButtonPink))
                .cornerRadius(12)
                .overlay(
                    isOutline ? RoundedRectangle(cornerRadius: 12).stroke(Color.stampdTextPink, lineWidth: 2) : nil
                )
                .shadow(color: isOutline ? .clear : Color.stampdButtonShadow, radius: 8, x: 0, y: 4)
        }
        .disabled(isDisabled)
    }
}

// numbered step component
struct NumberedStep: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.stampdTextPink)
                .clipShape(Circle())
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

