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
    
    // Fixed layout constants for consistency
    private let contentMaxWidth: CGFloat = 900
    private let cardSpacing: CGFloat = 20
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header - fixed height for consistency
                headerView
                    .frame(height: 80)
                    .frame(maxWidth: .infinity)
                    .background(Color(.windowBackgroundColor).opacity(0.5))
                
                Divider()
                
                // Main content
                if let employee = authService.currentEmployee, let employeeId = employee.id {
                    ScrollView {
                        mainContentGrid(employeeId: employeeId, containerWidth: geometry.size.width)
                            .frame(maxWidth: contentMaxWidth)
                            .frame(maxWidth: .infinity) // Center within container
                            .padding(.horizontal, AppTheme.Spacing.lg)
                            .padding(.vertical, cardSpacing)
                    }
                } else {
                    notLoggedInView
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        .onAppear {
            loadCurrentEntry()
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("Time Clock")
                    .font(AppTheme.Typography.largeTitle)
                    .fontWeight(.bold)
                
                if let employee = authService.currentEmployee {
                    Text(employee.fullName)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Current time - fixed width to prevent layout shifts
            Text(currentTime, style: .time)
                .font(.system(size: 32, weight: .medium, design: .rounded))
                .monospacedDigit()
                .frame(minWidth: 140, alignment: .trailing)
                .onReceive(timer) { _ in
                    currentTime = Date()
                }
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
    }
    
    // MARK: - Main Content Grid
    
    private func mainContentGrid(employeeId: UUID, containerWidth: CGFloat) -> some View {
        let useWideLayout = containerWidth > 700
        
        return VStack(spacing: cardSpacing) {
            // Top row: Clock status (always full width at top)
            clockStatusCard(employeeId: employeeId)
            
            // Actions row
            clockActionsCard(employeeId: employeeId)
            
            // Bottom row: Summary and Recent entries side by side on wide screens
            if useWideLayout {
                HStack(alignment: .top, spacing: cardSpacing) {
                    todaysSummaryCard(employeeId: employeeId)
                        .frame(minWidth: 0, maxWidth: .infinity)
                    
                    recentEntriesCard(employeeId: employeeId)
                        .frame(minWidth: 0, maxWidth: .infinity)
                }
            } else {
                // Stack vertically on narrow screens
                todaysSummaryCard(employeeId: employeeId)
                recentEntriesCard(employeeId: employeeId)
            }
        }
    }
    
    // MARK: - Clock Status Card
    
    private func clockStatusCard(employeeId: UUID) -> some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            if let entry = currentEntry, entry.isActive {
                // Currently clocked in
                VStack(spacing: AppTheme.Spacing.md) {
                    HStack {
                        Circle()
                            .fill(entry.onBreak ? Color.orange : Color.green)
                            .frame(width: 12, height: 12)
                            .shadow(color: (entry.onBreak ? Color.orange : Color.green).opacity(0.5), radius: 4)
                        
                        Text(entry.statusDisplay)
                            .font(AppTheme.Typography.headline)
                    }
                    
                    Text(entry.formattedDuration)
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(
                            LinearGradient(
                                colors: entry.onBreak ? [.orange, .red] : [.green, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Started at \(formatTime(entry.clockInTime))")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                // Not clocked in
                VStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: "clock.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    
                    Text("Not Clocked In")
                        .font(AppTheme.Typography.title2)
                        .fontWeight(.semibold)
                    
                    Text("Start your shift to begin tracking time")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.xxl)
        .glassCard()
        .onReceive(timer) { _ in
            if currentEntry?.isActive == true {
                // Force view update for live timer
                currentEntry = timeClockService.getActiveEntry(for: employeeId)
            }
        }
    }
    
    // MARK: - Clock Actions Card
    
    private func clockActionsCard(employeeId: UUID) -> some View {
        VStack(spacing: AppTheme.Spacing.md) {
            if let entry = currentEntry, entry.isActive {
                // Clocked in actions
                HStack(spacing: AppTheme.Spacing.md) {
                    if entry.onBreak {
                        Button(action: { endBreak(employeeId: employeeId) }) {
                            Label("End Break", systemImage: "play.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PremiumButtonStyle(variant: .success))
                    } else {
                        Button(action: { startBreak(employeeId: employeeId) }) {
                            Label("Start Break", systemImage: "pause.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PremiumButtonStyle(variant: .warning))
                    }
                    
                    Button(action: { clockOut(employeeId: employeeId) }) {
                        Label("Clock Out", systemImage: "stop.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PremiumButtonStyle(variant: .destructive))
                }
            } else {
                // Clock in action
                Button(action: { clockIn(employeeId: employeeId) }) {
                    Label("Clock In", systemImage: "play.fill")
                        .font(AppTheme.Typography.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PremiumButtonStyle(variant: .primary))
            }
        }
    }
    
    // MARK: - Today's Summary
    
    private func todaysSummaryCard(employeeId: UUID) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Today's Summary")
                .font(AppTheme.Typography.headline)
            
            let todaysEntries = timeClockService.fetchTodaysEntries(for: employeeId)
            let totalHours = todaysEntries.reduce(0.0) { $0 + $1.currentDuration }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Hours")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(.secondary)
                    Text(formatHours(totalHours))
                        .font(AppTheme.Typography.title3)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                if let employee = authService.currentEmployee {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Estimated Pay")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(.secondary)
                        Text(formatCurrency(Decimal(totalHours / 3600.0) * employee.hourlyRate.decimalValue))
                            .font(AppTheme.Typography.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                }
            }
            .padding(AppTheme.Spacing.lg)
            .background(Color.blue.opacity(0.05))
            .cornerRadius(AppTheme.cardCornerRadius)
        }
        .glassCard()
    }
    
    // MARK: - Recent Entries
    
    private func recentEntriesCard(employeeId: UUID) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Recent Entries")
                .font(AppTheme.Typography.headline)
            
            let entries = timeClockService.fetchEntriesForEmployee(employeeId).prefix(7)
            
            if entries.isEmpty {
                Text("No time clock entries yet")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(AppTheme.Spacing.xl)
            } else {
                ForEach(Array(entries)) { entry in
                    TimeClockEntryRow(entry: entry)
                }
            }
        }
        .glassCard()
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
                    .font(AppTheme.Typography.subheadline)
                    .fontWeight(.medium)
                
                Text("\(entry.formattedClockIn) - \(entry.formattedClockOut)")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(entry.formattedDuration)
                    .font(AppTheme.Typography.subheadline)
                    .fontWeight(.semibold)
                
                if entry.isActive {
                    Text(entry.statusDisplay)
                        .font(AppTheme.Typography.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(4)
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(Color.white.opacity(0.5))
        .cornerRadius(AppTheme.cardCornerRadius)
    }
}

#Preview {
    TimeClockView()
}
