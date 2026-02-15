//
//  DesignSystem.swift
//  Steady
//
//  Central design tokens for the Steady app
//

import SwiftUI

struct DesignSystem {
    // MARK: - Colors
    struct Colors {
        // Primary greens - muted sage palette
        static let primaryGreen = Color(hex: "6B9B7D")
        static let lightGreen = Color(hex: "A8C5B4")
        static let darkGreen = Color(hex: "4A7A5E")
        
        // Backgrounds - warm and earthy
        static let warmBackground = Color(light: "FAFAF7", dark: "1C1C1E")
        static let surface = Color(light: "F5F5F0", dark: "2C2C2E")
        
        // Text
        static let textPrimary = Color(hex: "2D3436")
        static let textSecondary = Color(hex: "636E72")
        
        // Accent - warm amber for streaks and highlights
        static let accentWarm = Color(hex: "D4A574")
        
        // Empty/inactive states
        static let emptyCells = Color(light: "F0EDE8", dark: "38383A")
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let sm: CGFloat = 4
        static let md: CGFloat = 8
        static let lg: CGFloat = 12
        static let xl: CGFloat = 16
        static let pill: CGFloat = 100
    }
    
    // MARK: - Shadows
    struct Shadow {
        static let subtle: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (
            Color.black.opacity(0.05),
            4,
            0,
            2
        )
        
        static let medium: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = (
            Color.black.opacity(0.1),
            8,
            0,
            4
        )
    }
    
    // MARK: - Animation
    struct Animation {
        static var spring: SwiftUI.Animation {
            .spring(response: 0.3, dampingFraction: 0.7)
        }
        
        static var gentle: SwiftUI.Animation {
            .easeOut(duration: 0.2)
        }
        
        static func respectingMotion(_ animation: SwiftUI.Animation) -> SwiftUI.Animation? {
            UIAccessibility.isReduceMotionEnabled ? nil : animation
        }
    }
}

// MARK: - Color Extensions
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    init(light: String, dark: String) {
        self.init(uiColor: UIColor(light: UIColor(Color(hex: light)), dark: UIColor(Color(hex: dark))))
    }
}

extension UIColor {
    convenience init(light: UIColor, dark: UIColor) {
        self.init { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? dark : light
        }
    }
}
