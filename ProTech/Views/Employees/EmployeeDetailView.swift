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
    
    // Security states
    @State private var showResetPassword = false
    @State private var showResetPIN = false
    @State private var newPassword = ""
    @State private var confirmNewPassword = ""
    @State private var newPIN = ""
    @State private var confirmNewPIN = ""
    
    @State private var showDeactivateAlert = false
    @State private var showError = false
    @State private var showSuccess = false
    @State private var errorMessage = ""
    @State private var successMessage = ""
    
    @State private var timeClockEntries: [TimeClockEntry] = []
    
    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                if isEditing {
                    editFormView
                } else {
                    detailView
                }
            }
        }
        .frame(width: 800, height: 700)
        .onAppear {
            loadTimeClockEntries()
        }
        // Password Reset Sheet
        .sheet(isPresented: $showResetPassword) {
            resetPasswordSheet
        }
        // PIN Reset Sheet
        .sheet(isPresented: $showResetPIN) {
            resetPINSheet
        }
        // Alerts
        .alert("Deactivate Employee", isPresented: $showDeactivateAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Deactivate", role: .destructive) {
                deactivateEmployee()
            }
        } message: {
            Text("This will prevent \(employee.fullName) from logging in. Their data will be preserved.")
        }
        // Success Toast Overlay
        .overlay(alignment: .bottom) {
            if showSuccess {
                Text(successMessage)
                    .padding()
                    .background(Material.regular)
                    .cornerRadius(10)
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { showSuccess = false }
                        }
                    }
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(employee.fullName)
                    .font(AppTheme.Typography.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.Colors.primaryGradient)
                
                HStack {
                    Text(employee.displayRole)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(.secondary)
                    
                    if employee.isAdmin {
                        Image(systemName: "shield.fill")
                            .foregroundColor(.purple)
                            .font(.caption)
                    }
                }
            }
            
            Spacer()
            
            if !isEditing {
                Button("Edit Profile") {
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
        .background(AppTheme.Colors.cardBackground)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.2))
                .padding(.horizontal, -AppTheme.Spacing.lg),
            alignment: .bottom
        )
    }
    
    // MARK: - Detail View
    
    private var detailView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                HStack(alignment: .top, spacing: AppTheme.Spacing.lg) {
                    // Left Column
                    VStack(spacing: AppTheme.Spacing.lg) {
                        profileSection
                        employmentSection
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Right Column
                    VStack(spacing: AppTheme.Spacing.lg) {
                        securitySection
                        timeClockSection
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Actions
                actionsSection
            }
            .padding(AppTheme.Spacing.lg)
        }
    }
    
    private var profileSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            SectionHeader(title: "Profile Information", icon: "person.text.rectangle")
            
            InfoRow(label: "Name", value: employee.fullName)
            InfoRow(label: "Email", value: employee.email ?? "N/A", copyable: true)
            InfoRow(label: "Phone", value: employee.phone ?? "N/A", copyable: true)
            InfoRow(label: "Employee #", value: employee.employeeNumber ?? "N/A", copyable: true)
            
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
                        .foregroundColor(employee.isActive ? AppTheme.Colors.success : AppTheme.Colors.error)
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .glassCard()
    }
    
    private var employmentSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            SectionHeader(title: "Employment Details", icon: "briefcase")
            
            InfoRow(label: "Role", value: employee.displayRole)
            InfoRow(label: "Hourly Rate", value: employee.formattedHourlyRate)
            
            if let hireDate = employee.hireDate {
                InfoRow(label: "Hire Date", value: formatDate(hireDate))
            }
            
            if let lastLogin = employee.lastLoginAt {
                InfoRow(label: "Last Login", value: formatDateTime(lastLogin))
            }
            
            Divider()
                .padding(.vertical, 4)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Permissions")
                    .font(AppTheme.Typography.subheadline)
                    .fontWeight(.medium)
                
                ForEach(employee.roleType.permissions, id: \.self) { permission in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text(permission.rawValue)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .glassCard()
    }
    
    private var securitySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            SectionHeader(title: "Security & Access", icon: "lock.shield")
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Password")
                        .font(.subheadline)
                    Text(employee.hasPasswordSet ? "Set" : "Not Set")
                        .font(.caption)
                        .foregroundColor(employee.hasPasswordSet ? .green : .orange)
                }
                
                Spacer()
                
                Button("Reset Password") {
                    newPassword = ""
                    confirmNewPassword = ""
                    showResetPassword = true
                }
                .buttonStyle(PremiumButtonStyle(variant: .secondary))
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading) {
                    Text("PIN Code")
                        .font(.subheadline)
                    Text(employee.hasPINSet ? "Set (6 digits)" : "Not Set")
                        .font(.caption)
                        .foregroundColor(employee.hasPINSet ? .green : .orange)
                }
                
                Spacer()
                
                Button("Reset PIN") {
                    newPIN = ""
                    confirmNewPIN = ""
                    showResetPIN = true
                }
                .buttonStyle(PremiumButtonStyle(variant: .secondary))
            }
        }
        .padding(AppTheme.Spacing.lg)
        .glassCard()
    }
    
    private var timeClockSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            SectionHeader(title: "Time Clock", icon: "clock")
            
            if let employeeId = employee.id {
                let thisWeekHours = timeClockService.getTotalHoursThisWeek(for: employeeId)
                let thisMonthHours = timeClockService.getTotalHoursThisMonth(for: employeeId)
                
                HStack(spacing: 20) {
                    VStack(alignment: .leading) {
                        Text("This Week")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatHours(thisWeekHours))
                            .font(.headline)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("This Month")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatHours(thisMonthHours))
                            .font(.headline)
                    }
                }
                
                // Recent entries
                if !timeClockEntries.isEmpty {
                    Text("Recent Activity")
                        .font(AppTheme.Typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    
                    VStack(spacing: 8) {
                        ForEach(timeClockEntries.prefix(3)) { entry in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.formattedShiftDate)
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                    Text("\(entry.formattedClockIn) - \(entry.formattedClockOut)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(entry.formattedDuration)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .glassCard()
    }
    
    private var actionsSection: some View {
        HStack {
            Spacer()
            
            if employee.isActive {
                Button(action: { showDeactivateAlert = true }) {
                    Label("Deactivate Employee", systemImage: "person.slash")
                }
                .buttonStyle(PremiumButtonStyle(variant: .destructive))
            } else {
                Button(action: { activateEmployee() }) {
                    Label("Activate Employee", systemImage: "person.fill.checkmark")
                }
                .buttonStyle(PremiumButtonStyle(variant: .success))
            }
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
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
            .background(AppTheme.Colors.cardBackground)
        }
    }
    
    // MARK: - Sheets
    
    private var resetPasswordSheet: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Text("Reset Password")
                .font(AppTheme.Typography.title2)
                .fontWeight(.bold)
            
            Text("Create a new password for \(employee.fullName)")
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                SecureField("New Password", text: $newPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                SecureField("Confirm Password", text: $confirmNewPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Text("Min 10 chars, uppercase, lowercase, number, symbol")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            
            if showError {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            HStack {
                Button("Cancel") {
                    showResetPassword = false
                    showError = false
                }
                .buttonStyle(PremiumButtonStyle(variant: .secondary))
                
                Button("Update Password") {
                    resetPassword()
                }
                .buttonStyle(PremiumButtonStyle(variant: .primary))
                .disabled(newPassword.isEmpty || confirmNewPassword.isEmpty)
            }
        }
        .padding(AppTheme.Spacing.xl)
        .frame(width: 400)
    }
    
    private var resetPINSheet: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Text("Reset PIN Code")
                .font(AppTheme.Typography.title2)
                .fontWeight(.bold)
            
            Text("Set a new 6-digit PIN for \(employee.fullName)")
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                SecureField("New PIN (6 digits)", text: $newPIN)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: newPIN) { _, val in
                        newPIN = String(val.filter { $0.isNumber }.prefix(6))
                    }
                
                SecureField("Confirm PIN", text: $confirmNewPIN)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: confirmNewPIN) { _, val in
                        confirmNewPIN = String(val.filter { $0.isNumber }.prefix(6))
                    }
            }
            .padding()
            
            if showError {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            HStack {
                Button("Cancel") {
                    showResetPIN = false
                    showError = false
                }
                .buttonStyle(PremiumButtonStyle(variant: .secondary))
                
                Button("Update PIN") {
                    resetPIN()
                }
                .buttonStyle(PremiumButtonStyle(variant: .primary))
                .disabled(newPIN.count != 6 || confirmNewPIN.count != 6)
            }
        }
        .padding(AppTheme.Spacing.xl)
        .frame(width: 400)
    }
    
    // MARK: - Helper Views
    
    private struct SectionHeader: View {
        let title: String
        let icon: String
        
        var body: some View {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(AppTheme.Colors.primary)
                Text(title)
                    .font(AppTheme.Typography.headline)
            }
            .padding(.bottom, 4)
        }
    }
    
    private struct InfoRow: View {
        let label: String
        let value: String
        var copyable: Bool = false
        
        var body: some View {
            HStack {
                Text(label + ":")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(.secondary)
                Spacer()
                if copyable {
                    Text(value)
                        .font(AppTheme.Typography.body)
                        .fontWeight(.medium)
                        .textSelection(.enabled)
                } else {
                    Text(value)
                        .font(AppTheme.Typography.body)
                        .fontWeight(.medium)
                }
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
            showSuccessMessage("Profile updated successfully")
            onUpdate()
        } catch {
            showErrorMessage(error.localizedDescription)
        }
    }
    
    private func resetPassword() {
        guard newPassword == confirmNewPassword else {
            showErrorMessage("Passwords do not match")
            return
        }
        
        do {
            try employeeService.updateEmployeePassword(employee, newPassword: newPassword)
            showResetPassword = false
            showSuccessMessage("Password reset successfully")
            onUpdate() // Changes pending states typically
        } catch {
            showErrorMessage(error.localizedDescription)
        }
    }
    
    private func resetPIN() {
        guard newPIN == confirmNewPIN else {
            showErrorMessage("PINs do not match")
            return
        }
        
        do {
            try employeeService.updateEmployee(employee, pinCode: newPIN)
            showResetPIN = false
            showSuccessMessage("PIN reset successfully")
            onUpdate()
        } catch {
            showErrorMessage(error.localizedDescription)
        }
    }
    
    private func deactivateEmployee() {
        do {
            try employeeService.deactivateEmployee(employee)
            onUpdate()
            showSuccessMessage("Employee deactivated")
        } catch {
            showErrorMessage(error.localizedDescription)
        }
    }
    
    private func activateEmployee() {
        do {
            try employeeService.activateEmployee(employee)
            onUpdate()
            showSuccessMessage("Employee activated")
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
    
    private func showSuccessMessage(_ message: String) {
        successMessage = message
        showSuccess = true
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
        return String(format: "%.1f hrs", hours)
    }
}
