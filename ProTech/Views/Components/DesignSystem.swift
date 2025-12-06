//
//  DesignSystem.swift
//  ProTech
//
//  Premium Design System for macOS
//

import SwiftUI

// MARK: - App Theme
struct AppTheme {
    static let cornerRadius: CGFloat = 16
    static let cardCornerRadius: CGFloat = 12
    static let buttonCornerRadius: CGFloat = 10
    static let padding: CGFloat = 20
    static let shadowRadius: CGFloat = 8
    
    // MARK: - Spacing System
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
    }
    
    // MARK: - Typography
    struct Typography {
        // Titles
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .bold, design: .rounded)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
        
        // Body
        static let headline = Font.system(size: 17, weight: .semibold, design: .default)
        static let body = Font.system(size: 17, weight: .regular, design: .default)
        static let callout = Font.system(size: 16, weight: .regular, design: .default)
        static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
        static let footnote = Font.system(size: 13, weight: .regular, design: .default)
        static let caption = Font.system(size: 12, weight: .regular, design: .default)
        static let caption2 = Font.system(size: 11, weight: .regular, design: .default)
    }
    
    // MARK: - Colors
    struct Colors {
        static let primary = Color("AccentColor") // Assumes Asset Catalog has AccentColor
        static let secondary = Color.secondary
        static let background = Color(nsColor: .windowBackgroundColor)
        
        // Semantic Colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue
        
        // Theme-aware backgrounds
        static let cardBackground = Color(nsColor: .controlBackgroundColor)
        static let groupedBackground = Color(nsColor: .windowBackgroundColor)
        
        // Gradients - Primary
        static let primaryGradient = LinearGradient(
            colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let successGradient = LinearGradient(
            colors: [Color.green.opacity(0.8), Color.mint.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let warningGradient = LinearGradient(
            colors: [Color.orange.opacity(0.8), Color.yellow.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let errorGradient = LinearGradient(
            colors: [Color.red.opacity(0.8), Color.pink.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Chart Gradients
        static let chartBlue = LinearGradient(
            colors: [Color.blue, Color.blue.opacity(0.6)],
            startPoint: .top,
            endPoint: .bottom
        )
        
        static let chartPurple = LinearGradient(
            colors: [Color.purple, Color.purple.opacity(0.6)],
            startPoint: .top,
            endPoint: .bottom
        )
        
        static let chartGreen = LinearGradient(
            colors: [Color.green, Color.green.opacity(0.6)],
            startPoint: .top,
            endPoint: .bottom
        )
        
        static let chartGradient1 = LinearGradient(colors: [Color(hex: "667eea"), Color(hex: "764ba2")], startPoint: .topLeading, endPoint: .bottomTrailing)
        static let chartGradient2 = LinearGradient(colors: [Color(hex: "f093fb"), Color(hex: "f5576c")], startPoint: .topLeading, endPoint: .bottomTrailing)
        static let chartGradient3 = LinearGradient(colors: [Color(hex: "4facfe"), Color(hex: "00f2fe")], startPoint: .topLeading, endPoint: .bottomTrailing)
        
        // Customer Portal Gradients
        static let portalWelcome = LinearGradient(
            colors: [Color(hex: "a855f7"), Color(hex: "ec4899")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let portalSuccess = LinearGradient(
            colors: [Color(hex: "10b981"), Color(hex: "34d399")],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // MARK: - Animation
    struct Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
    }
}

// MARK: - View Modifiers

struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppTheme.padding)
            .background(.ultraThinMaterial)
            .cornerRadius(AppTheme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: AppTheme.shadowRadius, x: 0, y: 4)
    }
}

struct PremiumCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppTheme.padding)
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(AppTheme.cardCornerRadius)
            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
            )
    }
}

struct SectionHeaderModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTheme.Typography.headline)
            .foregroundColor(.primary)
            .padding(.bottom, AppTheme.Spacing.sm)
    }
}

struct PremiumButtonStyle: ButtonStyle {
    var variant: Variant = .primary
    
    enum Variant {
        case primary
        case secondary
        case destructive
        case success
        case warning
    }
    
    func makeBody(configuration: ButtonStyle.Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(backgroundFor(variant: variant, isPressed: configuration.isPressed))
            .foregroundColor(.white)
            .cornerRadius(AppTheme.buttonCornerRadius)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(AppTheme.Animation.quick, value: configuration.isPressed)
    }
    
    @ViewBuilder
    private func backgroundFor(variant: Variant, isPressed: Bool) -> some View {
        Group {
            switch variant {
            case .primary:
                AppTheme.Colors.primaryGradient
            case .secondary:
                Color.gray.opacity(0.5)
            case .destructive:
                AppTheme.Colors.errorGradient
            case .success:
                AppTheme.Colors.successGradient
            case .warning:
                LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }
        .opacity(isPressed ? 0.8 : 1.0)
    }
}

struct OutlinedButtonStyle: ButtonStyle {
    var color: Color = .blue
    
    func makeBody(configuration: ButtonStyle.Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(color.opacity(configuration.isPressed ? 0.1 : 0.05))
            .foregroundColor(color)
            .cornerRadius(AppTheme.buttonCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius)
                    .stroke(color, lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(AppTheme.Animation.quick, value: configuration.isPressed)
    }
}

struct GhostButtonStyle: ButtonStyle {
    var color: Color = .blue
    
    func makeBody(configuration: ButtonStyle.Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(configuration.isPressed ? 0.15 : 0))
            .foregroundColor(color)
            .cornerRadius(AppTheme.buttonCornerRadius)
            .animation(AppTheme.Animation.quick, value: configuration.isPressed)
    }
}

struct LinkButtonStyle: ButtonStyle {
    var color: Color = .blue
    
    func makeBody(configuration: ButtonStyle.Configuration) -> some View {
        configuration.label
            .foregroundColor(color)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(AppTheme.Animation.quick, value: configuration.isPressed)
    }
}

// MARK: - Extensions

extension View {
    func glassCard() -> some View {
        modifier(GlassCardModifier())
    }
    
    func premiumCard() -> some View {
        modifier(PremiumCardModifier())
    }
    
    func sectionHeader() -> some View {
        modifier(SectionHeaderModifier())
    }
}
