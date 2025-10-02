//
//  TimeClockView.swift
//  ProTech
//
//  Employee time clock interface
//

import SwiftUI

struct TimeClockView: View {
    @StateObject private var timeClockService = TimeClockService()
    @StateObject private var authService = AuthenticationService.shared
    
    @State private var currentEntry: TimeClockEntry?
    @State private var currentTime = Date()
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Time Clock")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    if let employee = authService.currentEmployee {
                        Text(employee.fullName)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Current time
                Text(currentTime, style: .time)
                    .font(.title)
                    .fontWeight(.medium)
                    .onReceive(timer) { _ in
                        currentTime = Date()
                    }
            }
            .padding()
            
            Divider()
            
            // Main content
            if let employee = authService.currentEmployee, let employeeId = employee.id {
                ScrollView {
                    VStack(spacing: 20) {
                        // Clock status card
                        clockStatusCard(employeeId: employeeId)
                        
                        // Quick actions
                        clockActionsCard(employeeId: employeeId)
                        
                        // Today's summary
                        todaysSummaryCard(employeeId: employeeId)
                        
                        // Recent entries
                        recentEntriesCard(employeeId: employeeId)
                    }
                    .padding()
                }
            } else {
                notLoggedInView
            }
        }
        .onAppear {
            loadCurrentEntry()
        }
    }
    
    // MARK: - Clock Status Card
    
    private func clockStatusCard(employeeId: UUID) -> some View {
        VStack(spacing: 20) {
            if let entry = currentEntry, entry.isActive {
                // Currently clocked in
                VStack(spacing: 10) {
                    HStack {
                        Circle()
                            .fill(entry.onBreak ? Color.orange : Color.green)
                            .frame(width: 12, height: 12)
                        
                        Text(entry.statusDisplay)
                            .font(.headline)
                    }
                    
                    Text(entry.formattedDuration)
                        .font(.system(size: 48, weight: .bold))
                        .monospacedDigit()
                    
                    Text("Started at \(formatTime(entry.clockInTime))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                // Not clocked in
                VStack(spacing: 10) {
                    Image(systemName: "clock")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text("Not Clocked In")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Start your shift to begin tracking time")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(30)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(16)
        .onReceive(timer) { _ in
            if currentEntry?.isActive == true {
                // Force view update for live timer
                currentEntry = timeClockService.getActiveEntry(for: employeeId)
            }
        }
    }
    
    // MARK: - Clock Actions Card
    
    private func clockActionsCard(employeeId: UUID) -> some View {
        VStack(spacing: 15) {
            if let entry = currentEntry, entry.isActive {
                // Clocked in actions
                HStack(spacing: 15) {
                    if entry.onBreak {
                        Button(action: { endBreak(employeeId: employeeId) }) {
                            Label("End Break", systemImage: "play.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    } else {
                        Button(action: { startBreak(employeeId: employeeId) }) {
                            Label("Start Break", systemImage: "pause.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    
                    Button(action: { clockOut(employeeId: employeeId) }) {
                        Label("Clock Out", systemImage: "stop.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
            } else {
                // Clock in action
                Button(action: { clockIn(employeeId: employeeId) }) {
                    Label("Clock In", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - Today's Summary
    
    private func todaysSummaryCard(employeeId: UUID) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Today's Summary")
                .font(.headline)
            
            let todaysEntries = timeClockService.fetchTodaysEntries(for: employeeId)
            let totalHours = todaysEntries.reduce(0.0) { $0 + $1.currentDuration }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Total Hours")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatHours(totalHours))
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                if let employee = authService.currentEmployee {
                    VStack(alignment: .trailing) {
                        Text("Estimated Pay")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatCurrency(Decimal(totalHours / 3600.0) * employee.hourlyRate.decimalValue))
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                }
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Recent Entries
    
    private func recentEntriesCard(employeeId: UUID) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Recent Entries")
                .font(.headline)
            
            let entries = timeClockService.fetchEntriesForEmployee(employeeId).prefix(7)
            
            if entries.isEmpty {
                Text("No time clock entries yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(Array(entries)) { entry in
                    TimeClockEntryRow(entry: entry)
                }
            }
        }
    }
    
    // MARK: - Not Logged In View
    
    private var notLoggedInView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Please Log In")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("You need to be logged in to use the time clock")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Actions
    
    private func clockIn(employeeId: UUID) {
        do {
            currentEntry = try timeClockService.clockIn(employeeId: employeeId)
        } catch {
            showErrorMessage(error.localizedDescription)
        }
    }
    
    private func clockOut(employeeId: UUID) {
        do {
            currentEntry = try timeClockService.clockOut(employeeId: employeeId)
            loadCurrentEntry() // Refresh to show not clocked in
        } catch {
            showErrorMessage(error.localizedDescription)
        }
    }
    
    private func startBreak(employeeId: UUID) {
        do {
            currentEntry = try timeClockService.startBreak(employeeId: employeeId)
        } catch {
            showErrorMessage(error.localizedDescription)
        }
    }
    
    private func endBreak(employeeId: UUID) {
        do {
            currentEntry = try timeClockService.endBreak(employeeId: employeeId)
        } catch {
            showErrorMessage(error.localizedDescription)
        }
    }
    
    private func loadCurrentEntry() {
        guard let employeeId = authService.currentEmployeeId else { return }
        currentEntry = timeClockService.getActiveEntry(for: employeeId)
    }
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showError = false
        }
    }
    
    // MARK: - Formatters
    
    private func formatTime(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatHours(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        return String(format: "%d:%02d", hours, minutes)
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
}

// MARK: - Time Clock Entry Row
struct TimeClockEntryRow: View {
    let entry: TimeClockEntry
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.formattedShiftDate)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(entry.formattedClockIn) - \(entry.formattedClockOut)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(entry.formattedDuration)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                if entry.isActive {
                    Text(entry.statusDisplay)
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    TimeClockView()
}
