//
//  DashboardStatsCard.swift
//  ProTech
//
//  Enhanced dashboard statistics card
//

import SwiftUI

struct DashboardStatsCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let color: Color
    let trend: Trend?
    
    enum Trend {
        case up(String)
        case down(String)
        case neutral
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "minus"
            }
        }
        
        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .neutral: return .gray
            }
        }
        
        var text: String {
            switch self {
            case .up(let value): return value
            case .down(let value): return value
            case .neutral: return "No change"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Icon with Gradient Background
                ZStack {
                    gradientFor(color: color)
                        .frame(width: 44, height: 44)
                        .cornerRadius(12)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                if let trend = trend {
                    HStack(spacing: 4) {
                        Image(systemName: trend.icon)
                            .font(.caption.bold())
                        Text(trend.text)
                            .font(.caption.bold())
                    }
                    .foregroundColor(trend.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(trend.color.opacity(0.15))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(trend.color.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .glassCard()
    }
    
    private func gradientFor(color: Color) -> LinearGradient {
        // Create a matching gradient based on the input color
        // This is a simple approximation, ideally we'd map specific colors to specific gradients
        LinearGradient(
            colors: [color, color.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
