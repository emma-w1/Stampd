//
//  AppColorExtensions.swift
//  Stampd
//
//  Created by Adishree Das on 9/27/25.
//

import SwiftUI

extension Color {
    // Primary brand colors
    static let stampdPink = Color.pink
    static let stampdPinkLight = Color.pink.opacity(0.2)
    static let stampdPinkDark = Color.pink.opacity(0.8)
    
    // Background colors
    static let stampdGradientTop = Color.pink.opacity(0.2)
    static let stampdGradientBottom = Color.gray.opacity(0.1)
    
    // Button colors
    static let stampdButtonPink = Color.pink
    static let stampdButtonPinkDisabled = Color.pink.opacity(0.7)
    static let stampdButtonShadow = Color.pink.opacity(0.4)
    
    // Text colors
    static let stampdTextPrimary = Color.primary
    static let stampdTextSecondary = Color.secondary
    static let stampdTextPink = Color.pink
    static let stampdTextWhite = Color.white
    
    // Card colors
    static let stampdCardBackground = Color(.systemGray6)
    static let stampdCardShadow = Color.black.opacity(0.05)
    
    // Action button colors
    static let stampdActionBlue = Color.blue
    static let stampdActionOrange = Color.orange
    static let stampdActionRed = Color.red
    static let stampdActionPurple = Color.purple
    static let stampdActionGreen = Color.green
}