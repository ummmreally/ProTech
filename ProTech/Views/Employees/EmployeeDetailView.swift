//
//  EmployeeDetailView.swift
//  ProTech
//
//  Employee detail and edit view
//

import SwiftUI

struct EmployeeDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var employee: Employee
    @ObservedObject var employeeService: EmployeeService
    @StateObject private var timeClockService = TimeClockService()
    
    var onUpdate: () -> Void
    
    @State private var isEditing = false
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var role: EmployeeRole = .technician
    @State private var hourlyRate = ""
    @State private var showDeactivateAlert = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    @State private var timeClockEntries: [TimeClockEntry] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(employee.fullName)
                        .font(AppTheme.Typography.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(employee.displayRole)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !isEditing {
                    Button("Edit") {
                        startEditing()
                    }
                    .disabled(!AuthenticationService.shared.hasPermission(.manageEmployees))
                    .buttonStyle(PremiumButtonStyle(variant: .secondary))
                }
                
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(PremiumButtonStyle(variant: .secondary))
            }
            .padding(AppTheme.Spacing.lg)
            
            Divider()
            
            if isEditing {
                editFormView
            } else {
                detailView
            }
        }
        .frame(width: 700, height: 600)
        .onAppear {
            loadTimeClockEntries()
        }
    }
    
    // MARK: - Detail View
    
    private var detailView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                // Profile section
                profileSection
                
                // Employment info
                employmentSection
                
                // Time clock summary
                timeClockSection
                
                // Actions
                actionsSection
            }
            .padding(AppTheme.Spacing.lg)
            .onAppear {
                loadTimeClockEntries()
            }
        }
    }
    
    private var profileSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Profile Information")
                .font(AppTheme.Typography.headline)
            
            InfoRow(label: "Name", value: employee.fullName)
            InfoRow(label: "Email", value: employee.email ?? "N/A")
            InfoRow(label: "Phone", value: employee.phone ?? "N/A")
            InfoRow(label: "Employee #", value: employee.employeeNumber ?? "N/A")
            
            HStack {
                Text("Status:")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(.secondary)
                Spacer()
                HStack {
                    Circle()
                    .fill(employee.isActive ? AppTheme.Colors.success : AppTheme.Colors.error)
                        .frame(width: 8, height: 8)
                    Text(employee.isActive ? "Active" : "Inactive")
                        .font(AppTheme.Typography.body)
                        .fontWeight(.medium)
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .glassCard()
    }
    
    private var employmentSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Employment Details")
                .font(AppTheme.Typography.headline)
            
            InfoRow(label: "Role", value: employee.displayRole)
            InfoRow(label: "Hourly Rate", value: employee.formattedHourlyRate)
            
            if let hireDate = employee.hireDate {
                InfoRow(label: "Hire Date", value: formatDate(hireDate))
            }
            
            if let lastLogin = employee.lastLoginAt {
                InfoRow(label: "Last Login", value: formatDateTime(lastLogin))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Permissions:")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(.secondary)
                
                ForEach(employee.roleType.permissions, id: \.self) { permission in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text(permission.rawValue)
                            .font(AppTheme.Typography.caption)
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .glassCard()
    }
    
    private var timeClockSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Time Clock Summary")
                .font(AppTheme.Typography.headline)
            
            if let employeeId = employee.id {
                let thisWeekHours = timeClockService.getTotalHoursThisWeek(for: employeeId)
                let thisMonthHours = timeClockService.getTotalHoursThisMonth(for: employeeId)
                
                InfoRow(label: "This Week", value: formatHours(thisWeekHours))
                InfoRow(label: "This Month", value: formatHours(thisMonthHours))
                
                // Recent entries
                if !timeClockEntries.isEmpty {
                    Text("Recent Clock Entries")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    
                    ForEach(timeClockEntries.prefix(5)) { entry in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.formattedShiftDate)
                                    .font(AppTheme.Typography.caption)
                                Text("\(entry.formattedClockIn) - \(entry.formattedClockOut)")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(entry.formattedDuration)
                                .font(AppTheme.Typography.caption)
                                .fontWeight(.medium)
                        }
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .glassCard()
    }
    
    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Actions")
                .font(AppTheme.Typography.headline)
            
            HStack {
                if employee.isActive {
                    Button("Deactivate Employee") {
                        showDeactivateAlert = true
                    }
                    .buttonStyle(PremiumButtonStyle(variant: .destructive))
                } else {
                    Button("Activate Employee") {
                        activateEmployee()
                    }
                    .buttonStyle(PremiumButtonStyle(variant: .success))
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .glassCard()
        .alert("Deactivate Employee", isPresented: $showDeactivateAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Deactivate", role: .destructive) {
                deactivateEmployee()
            }
        } message: {
            Text("This will prevent \(employee.fullName) from logging in. Their data will be preserved.")
        }
    }
    
    // MARK: - Edit Form View
    
    private var editFormView: some View {
        VStack(spacing: 0) {
            Form {
                Section("Personal Information") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Email", text: $email)
                    TextField("Phone", text: $phone)
                }
                
                Section("Employment") {
                    Picker("Role", selection: $role) {
                        ForEach(EmployeeRole.allCases, id: \.self) { role in
                            Text(role.rawValue).tag(role)
                        }
                    }
                    
                    TextField("Hourly Rate", text: $hourlyRate)
                }
            }
            .formStyle(.grouped)
            
            if showError {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            HStack {
                Spacer()
                
                Button("Cancel") {
                    isEditing = false
                }
                .buttonStyle(PremiumButtonStyle(variant: .secondary))
                
                Button("Save Changes") {
                    saveChanges()
                }
                .buttonStyle(PremiumButtonStyle(variant: .primary))
            }
            .padding(AppTheme.Spacing.lg)
        }
    }
    
    // MARK: - Helper Views
    
    private struct InfoRow: View {
        let label: String
        let value: String
        
        var body: some View {
            HStack {
                Text(label + ":")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(.secondary)
                Spacer()
                Text(value)
                    .font(AppTheme.Typography.body)
                    .fontWeight(.medium)
            }
        }
    }
    
    // MARK: - Actions
    
    private func startEditing() {
        firstName = employee.firstName ?? ""
        lastName = employee.lastName ?? ""
        email = employee.email ?? ""
        phone = employee.phone ?? ""
        role = employee.roleType
        hourlyRate = employee.hourlyRate.stringValue
        isEditing = true
    }
    
    private func saveChanges() {
        guard let rate = Decimal(string: hourlyRate) else {
            showErrorMessage("Invalid hourly rate")
            return
        }
        
        do {
            try employeeService.updateEmployee(
                employee,
                firstName: firstName,
                lastName: lastName,
                email: email,
                role: role,
                hourlyRate: rate,
                phone: phone
            )
            
            isEditing = false
            onUpdate()
        } catch {
            showErrorMessage(error.localizedDescription)
        }
    }
    
    private func deactivateEmployee() {
        do {
            try employeeService.deactivateEmployee(employee)
            onUpdate()
        } catch {
            showErrorMessage(error.localizedDescription)
        }
    }
    
    private func activateEmployee() {
        do {
            try employeeService.activateEmployee(employee)
            onUpdate()
        } catch {
            showErrorMessage(error.localizedDescription)
        }
    }
    
    private func loadTimeClockEntries() {
        guard let employeeId = employee.id else { return }
        timeClockEntries = timeClockService.fetchEntriesForEmployee(employeeId).prefix(10).map { $0 }
    }
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    // MARK: - Formatters
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatHours(_ seconds: TimeInterval) -> String {
        let hours = seconds / 3600
        return String(format: "%.1f hours", hours)
    }
}
