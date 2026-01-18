//
//  RepairStageTracker.swift
//  ProTech
//
//  Visual pipeline tracker for the repair workflow.
//  Maps granular technical stages to high-level statuses.
//

import SwiftUI

// High-level phases for the tracker
enum RepairPhase: String, CaseIterable {
    case checkedIn = "Checked In"
    case diagnosing = "Diagnosing"
    case repairing = "Repairing"
    case testing = "Testing"
    case ready = "Ready"
    case pickedUp = "Picked Up"
    
    var icon: String {
        switch self {
        case .checkedIn: return "person.text.rectangle"
        case .diagnosing: return "stethoscope"
        case .repairing: return "wrench.and.screwdriver"
        case .testing: return "checkmark.shield"
        case .ready: return "shippingbox.fill"
        case .pickedUp: return "figure.wave"
        }
    }
}

struct RepairStageTracker: View {
    @Binding var currentStage: RepairStage?
    let ticketStatus: String
    
    // High-level phases for the tracker

    
    var currentPhase: RepairPhase {
        // If ticket is picked up, show that
        if ticketStatus == "picked_up" { return .pickedUp }
        if ticketStatus == "completed" { return .ready }
        
        guard let stage = currentStage else { return .checkedIn }
        
        // Map granular internal stages to high-level phases
        switch stage {
        case .diagnostic:
            return .diagnosing
        case .partsOrdering, .disassembly, .repair:
            return .repairing
        case .testing, .reassembly:
            return .testing
        case .qualityCheck, .cleanup:
            return .ready
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Progress Bar
            GeometryReader { geometry in
                let spacing: CGFloat = 4
                let totalSpacing = spacing * CGFloat(RepairPhase.allCases.count - 1)
                let width = (geometry.size.width - totalSpacing) / CGFloat(RepairPhase.allCases.count)
                
                HStack(spacing: spacing) {
                    ForEach(RepairPhase.allCases, id: \.self) { phase in
                        PhaseSegment(
                            phase: phase,
                            isActive: isActive(phase),
                            isCompleted: isCompleted(phase),
                            width: width
                        )
                    }
                }
            }
            .frame(height: 4)
            
            // Labels and current stage highlight
            HStack {
                Text(currentPhase.rawValue.uppercased())
                    .font(.caption)
                    .bold()
                    .foregroundColor(color(for: currentPhase))
                
                Spacer()
                
                if let stage = currentStage, ticketStatus == "in_progress" {
                    Text("Detailed: \(stage.displayName)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(Color.white)
    }
    
    private func isCompleted(_ phase: RepairPhase) -> Bool {
        let allPhases = RepairPhase.allCases
        guard let currentIndex = allPhases.firstIndex(of: currentPhase),
              let phaseIndex = allPhases.firstIndex(of: phase) else { return false }
        return phaseIndex < currentIndex
    }
    
    private func isActive(_ phase: RepairPhase) -> Bool {
        phase == currentPhase
    }
    
    private func color(for phase: RepairPhase) -> Color {
        switch phase {
        case .checkedIn: return .gray
        case .diagnosing: return .blue
        case .repairing: return .orange
        case .testing: return .purple
        case .ready: return .green
        case .pickedUp: return .gray
        }
    }
}

struct PhaseSegment: View {
    let phase: RepairPhase
    let isActive: Bool
    let isCompleted: Bool
    let width: CGFloat
    
    var body: some View {
        Rectangle()
            .fill(fillColor)
            .frame(width: width)
            .overlay(
                // Pulse effect if active
                Group {
                    if isActive {
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .blink()
                    }
                }
            )
    }
    
    var fillColor: Color {
        if isActive {
            switch phase {
            case .checkedIn: return .gray
            case .diagnosing: return .blue
            case .repairing: return .orange
            case .testing: return .purple
            case .ready: return .green
            case .pickedUp: return .gray
            }
        } else if isCompleted {
            return .green.opacity(0.5)
        } else {
            return .gray.opacity(0.2)
        }
    }
}

extension View {
    func blink() -> some View {
        modifier(BlinkModifier())
    }
}

struct BlinkModifier: ViewModifier {
    @State private var opacity = 0.0
    
    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).repeatForever()) {
                    opacity = 1.0
                }
            }
    }
}
