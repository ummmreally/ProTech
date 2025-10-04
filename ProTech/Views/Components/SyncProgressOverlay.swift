//
//  SyncProgressOverlay.swift
//  ProTech
//
//  Prominent loading overlay for sync operations
//

import SwiftUI

struct SyncProgressOverlay: View {
    let progress: Double
    let currentOperation: String?
    let status: SyncManagerStatus
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            // Progress card
            VStack(spacing: 24) {
                // Animated sync icon
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(status == .syncing ? 360 : 0))
                        .animation(
                            status == .syncing ?
                            Animation.linear(duration: 2.0).repeatForever(autoreverses: false) :
                            .default,
                            value: status
                        )
                }
                
                VStack(spacing: 12) {
                    // Status text
                    Text("Syncing...")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    // Current operation
                    if let operation = currentOperation {
                        Text(operation)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    
                    // Progress bar
                    VStack(spacing: 8) {
                        ProgressView(value: progress)
                            .progressViewStyle(.linear)
                            .tint(.blue)
                            .frame(width: 250)
                        
                        HStack {
                            Text("\(Int(progress * 100))% Complete")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            // Estimated time (optional)
                            if progress > 0.1 && progress < 0.95 {
                                Text(estimatedTimeRemaining(progress: progress))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(width: 250)
                    }
                }
                
                // Cancel hint (optional)
                Text("Please wait while syncing completes")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(NSColor.windowBackgroundColor))
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
        }
    }
    
    private func estimatedTimeRemaining(progress: Double) -> String {
        guard progress > 0 else { return "" }
        
        // Simple estimation based on progress
        let remainingProgress = 1.0 - progress
        let estimatedSeconds = Int((remainingProgress / progress) * 10) // Rough estimate
        
        if estimatedSeconds < 60 {
            return "~\(estimatedSeconds)s remaining"
        } else {
            let minutes = estimatedSeconds / 60
            return "~\(minutes)m remaining"
        }
    }
}

// MARK: - Compact Version for In-Line Use

struct SyncProgressBar: View {
    let progress: Double
    let currentOperation: String?
    let showPercentage: Bool
    
    init(progress: Double, currentOperation: String? = nil, showPercentage: Bool = true) {
        self.progress = progress
        self.currentOperation = currentOperation
        self.showPercentage = showPercentage
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.blue)
                    .symbolEffect(.rotate, options: .repeat(.continuous))
                
                if let operation = currentOperation {
                    Text(operation)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else {
                    Text("Syncing...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if showPercentage {
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
            }
            
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(.blue)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(10)
    }
}

// MARK: - Preview

#Preview("Overlay") {
    ZStack {
        Color.gray.opacity(0.2)
        
        SyncProgressOverlay(
            progress: 0.65,
            currentOperation: "Importing customers from Square...",
            status: .syncing
        )
    }
}

#Preview("Progress Bar") {
    VStack(spacing: 20) {
        SyncProgressBar(
            progress: 0.35,
            currentOperation: "Fetching items from Square..."
        )
        
        SyncProgressBar(
            progress: 0.75,
            currentOperation: "Updating inventory counts..."
        )
        
        SyncProgressBar(
            progress: 0.95,
            currentOperation: nil
        )
    }
    .padding()
}
