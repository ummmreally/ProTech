//
//  TimeEntriesView.swift
//  ProTech
//
//  View and manage time entries
//

import SwiftUI

struct TimeEntriesView: View {
    @State private var timeEntries: [TimeEntry] = []
    @State private var searchText = ""
    @State private var filterOption: FilterOption = .all
    @State private var selectedEntry: TimeEntry?
    @State private var showingEditEntry = false
    @State private var showingManualEntry = false
    
    private let timeTrackingService = TimeTrackingService.shared
    private let coreDataManager = CoreDataManager.shared
    
    enum FilterOption: String, CaseIterable {
        case all = "All"
        case billable = "Billable"
        case nonBillable = "Non-Billable"
        case running = "Active"
    }
    
    var filteredEntries: [TimeEntry] {
        var filtered = timeEntries
        
        switch filterOption {
        case .all:
            break
        case .billable:
            filtered = filtered.filter { $0.isBillable }
        case .nonBillable:
            filtered = filtered.filter { !$0.isBillable }
        case .running:
            filtered = filtered.filter { $0.isRunning }
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter { entry in
                entry.notes?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerView
                
                Divider()
                
                // Filter bar
                filterBar
                
                Divider()
                
                // Time entries list
                if filteredEntries.isEmpty {
                    emptyStateView
                } else {
                    timeEntriesListView
                }
            }
            .onAppear {
                loadTimeEntries()
            }
            .sheet(isPresented: $showingManualEntry) {
                ManualTimeEntryView(ticket: nil)
                    .onDisappear {
                        loadTimeEntries()
                    }
            }
            .sheet(item: $selectedEntry) { entry in
                EditTimeEntryView(entry: entry)
                    .onDisappear {
                        loadTimeEntries()
                    }
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("Time Entries")
                    .font(AppTheme.Typography.largeTitle)
                    .fontWeight(.bold)
                
                Text("\(filteredEntries.count) entr\(filteredEntries.count == 1 ? "y" : "ies")")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Statistics
            statisticsView
            
            Spacer()
            
            Button {
                showingManualEntry = true
            } label: {
                Label("Add Entry", systemImage: "plus.circle.fill")
                    .font(AppTheme.Typography.headline)
            }
            .buttonStyle(PremiumButtonStyle(variant: .primary))
        }
        .padding(AppTheme.Spacing.lg)
    }
    
    private var statisticsView: some View {
        let totalHours = filteredEntries.reduce(0.0) { $0 + $1.duration / 3600.0 }
        let billableHours = filteredEntries.filter { $0.isBillable }.reduce(0.0) { $0 + $1.duration / 3600.0 }
        let totalRevenue = filteredEntries.reduce(Decimal.zero) { $0 + $1.billableAmount }
        
        return HStack(spacing: AppTheme.Spacing.md) {
            TimeTrackingStatCard(
                title: "Total Hours",
                value: String(format: "%.1fh", totalHours),
                color: .blue
            )
            
            TimeTrackingStatCard(
                title: "Billable",
                value: String(format: "%.1fh", billableHours),
                color: .green
            )
            
            TimeTrackingStatCard(
                title: "Revenue",
                value: formatCurrency(totalRevenue),
                color: .purple
            )
        }
    }
    
    // MARK: - Filter Bar
    
    private var filterBar: some View {
        HStack {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search notes...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
            .frame(maxWidth: 400)
            
            Spacer()
            
            // Filter
            Picker("Filter", selection: $filterOption) {
                ForEach(FilterOption.allCases, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 400)
        }
        .padding(AppTheme.Spacing.md)
        .glassCard()
        .padding(.horizontal, AppTheme.Spacing.lg)
    }
    
    // MARK: - Time Entries List
    
    private var timeEntriesListView: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.md) {
                ForEach(filteredEntries, id: \.id) { entry in
                    TimeEntryRow(entry: entry)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedEntry = entry
                        }
                        .contextMenu {
                            entryContextMenu(for: entry)
                        }
                }
            }
            .padding(AppTheme.Spacing.lg)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "timer")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Time Entries")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start tracking time on tickets or add manual entries")
                .foregroundColor(.secondary)
            
            Button {
                showingManualEntry = true
            } label: {
                Label("Add Manual Entry", systemImage: "plus.circle.fill")
                    .font(AppTheme.Typography.headline)
            }
            .buttonStyle(PremiumButtonStyle(variant: .primary))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Context Menu
    
    @ViewBuilder
    private func entryContextMenu(for entry: TimeEntry) -> some View {
        Button {
            selectedEntry = entry
        } label: {
            Label("Edit", systemImage: "pencil")
        }
        
        if entry.isRunning {
            if entry.isPaused {
                Button {
                    timeTrackingService.resumeTimer(entry)
                    loadTimeEntries()
                } label: {
                    Label("Resume", systemImage: "play.fill")
                }
            } else {
                Button {
                    timeTrackingService.pauseTimer(entry)
                    loadTimeEntries()
                } label: {
                    Label("Pause", systemImage: "pause.fill")
                }
            }
            
            Button {
                timeTrackingService.stopTimer(entry)
                loadTimeEntries()
            } label: {
                Label("Stop", systemImage: "stop.fill")
            }
        }
        
        Button(role: .destructive) {
            timeTrackingService.deleteTimeEntry(entry)
            loadTimeEntries()
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    
    // MARK: - Actions
    
    private func loadTimeEntries() {
        let request = TimeEntry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        timeEntries = (try? coreDataManager.viewContext.fetch(request)) ?? []
    }
    
    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: value as NSDecimalNumber) ?? "$0.00"
    }
}

// MARK: - Time Entry Row

struct TimeEntryRow: View {
    let entry: TimeEntry
    @StateObject private var timeTrackingService = TimeTrackingService.shared
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Status indicator
            Image(systemName: statusIcon)
                .font(.title2)
                .foregroundColor(statusColor)
                .frame(width: 40)
            
            // Entry details
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(entry.isRunning ? entry.formattedDuration : entry.formattedDurationHoursMinutes)
                        .font(AppTheme.Typography.headline)
                    
                    if entry.isBillable {
                        Text("• \(entry.formattedBillableAmount)")
                            .font(AppTheme.Typography.subheadline)
                            .foregroundColor(.green)
                    }
                }
                
                if let startTime = entry.startTime {
                    Text(startTime.formatted(date: .abbreviated, time: .shortened))
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let notes = entry.notes, !notes.isEmpty {
                    Text(notes)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Badges
            VStack(alignment: .trailing, spacing: 4) {
                if entry.isRunning {
                    Text(entry.statusDisplay)
                        .font(AppTheme.Typography.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(entry.isPaused ? Color.orange : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
                
                if entry.isBillable {
                    Text("BILLABLE")
                        .font(AppTheme.Typography.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(4)
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .glassCard()
    }
    
    private var statusIcon: String {
        if entry.isRunning {
            return entry.isPaused ? "pause.circle.fill" : "play.circle.fill"
        }
        return "checkmark.circle.fill"
    }
    
    private var statusColor: Color {
        if entry.isRunning {
            return entry.isPaused ? .orange : .green
        }
        return .blue
    }
}

struct TimeTrackingStatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(AppTheme.Typography.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding(12)
        .glassCard()
    }
}

// MARK: - Manual Time Entry View

struct ManualTimeEntryView: View {
    @Environment(\.dismiss) var dismiss
    
    let ticket: Ticket?
    
    @State private var selectedTicket: Ticket?
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var notes = ""
    @State private var isBillable = true
    @State private var hourlyRate = "75.00"
    @State private var showingTicketPicker = false
    
    private let timeTrackingService = TimeTrackingService.shared
    
    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Ticket") {
                    if let ticket = ticket ?? selectedTicket {
                        HStack {
                            Text("Ticket #\(ticket.ticketNumber)")
                            Spacer()
                            if self.ticket == nil {
                                Button("Change") {
                                    showingTicketPicker = true
                                }
                            }
                        }
                    } else {
                        Button("Select Ticket") {
                            showingTicketPicker = true
                        }
                    }
                }
                
                Section("Time") {
                    DatePicker("Start Time", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                    
                    DatePicker("End Time", selection: $endDate, in: startDate..., displayedComponents: [.date, .hourAndMinute])
                    
                    LabeledContent("Duration") {
                        Text(formatDuration(duration))
                            .font(.headline)
                    }
                }
                
                Section("Billing") {
                    Toggle("Billable", isOn: $isBillable)
                    
                    if isBillable {
                        HStack {
                            Text("Hourly Rate")
                            Spacer()
                            TextField("75.00", text: $hourlyRate)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        if let rate = Decimal(string: hourlyRate) {
                            let hours = Decimal(duration / 3600.0)
                            let amount = hours * rate
                            LabeledContent("Amount") {
                                Text(formatCurrency(amount))
                                    .font(.headline)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 80)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Manual Time Entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEntry()
                    }
                    .disabled(!isValid)
                }
            }
        }
        .frame(width: 600, height: 550)
        .onAppear {
            if ticket != nil {
                selectedTicket = ticket
            }
        }
    }
    
    private var isValid: Bool {
        return (ticket != nil || selectedTicket != nil) && endDate > startDate
    }
    
    private func saveEntry() {
        guard let ticketId = ticket?.id ?? selectedTicket?.id else { return }
        
        let rate = Decimal(string: hourlyRate) ?? 75.00
        
        _ = timeTrackingService.createManualEntry(
            ticketId: ticketId,
            startTime: startDate,
            endTime: endDate,
            notes: notes.isEmpty ? nil : notes,
            isBillable: isBillable,
            hourlyRate: rate
        )
        
        dismiss()
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
    
    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: value as NSDecimalNumber) ?? "$0.00"
    }
}

// MARK: - Edit Time Entry View

struct EditTimeEntryView: View {
    @Environment(\.dismiss) var dismiss
    
    let entry: TimeEntry
    
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var notes: String
    @State private var isBillable: Bool
    @State private var hourlyRate: String
    
    private let timeTrackingService = TimeTrackingService.shared
    
    init(entry: TimeEntry) {
        self.entry = entry
        _startDate = State(initialValue: entry.startTime ?? Date())
        _endDate = State(initialValue: entry.endTime ?? Date())
        _notes = State(initialValue: entry.notes ?? "")
        _isBillable = State(initialValue: entry.isBillable)
        _hourlyRate = State(initialValue: String(describing: entry.hourlyRate))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if !entry.isRunning {
                    Section("Time") {
                        DatePicker("Start Time", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                        
                        DatePicker("End Time", selection: $endDate, in: startDate..., displayedComponents: [.date, .hourAndMinute])
                        
                        LabeledContent("Duration") {
                            Text(entry.formattedDurationHoursMinutes)
                                .font(.headline)
                        }
                    }
                } else {
                    Section("Time") {
                        LabeledContent("Status", value: entry.statusDisplay)
                        LabeledContent("Duration", value: entry.formattedDuration)
                    }
                }
                
                Section("Billing") {
                    Toggle("Billable", isOn: $isBillable)
                    
                    if isBillable {
                        HStack {
                            Text("Hourly Rate")
                            Spacer()
                            TextField("75.00", text: $hourlyRate)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 80)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Edit Time Entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                }
            }
        }
        .frame(width: 600, height: 500)
    }
    
    private func saveChanges() {
        let rate = Decimal(string: hourlyRate) ?? entry.hourlyRate
        
        timeTrackingService.updateTimeEntry(
            entry,
            startTime: entry.isRunning ? nil : startDate,
            endTime: entry.isRunning ? nil : endDate,
            notes: notes.isEmpty ? nil : notes,
            isBillable: isBillable,
            hourlyRate: rate
        )
        
        dismiss()
    }
}
