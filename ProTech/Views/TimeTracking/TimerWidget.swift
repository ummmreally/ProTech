//
//  TimerWidget.swift
//  ProTech
//
//  Floating timer widget for active time tracking
//

import SwiftUI

struct TimerWidget: View {
    @StateObject private var timeTrackingService = TimeTrackingService.shared
    @State private var showingTicketDetail = false
    
    var body: some View {
        if let entry = timeTrackingService.activeEntry {
            VStack(spacing: 0) {
                // Timer display
                HStack(spacing: 12) {
                    // Status indicator
                    Circle()
                        .fill(entry.isPaused ? Color.orange : Color.green)
                        .frame(width: 8, height: 8)
                    
                    // Time display
                    Text(formatTime(timeTrackingService.elapsedTime))
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Controls
                    HStack(spacing: 8) {
                        if entry.isPaused {
                            Button {
                                timeTrackingService.resumeTimer(entry)
                            } label: {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 14))
                            }
                            .buttonStyle(.plain)
                            .help("Resume timer")
                        } else {
                            Button {
                                timeTrackingService.pauseTimer(entry)
                            } label: {
                                Image(systemName: "pause.fill")
                                    .font(.system(size: 14))
                            }
                            .buttonStyle(.plain)
                            .help("Pause timer")
                        }
                        
                        Button {
                            timeTrackingService.stopTimer(entry)
                        } label: {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 14))
                        }
                        .buttonStyle(.plain)
                        .help("Stop timer")
                        
                        Button {
                            showingTicketDetail = true
                        } label: {
                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 14))
                        }
                        .buttonStyle(.plain)
                        .help("View ticket")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .glassCard()
            .padding()
        }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
}

// MARK: - Compact Timer Widget (for sidebar)

struct CompactTimerWidget: View {
    @StateObject private var timeTrackingService = TimeTrackingService.shared
    
    var body: some View {
        if let entry = timeTrackingService.activeEntry {
            HStack(spacing: 8) {
                Circle()
                    .fill(entry.isPaused ? Color.orange : Color.green)
                    .frame(width: 6, height: 6)
                
                Text(formatTime(timeTrackingService.elapsedTime))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                
                if entry.isPaused {
                    Button {
                        timeTrackingService.resumeTimer(entry)
                    } label: {
                        Image(systemName: "play.fill")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        timeTrackingService.pauseTimer(entry)
                    } label: {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                }
                
                Button {
                    timeTrackingService.stopTimer(entry)
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 10))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(AppTheme.Colors.primary.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
}

// MARK: - Timer Control Panel (for ticket detail)

struct TimerControlPanel: View {
    let ticket: Ticket
    @StateObject private var timeTrackingService = TimeTrackingService.shared
    @State private var showingManualEntry = false
    
    private var hasActiveTimer: Bool {
        if let entry = timeTrackingService.activeEntry {
            return entry.ticketId == ticket.id
        }
        return false
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Time Tracking")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    showingManualEntry = true
                } label: {
                    Label("Add Manual Entry", systemImage: "plus.circle")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }
            
            if hasActiveTimer, let entry = timeTrackingService.activeEntry {
                // Active timer display
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Active Timer")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(formatTime(timeTrackingService.elapsedTime))
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        if entry.isPaused {
                            Button {
                                timeTrackingService.resumeTimer(entry)
                            } label: {
                                Label("Resume", systemImage: "play.fill")
                            }
                            .buttonStyle(.borderedProminent)
                        } else {
                            Button {
                                timeTrackingService.pauseTimer(entry)
                            } label: {
                                Label("Pause", systemImage: "pause.fill")
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        Button {
                            timeTrackingService.stopTimer(entry)
                        } label: {
                            Label("Stop", systemImage: "stop.fill")
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .background(entry.isPaused ? Color.orange.opacity(0.1) : Color.green.opacity(0.1))
                .cornerRadius(12)
            } else {
                // Start timer button
                Button {
                    startTimer()
                } label: {
                    Label("Start Timer", systemImage: "timer")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PremiumButtonStyle(variant: .primary))
            }
            
            // Time summary
            let entries = timeTrackingService.getTimeEntries(for: ticket.id ?? UUID())
            let totalTime = timeTrackingService.getTotalTime(for: ticket.id ?? UUID())
            let billableTime = timeTrackingService.getBillableTime(for: ticket.id ?? UUID())
            
            if !entries.isEmpty {
                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatDuration(totalTime))
                            .font(.headline)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Billable")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatDuration(billableTime))
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Entries")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(entries.count)")
                            .font(.headline)
                    }
                }
                .padding()
                .glassCard()
            }
        }
        .sheet(isPresented: $showingManualEntry) {
            ManualTimeEntryView(ticket: ticket)
        }
    }
    
    private func startTimer() {
        guard let ticketId = ticket.id else { return }
        _ = timeTrackingService.startTimer(for: ticketId)
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Preview

struct TimerWidget_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            TimerWidget()
            CompactTimerWidget()
        }
        .frame(width: 300)
    }
}
