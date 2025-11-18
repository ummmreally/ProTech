//
//  AttendanceView.swift
//  ProTech
//
//  Comprehensive attendance system with PIN clock-in and time management
//

import SwiftUI

struct AttendanceView: View {
    @State private var selectedView: AttendanceViewType = .editTimeCards
    
    enum AttendanceViewType {
        case editTimeCards
        case timeOffRequests
        case attendanceReports
    }
    
    var body: some View {
        HSplitView {
            // Left Panel - Clock In/Out
            PINClockView()
                .frame(minWidth: 400, idealWidth: 450, maxWidth: 500)
            
            // Right Panel - Management Tools
            VStack(spacing: 0) {
                // Tab selector
                Picker("View", selection: $selectedView) {
                    Label("Edit Time Cards", systemImage: "pencil.circle").tag(AttendanceViewType.editTimeCards)
                    Label("Time Off", systemImage: "calendar.badge.clock").tag(AttendanceViewType.timeOffRequests)
                    Label("Reports", systemImage: "chart.bar").tag(AttendanceViewType.attendanceReports)
                }
                .pickerStyle(.segmented)
                .padding()
                
                Divider()
                
                // Content area
                Group {
                    switch selectedView {
                    case .editTimeCards:
                        EditTimeCardsView()
                    case .timeOffRequests:
                        TimeOffRequestsView()
                    case .attendanceReports:
                        AttendanceReportsView()
                    }
                }
            }
            .frame(minWidth: 600)
        }
    }
}

// MARK: - PIN Clock In/Out View

struct PINClockView: View {
    @StateObject private var timeClockService = TimeClockService()
    @State private var pinEntry = ""
    @State private var currentTime = Date()
    @State private var activeEmployee: Employee?
    @State private var currentEntry: TimeClockEntry?
    @State private var showMessage = false
    @State private var messageText = ""
    @State private var messageType: MessageType = .success
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    enum MessageType {
        case success, error, info
        
        var color: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            case .info: return .blue
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("Time Clock")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(currentTime, style: .time)
                    .font(.system(size: 48, weight: .medium))
                    .monospacedDigit()
                    .onReceive(timer) { _ in
                        currentTime = Date()
                        // Update active entry if exists
                        if let employee = activeEmployee, let employeeId = employee.id {
                            currentEntry = timeClockService.getActiveEntry(for: employeeId)
                        }
                    }
                
                Text(currentTime.formatted(date: .complete, time: .omitted))
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 30)
            .padding(.bottom, 20)
            
            Divider()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Status Display
                    if let employee = activeEmployee, let entry = currentEntry, entry.isActive {
                        activeStatusCard(employee: employee, entry: entry)
                    } else {
                        readyToClockInCard
                    }
                    
                    // PIN Entry
                    pinEntrySection
                    
                    // Quick Actions
                    if let employee = activeEmployee, let entry = currentEntry, entry.isActive {
                        quickActionsSection(employee: employee, entry: entry)
                    }
                    
                    // Message Display
                    if showMessage {
                        messageCard
                    }
                }
                .padding()
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Active Status Card
    
    private func activeStatusCard(employee: Employee, entry: TimeClockEntry) -> some View {
        VStack(spacing: 16) {
            Circle()
                .fill(entry.onBreak ? Color.orange.gradient : Color.green.gradient)
                .frame(width: 80, height: 80)
                .overlay {
                    Image(systemName: entry.onBreak ? "pause.circle.fill" : "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
            
            Text(employee.fullName)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(entry.onBreak ? "ON BREAK" : "CLOCKED IN")
                .font(.headline)
                .foregroundColor(entry.onBreak ? .orange : .green)
            
            Text(entry.formattedDuration)
                .font(.system(size: 36, weight: .semibold))
                .monospacedDigit()
            
            Text("Started at \(formatTime(entry.clockInTime))")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(16)
    }
    
    // MARK: - Ready to Clock In Card
    
    private var readyToClockInCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.checkmark")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Ready to Clock In")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Enter your PIN below")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(30)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(16)
    }
    
    // MARK: - PIN Entry Section
    
    private var pinEntrySection: some View {
        VStack(spacing: 16) {
            Text("Enter Your PIN")
                .font(.headline)
            
            // PIN Display
            HStack(spacing: 12) {
                ForEach(0..<6, id: \.self) { index in
                    Circle()
                        .fill(index < pinEntry.count ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 16, height: 16)
                }
            }
            .padding(.vertical, 8)
            
            // Number Pad
            VStack(spacing: 12) {
                ForEach(0..<3) { row in
                    HStack(spacing: 12) {
                        ForEach(1..<4) { col in
                            let number = row * 3 + col
                            Button {
                                addDigit(String(number))
                            } label: {
                                Text("\(number)")
                                    .font(.title)
                                    .fontWeight(.semibold)
                                    .frame(width: 70, height: 70)
                                    .background(Color(NSColor.controlBackgroundColor))
                                    .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                HStack(spacing: 12) {
                    Button {
                        clearPIN()
                    } label: {
                        Image(systemName: "delete.left")
                            .font(.title2)
                            .frame(width: 70, height: 70)
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        addDigit("0")
                    } label: {
                        Text("0")
                            .font(.title)
                            .fontWeight(.semibold)
                            .frame(width: 70, height: 70)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        submitPIN()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.title2)
                            .frame(width: 70, height: 70)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(16)
    }
    
    // MARK: - Quick Actions Section
    
    private func quickActionsSection(employee: Employee, entry: TimeClockEntry) -> some View {
        VStack(spacing: 12) {
            if entry.onBreak {
                Button {
                    endBreak(employee: employee)
                } label: {
                    Label("End Break", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    startBreak(employee: employee)
                } label: {
                    Label("Start Break", systemImage: "pause.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
            
            Button {
                clockOut(employee: employee)
            } label: {
                Label("Clock Out", systemImage: "xmark.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Message Card
    
    private var messageCard: some View {
        HStack {
            Image(systemName: messageType == .success ? "checkmark.circle.fill" : 
                            messageType == .error ? "xmark.circle.fill" : "info.circle.fill")
                .foregroundColor(messageType.color)
            Text(messageText)
                .font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(messageType.color.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Actions
    
    private func addDigit(_ digit: String) {
        guard pinEntry.count < 6 else { return }
        pinEntry += digit
        
        // Auto-submit on 4 or 6 digits
        if pinEntry.count == 4 || pinEntry.count == 6 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                submitPIN()
            }
        }
    }
    
    private func clearPIN() {
        pinEntry = ""
        showMessage = false
    }
    
    private func submitPIN() {
        guard !pinEntry.isEmpty else { return }
        
        let context = CoreDataManager.shared.viewContext
        guard let employee = Employee.fetchEmployeeByPIN(pinEntry, context: context) else {
            showErrorMessage("Invalid PIN. Please try again.")
            pinEntry = ""
            return
        }
        
        guard let employeeId = employee.id else { return }
        
        // Check if already clocked in
        if let activeEntry = timeClockService.getActiveEntry(for: employeeId) {
            activeEmployee = employee
            currentEntry = activeEntry
            showSuccessMessage("Welcome back, \(employee.firstName ?? "")!")
            pinEntry = ""
        } else {
            // Clock in
            do {
                currentEntry = try timeClockService.clockIn(employeeId: employeeId)
                activeEmployee = employee
                showSuccessMessage("Clocked in successfully!")
                pinEntry = ""
            } catch {
                showErrorMessage("Failed to clock in: \(error.localizedDescription)")
                pinEntry = ""
            }
        }
    }
    
    private func startBreak(employee: Employee) {
        guard let employeeId = employee.id else { return }
        do {
            currentEntry = try timeClockService.startBreak(employeeId: employeeId)
            showInfoMessage("Break started")
        } catch {
            showErrorMessage(error.localizedDescription)
        }
    }
    
    private func endBreak(employee: Employee) {
        guard let employeeId = employee.id else { return }
        do {
            currentEntry = try timeClockService.endBreak(employeeId: employeeId)
            showInfoMessage("Break ended")
        } catch {
            showErrorMessage(error.localizedDescription)
        }
    }
    
    private func clockOut(employee: Employee) {
        guard let employeeId = employee.id else { return }
        do {
            _ = try timeClockService.clockOut(employeeId: employeeId)
            showSuccessMessage("Clocked out successfully!")
            activeEmployee = nil
            currentEntry = nil
        } catch {
            showErrorMessage(error.localizedDescription)
        }
    }
    
    // MARK: - Helper Methods
    
    private func showSuccessMessage(_ message: String) {
        messageText = message
        messageType = .success
        showMessage = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showMessage = false
        }
    }
    
    private func showErrorMessage(_ message: String) {
        messageText = message
        messageType = .error
        showMessage = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showMessage = false
        }
    }
    
    private func showInfoMessage(_ message: String) {
        messageText = message
        messageType = .info
        showMessage = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showMessage = false
        }
    }
    
    private func formatTime(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Edit Time Cards View

struct EditTimeCardsView: View {
    @StateObject private var timeClockService = TimeClockService()
    @EnvironmentObject var authService: AuthenticationService
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Employee.firstName, ascending: true)],
        predicate: NSPredicate(format: "isActive == true")
    ) var employees: FetchedResults<Employee>
    
    @State private var selectedEmployee: Employee?
    @State private var selectedDateRange: DateRange = .thisWeek
    @State private var customStartDate = Calendar.current.startOfDay(for: Date())
    @State private var customEndDate = Date()
    @State private var entries: [TimeClockEntry] = []
    @State private var editingEntry: TimeClockEntry?
    
    enum DateRange: String, CaseIterable {
        case today = "Today"
        case thisWeek = "This Week"
        case lastWeek = "Last Week"
        case thisMonth = "This Month"
        case custom = "Custom"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Edit Time Cards")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Review and edit employee time entries")
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            
            Divider()
            
            // Filters
            VStack(spacing: 12) {
                HStack {
                    Picker("Employee", selection: $selectedEmployee) {
                        Text("All Employees").tag(nil as Employee?)
                        ForEach(employees, id: \.id) { employee in
                            Text(employee.fullName).tag(employee as Employee?)
                        }
                    }
                    .frame(width: 200)
                    
                    Picker("Period", selection: $selectedDateRange) {
                        ForEach(DateRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 400)
                }
                
                // Custom date range pickers
                if selectedDateRange == .custom {
                    HStack(spacing: 16) {
                        DatePicker("From:", selection: $customStartDate, displayedComponents: [.date])
                            .labelsHidden()
                            .datePickerStyle(.compact)
                        
                        Image(systemName: "arrow.right")
                            .foregroundColor(.secondary)
                        
                        DatePicker("To:", selection: $customEndDate, in: customStartDate..., displayedComponents: [.date])
                            .labelsHidden()
                            .datePickerStyle(.compact)
                        
                        Text("(\(daysBetween(customStartDate, customEndDate)) days)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding()
            .animation(.easeInOut(duration: 0.2), value: selectedDateRange)
            
            Divider()
            
            // Time entries list
            if entries.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(entries) { entry in
                            TimeCardRow(entry: entry, onEdit: {
                                editingEntry = entry
                            })
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(item: $editingEntry) { entry in
            EditTimeCardSheet(entry: entry)
        }
        .onChange(of: selectedEmployee) { _, _ in loadEntries() }
        .onChange(of: selectedDateRange) { _, _ in loadEntries() }
        .onChange(of: customStartDate) { _, _ in
            if selectedDateRange == .custom {
                loadEntries()
            }
        }
        .onChange(of: customEndDate) { _, _ in
            if selectedDateRange == .custom {
                loadEntries()
            }
        }
        .onAppear { loadEntries() }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("No time entries found")
                .font(.headline)
            Text("Select a different period or employee")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func loadEntries() {
        let (startDate, endDate) = getDateRange()
        
        if let employee = selectedEmployee, let employeeId = employee.id {
            entries = timeClockService.fetchEntries(for: employeeId, from: startDate, to: endDate)
        } else {
            entries = timeClockService.fetchAllEntries(from: startDate, to: endDate)
        }
    }
    
    private func daysBetween(_ start: Date, _ end: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: calendar.startOfDay(for: start), to: calendar.startOfDay(for: end))
        return (components.day ?? 0) + 1
    }
    
    private func getDateRange() -> (Date, Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedDateRange {
        case .today:
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            return (start, end)
        case .thisWeek:
            let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            let end = calendar.date(byAdding: .day, value: 7, to: start)!
            return (start, end)
        case .lastWeek:
            let thisWeekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            let start = calendar.date(byAdding: .day, value: -7, to: thisWeekStart)!
            return (start, thisWeekStart)
        case .thisMonth:
            let start = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let end = calendar.date(byAdding: .month, value: 1, to: start)!
            return (start, end)
        case .custom:
            let start = calendar.startOfDay(for: customStartDate)
            let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: customEndDate))!
            return (start, end)
        }
    }
}

// MARK: - Time Card Row

struct TimeCardRow: View {
    let entry: TimeClockEntry
    let onEdit: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                if let employeeName = entry.employeeName {
                    Text(employeeName)
                        .font(.headline)
                }
                
                Text(entry.formattedShiftDate)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    Label(entry.formattedClockIn, systemImage: "arrow.right.circle")
                    Label(entry.formattedClockOut, systemImage: "arrow.left.circle")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                Text(entry.formattedDuration)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                if entry.wasEdited {
                    Label("Edited", systemImage: "pencil.circle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                if entry.isActive {
                    Text(entry.statusDisplay)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(6)
                }
            }
            
            Button {
                onEdit()
            } label: {
                Image(systemName: "pencil.circle")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Edit Time Card Sheet

struct EditTimeCardSheet: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var timeClockService = TimeClockService()
    
    let entry: TimeClockEntry
    
    @State private var clockInTime: Date
    @State private var clockOutTime: Date?
    @State private var notes: String
    
    init(entry: TimeClockEntry) {
        self.entry = entry
        _clockInTime = State(initialValue: entry.clockInTime ?? Date())
        _clockOutTime = State(initialValue: entry.clockOutTime)
        _notes = State(initialValue: entry.editNotes ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Employee") {
                    Text(entry.employeeName ?? "Unknown")
                        .font(.headline)
                }
                
                Section("Time") {
                    DatePicker("Clock In", selection: $clockInTime, displayedComponents: [.date, .hourAndMinute])
                    
                    if entry.clockOutTime != nil || !entry.isActive {
                        DatePicker("Clock Out", selection: Binding(
                            get: { clockOutTime ?? Date() },
                            set: { clockOutTime = $0 }
                        ), in: clockInTime..., displayedComponents: [.date, .hourAndMinute])
                    }
                    
                    if let endTime = clockOutTime {
                        LabeledContent("Duration") {
                            Text(formatDuration(endTime.timeIntervalSince(clockInTime)))
                                .font(.headline)
                        }
                    }
                }
                
                Section("Admin Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 80)
                    Text("Document reason for edit (required)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if entry.wasEdited {
                    Section("Edit History") {
                        if let editedBy = entry.editedBy {
                            LabeledContent("Last Edited By", value: editedBy)
                        }
                        if let editedAt = entry.editedAt {
                            LabeledContent("Last Edit", value: editedAt.formatted(date: .abbreviated, time: .shortened))
                        }
                        if let previousNotes = entry.editNotes, !previousNotes.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Previous Notes:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(previousNotes)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Edit Time Card")
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
                    .disabled(notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .frame(width: 500, height: 500)
    }
    
    private func saveChanges() {
        timeClockService.editTimeEntry(
            entry,
            clockInTime: clockInTime,
            clockOutTime: clockOutTime,
            notes: notes
        )
        dismiss()
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        return String(format: "%d:%02d", hours, minutes)
    }
}

// MARK: - Time Off Requests View

struct TimeOffRequestsView: View {
    @EnvironmentObject var authService: AuthenticationService
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TimeOffRequest.requestedAt, ascending: false)]
    ) var allRequests: FetchedResults<TimeOffRequest>
    
    @State private var showingNewRequest = false
    @State private var selectedFilter: RequestFilter = .all
    @State private var reviewingRequest: TimeOffRequest?
    
    enum RequestFilter: String, CaseIterable {
        case all = "All"
        case pending = "Pending"
        case approved = "Approved"
        case denied = "Denied"
    }
    
    var filteredRequests: [TimeOffRequest] {
        var filtered = Array(allRequests)
        
        switch selectedFilter {
        case .all:
            break
        case .pending:
            filtered = filtered.filter { $0.status == TimeOffStatus.pending.rawValue }
        case .approved:
            filtered = filtered.filter { $0.status == TimeOffStatus.approved.rawValue }
        case .denied:
            filtered = filtered.filter { $0.status == TimeOffStatus.denied.rawValue }
        }
        
        return filtered
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Time Off Requests")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("\(filteredRequests.count) request\(filteredRequests.count == 1 ? "" : "s")")
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    showingNewRequest = true
                } label: {
                    Label("New Request", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            Divider()
            
            // Filter
            Picker("Filter", selection: $selectedFilter) {
                ForEach(RequestFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            Divider()
            
            // Requests list
            if filteredRequests.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredRequests, id: \.id) { request in
                            TimeOffRequestRow(request: request, onReview: {
                                reviewingRequest = request
                            })
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingNewRequest) {
            NewTimeOffRequestView()
        }
        .sheet(item: $reviewingRequest) { request in
            ReviewTimeOffRequestView(request: request)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("No time off requests")
                .font(.headline)
            Text("Tap the + button to create a new request")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct TimeOffRequestRow: View {
    let request: TimeOffRequest
    let onReview: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(request.statusEnum.color.gradient)
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: request.typeEnum.icon)
                        .font(.title3)
                        .foregroundColor(.white)
                }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(request.employeeName ?? "Unknown")
                        .font(.headline)
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(request.typeEnum.rawValue)
                        .foregroundColor(.secondary)
                }
                
                if let start = request.startDate, let end = request.endDate {
                    Text("\(start.formatted(date: .abbreviated, time: .omitted)) - \(end.formatted(date: .abbreviated, time: .omitted))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text("\(Int(request.totalDays)) business day\(Int(request.totalDays) == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: request.statusEnum.icon)
                    Text(request.statusEnum.displayName)
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(request.statusEnum.color.opacity(0.2))
                .foregroundColor(request.statusEnum.color)
                .cornerRadius(6)
                
                if request.status == TimeOffStatus.pending.rawValue {
                    Button {
                        onReview()
                    } label: {
                        Text("Review")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct NewTimeOffRequestView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthenticationService
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var requestType: TimeOffType = .pto
    @State private var reason = ""
    
    var totalDays: Double {
        TimeOffRequest.calculateBusinessDays(from: startDate, to: endDate)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Date Range") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: [.date])
                    DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: [.date])
                    
                    LabeledContent("Business Days") {
                        Text("\(Int(totalDays))")
                            .font(.headline)
                    }
                }
                
                Section("Request Type") {
                    Picker("Type", selection: $requestType) {
                        ForEach(TimeOffType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon).tag(type)
                        }
                    }
                }
                
                Section("Reason (Optional)") {
                    TextEditor(text: $reason)
                        .frame(height: 80)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Request Time Off")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        submitRequest()
                    }
                }
            }
        }
        .frame(width: 500, height: 450)
    }
    
    private func submitRequest() {
        guard let employeeId = authService.currentEmployeeId else { return }
        
        let context = CoreDataManager.shared.viewContext
        _ = TimeOffRequest(
            context: context,
            employeeId: employeeId,
            startDate: startDate,
            endDate: endDate,
            requestType: requestType,
            reason: reason
        )
        
        try? context.save()
        dismiss()
    }
}

struct ReviewTimeOffRequestView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthenticationService
    
    let request: TimeOffRequest
    @State private var reviewNotes = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Employee") {
                    Text(request.employeeName ?? "Unknown")
                        .font(.headline)
                }
                
                Section("Request Details") {
                    LabeledContent("Type", value: request.typeEnum.rawValue)
                    if let start = request.startDate {
                        LabeledContent("Start Date", value: start.formatted(date: .long, time: .omitted))
                    }
                    if let end = request.endDate {
                        LabeledContent("End Date", value: end.formatted(date: .long, time: .omitted))
                    }
                    LabeledContent("Business Days", value: "\(Int(request.totalDays))")
                }
                
                if let reason = request.reason, !reason.isEmpty {
                    Section("Reason") {
                        Text(reason)
                    }
                }
                
                Section("Admin Notes") {
                    TextEditor(text: $reviewNotes)
                        .frame(height: 80)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Review Request")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .automatic) {
                    Button("Deny", role: .destructive) {
                        reviewRequest(approved: false)
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Approve") {
                        reviewRequest(approved: true)
                    }
                    .tint(.green)
                }
            }
        }
        .frame(width: 500, height: 500)
    }
    
    private func reviewRequest(approved: Bool) {
        request.status = approved ? TimeOffStatus.approved.rawValue : TimeOffStatus.denied.rawValue
        request.reviewedAt = Date()
        request.reviewedBy = authService.currentEmployeeName
        request.reviewNotes = reviewNotes.isEmpty ? nil : reviewNotes
        request.updatedAt = Date()
        
        try? CoreDataManager.shared.viewContext.save()
        dismiss()
    }
}

// MARK: - Attendance Reports View

struct AttendanceReportsView: View {
    @StateObject private var timeClockService = TimeClockService()
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Employee.firstName, ascending: true)],
        predicate: NSPredicate(format: "isActive == true")
    ) var employees: FetchedResults<Employee>
    
    @State private var selectedPeriod: ReportPeriod = .thisWeek
    @State private var selectedEmployee: Employee?
    
    enum ReportPeriod: String, CaseIterable {
        case today = "Today"
        case thisWeek = "This Week"
        case lastWeek = "Last Week"
        case thisMonth = "This Month"
        case lastMonth = "Last Month"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Attendance Reports")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Analytics and insights")
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            
            Divider()
            
            // Filters
            HStack {
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(ReportPeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 500)
                
                Spacer()
                
                Picker("Employee", selection: $selectedEmployee) {
                    Text("All Employees").tag(nil as Employee?)
                    ForEach(employees, id: \.id) { employee in
                        Text(employee.fullName).tag(employee as Employee?)
                    }
                }
                .frame(width: 250)
            }
            .padding()
            
            Divider()
            
            // Analytics Dashboard
            ScrollView {
                VStack(spacing: 20) {
                    // Summary Cards
                    HStack(spacing: 16) {
                        AnalyticCard(
                            title: "Total Hours",
                            value: formatHours(getTotalHours()),
                            icon: "clock.fill",
                            color: .blue
                        )
                        
                        AnalyticCard(
                            title: "Late Arrivals",
                            value: "\(getLateArrivals())",
                            icon: "exclamationmark.triangle.fill",
                            color: .orange
                        )
                        
                        AnalyticCard(
                            title: "Overtime",
                            value: formatHours(getOvertimeHours()),
                            icon: "clock.badge.plus.fill",
                            color: .purple
                        )
                        
                        AnalyticCard(
                            title: "Attendance Rate",
                            value: "\(Int(getAttendanceRate()))%",
                            icon: "chart.line.uptrend.xyaxis",
                            color: .green
                        )
                    }
                    
                    // Details List
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Detailed Breakdown")
                                .font(.headline)
                            
                            ForEach(getEmployeeAnalytics(), id: \.employee.id) { analytics in
                                EmployeeAnalyticsRow(analytics: analytics)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
        }
    }
    
    private func getTotalHours() -> TimeInterval {
        let (start, end) = getDateRange()
        if let employee = selectedEmployee, let employeeId = employee.id {
            return timeClockService.getTotalHoursForEmployee(employeeId, from: start, to: end)
        } else {
            return employees.reduce(0.0) { total, emp in
                guard let empId = emp.id else { return total }
                return total + timeClockService.getTotalHoursForEmployee(empId, from: start, to: end)
            }
        }
    }
    
    private func getLateArrivals() -> Int {
        let (start, end) = getDateRange()
        let context = CoreDataManager.shared.viewContext
        let entries: [TimeClockEntry]
        
        if let employee = selectedEmployee, let employeeId = employee.id {
            entries = timeClockService.fetchEntries(for: employeeId, from: start, to: end)
        } else {
            entries = timeClockService.fetchAllEntries(from: start, to: end)
        }
        
        return entries.filter { entry in
            guard let clockIn = entry.clockInTime,
                  let employeeId = entry.employeeId else { return false }
            
            let calendar = Calendar.current
            let dayOfWeek = calendar.component(.weekday, from: clockIn)
            
            if let schedule = EmployeeSchedule.fetchScheduleForDay(employeeId, dayOfWeek: dayOfWeek, context: context),
               let scheduledStart = schedule.scheduledStartTime {
                let clockInTime = calendar.dateComponents([.hour, .minute], from: clockIn)
                let scheduledTime = calendar.dateComponents([.hour, .minute], from: scheduledStart)
                
                if let clockInMinutes = clockInTime.hour.map({ $0 * 60 + (clockInTime.minute ?? 0) }),
                   let scheduledMinutes = scheduledTime.hour.map({ $0 * 60 + (scheduledTime.minute ?? 0) }) {
                    return clockInMinutes > scheduledMinutes + 5
                }
            }
            
            return false
        }.count
    }
    
    private func getOvertimeHours() -> TimeInterval {
        let (start, end) = getDateRange()
        let context = CoreDataManager.shared.viewContext
        let entries: [TimeClockEntry]
        
        if let employee = selectedEmployee, let employeeId = employee.id {
            entries = timeClockService.fetchEntries(for: employeeId, from: start, to: end)
        } else {
            entries = timeClockService.fetchAllEntries(from: start, to: end)
        }
        
        var totalOvertime: TimeInterval = 0
        
        for entry in entries where !entry.isActive {
            guard let employeeId = entry.employeeId,
                  let clockIn = entry.clockInTime else { continue }
            
            let calendar = Calendar.current
            let dayOfWeek = calendar.component(.weekday, from: clockIn)
            
            if let schedule = EmployeeSchedule.fetchScheduleForDay(employeeId, dayOfWeek: dayOfWeek, context: context) {
                let scheduledHours = schedule.scheduledHours * 3600
                if entry.totalHours > scheduledHours {
                    totalOvertime += entry.totalHours - scheduledHours
                }
            }
        }
        
        return totalOvertime
    }
    
    private func getAttendanceRate() -> Double {
        return 95.0
    }
    
    private func getEmployeeAnalytics() -> [EmployeeAnalytics] {
        var analytics: [EmployeeAnalytics] = []
        
        let employeesToAnalyze = selectedEmployee != nil ? [selectedEmployee!] : Array(employees)
        
        for employee in employeesToAnalyze {
            guard let employeeId = employee.id else { continue }
            let (start, end) = getDateRange()
            let totalHours = timeClockService.getTotalHoursForEmployee(employeeId, from: start, to: end)
            
            analytics.append(EmployeeAnalytics(
                employee: employee,
                totalHours: totalHours,
                lateCount: 0,
                overtimeHours: 0
            ))
        }
        
        return analytics
    }
    
    private func getDateRange() -> (Date, Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedPeriod {
        case .today:
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            return (start, end)
        case .thisWeek:
            let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            let end = calendar.date(byAdding: .day, value: 7, to: start)!
            return (start, end)
        case .lastWeek:
            let thisWeekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            let start = calendar.date(byAdding: .day, value: -7, to: thisWeekStart)!
            return (start, thisWeekStart)
        case .thisMonth:
            let start = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let end = calendar.date(byAdding: .month, value: 1, to: start)!
            return (start, end)
        case .lastMonth:
            let thisMonthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let start = calendar.date(byAdding: .month, value: -1, to: thisMonthStart)!
            return (start, thisMonthStart)
        }
    }
    
    private func formatHours(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        return String(format: "%d:%02d", hours, minutes)
    }
}

struct AnalyticCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct EmployeeAnalytics {
    let employee: Employee
    let totalHours: TimeInterval
    let lateCount: Int
    let overtimeHours: TimeInterval
}

struct EmployeeAnalyticsRow: View {
    let analytics: EmployeeAnalytics
    
    var body: some View {
        HStack {
            Text(analytics.employee.fullName)
                .font(.subheadline)
            
            Spacer()
            
            HStack(spacing: 20) {
                VStack(alignment: .trailing) {
                    Text("Hours")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(formatHours(analytics.totalHours))
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                
                VStack(alignment: .trailing) {
                    Text("Late")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(analytics.lateCount)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(analytics.lateCount > 0 ? .orange : .green)
                }
                
                VStack(alignment: .trailing) {
                    Text("OT")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(formatHours(analytics.overtimeHours))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatHours(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        return String(format: "%d:%02d", hours, minutes)
    }
}

#Preview {
    AttendanceView()
        .environmentObject(AuthenticationService.shared)
}
