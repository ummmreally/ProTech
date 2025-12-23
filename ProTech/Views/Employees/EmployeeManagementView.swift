//
//  EmployeeManagementView.swift
//  ProTech
//
//  Employee management dashboard
//

import SwiftUI

struct EmployeeManagementView: View {
    @StateObject private var employeeService = EmployeeService()
    @StateObject private var authService = AuthenticationService.shared
    @StateObject private var employeeSyncer = EmployeeSyncer()
    @StateObject private var queueManager = OfflineQueueManager.shared
    
    @State private var employees: [Employee] = []
    @State private var searchText = ""
    @State private var selectedRole: EmployeeRole?
    @State private var showInactive = false
    @State private var showAddEmployee = false
    @State private var selectedEmployee: Employee?
    @State private var isRefreshing = false
    
    var filteredEmployees: [Employee] {
        var result = employees
        
        // Filter by search
        if !searchText.isEmpty {
            result = result.filter { employee in
                employee.fullName.localizedCaseInsensitiveContains(searchText) ||
                employee.email?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
        
        // Filter by role
        if let role = selectedRole {
            result = result.filter { $0.roleType == role }
        }
        
        // Filter by status
        if !showInactive {
            result = result.filter { $0.isActive }
        }
        
        return result
    }
    
    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Offline Banner
                OfflineBanner()
                
                // Header
                headerView
                
                // Filters
                filterBar
                
                // Employee list
                if filteredEmployees.isEmpty {
                    emptyStateView
                } else {
                    employeeListView
                }
            }
        }
        .sheet(isPresented: $showAddEmployee) {
            AddEmployeeView(employeeService: employeeService, onSave: loadEmployees)
        }
        .sheet(item: $selectedEmployee) { employee in
            EmployeeDetailView(employee: employee, employeeService: employeeService, onUpdate: loadEmployees)
        }
        .onAppear(perform: loadEmployees)
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Employees")
                            .font(AppTheme.Typography.largeTitle)
                            .foregroundStyle(AppTheme.Colors.primaryGradient)
                        
                        SyncStatusBadge()
                    }
                    
                    Text("Manage your team, roles, and permissions")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { showAddEmployee = true }) {
                    Label("Add Employee", systemImage: "person.badge.plus")
                }
                .buttonStyle(PremiumButtonStyle(variant: .primary))
                .disabled(!authService.hasPermission(.manageEmployees))
            }
            
            // Stats Row
            HStack(spacing: AppTheme.Spacing.lg) {
                EmployeeStatBadge(
                    icon: "person.2.fill",
                    value: "\(employees.count)",
                    label: "Total"
                )
                
                EmployeeStatBadge(
                    icon: "checkmark.circle.fill",
                    value: "\(employees.filter { $0.isActive }.count)",
                    label: "Active",
                    color: .green
                )
                
                EmployeeStatBadge(
                    icon: "briefcase.fill",
                    value: "\(employees.filter { $0.roleType == .technician }.count)",
                    label: "Techs",
                    color: .blue
                )
            }
        }
        .padding(AppTheme.Spacing.xl)
        .background(AppTheme.Colors.cardBackground)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.2))
                .padding(.horizontal, -AppTheme.Spacing.xl),
            alignment: .bottom
        )
    }
    
    // MARK: - Filter Bar
    
    private var filterBar: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search employees...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(10)
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            
            // Role filter items
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        title: "All",
                        isSelected: selectedRole == nil,
                        action: { selectedRole = nil }
                    )
                    
                    ForEach(EmployeeRole.allCases, id: \.self) { role in
                        FilterChip(
                            title: role.rawValue,
                            isSelected: selectedRole == role,
                            action: { selectedRole = role }
                        )
                    }
                }
            }
            
            Spacer()
            
            // Show inactive toggle
            Toggle("Show Inactive", isOn: $showInactive)
                .toggleStyle(.switch)
                .font(AppTheme.Typography.caption)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.background)
    }
    
    // MARK: - Employee List
    
    private var employeeListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredEmployees) { employee in
                    EmployeeRowView(employee: employee)
                        .onTapGesture {
                            selectedEmployee = employee
                        }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()
            
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundStyle(AppTheme.Colors.primaryGradient)
                .opacity(0.8)
            
            VStack(spacing: 8) {
                Text("No Employees Found")
                    .font(AppTheme.Typography.title2)
                    .fontWeight(.semibold)
                
                Text(searchText.isEmpty ? "Add your first employee to get started" : "Try adjusting your search or filters")
                    .foregroundColor(.secondary)
            }
            
            if authService.hasPermission(.manageEmployees) && searchText.isEmpty {
                Button("Add Employee") {
                    showAddEmployee = true
                }
                .buttonStyle(PremiumButtonStyle(variant: .primary))
            }
            
            Spacer()
        }
    }
    
    // MARK: - Actions
    
    private func loadEmployees() {
        employees = employeeService.fetchAllEmployees()
    }
}

// MARK: - Subviews

struct EmployeeStatBadge: View {
    let icon: String
    let value: String
    let label: String
    var color: Color = .primary
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(8)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.Typography.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? AppTheme.Colors.primary.opacity(0.2) : AppTheme.Colors.cardBackground)
                .foregroundColor(isSelected ? AppTheme.Colors.primary : .primary)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? AppTheme.Colors.primary : Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Employee Row View
struct EmployeeRowView: View {
    let employee: Employee
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 15) {
            // Avatar
            ZStack {
                Circle()
                    .fill(employee.isActive ? 
                          AppTheme.Colors.primary.opacity(0.1) : 
                          Color.gray.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Text(employee.initials)
                    .font(.headline)
                    .foregroundColor(employee.isActive ? AppTheme.Colors.primary : .gray)
            }
            .overlay(
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(employee.fullName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if employee.isAdmin {
                        Image(systemName: "shield.fill")
                            .font(.caption)
                            .foregroundColor(.purple)
                            .help("Administrator")
                    }
                }
                
                HStack(spacing: 8) {
                    Text(employee.displayRole)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(roleColor(employee.roleType).opacity(0.15))
                        .foregroundColor(roleColor(employee.roleType))
                        .cornerRadius(4)
                    
                    if let email = employee.email {
                        Text(email)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Rate and status
            VStack(alignment: .trailing, spacing: 4) {
                Text(employee.formattedHourlyRate)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                StatusBadge(isActive: employee.isActive)
            }
            
            // Sync status icon
            if let syncStatus = employee.cloudSyncStatus {
                syncStatusIcon(for: syncStatus)
            }
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding()
        .glassCard()
    }
    
    private func syncStatusIcon(for status: String) -> some View {
        Group {
            switch status {
            case "synced":
                Image(systemName: "checkmark.icloud.fill")
                    .foregroundColor(.green)
                    .font(AppTheme.Typography.caption)
                    .help("Synced to cloud")
            case "pending":
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.orange)
                    .font(AppTheme.Typography.caption)
                    .help("Sync pending")
            case "failed":
                Image(systemName: "exclamationmark.icloud.fill")
                    .foregroundColor(.red)
                    .font(AppTheme.Typography.caption)
                    .help("Sync failed")
            default:
                EmptyView()
            }
        }
    }
    
    private func roleColor(_ role: EmployeeRole) -> Color {
        switch role {
        case .admin: return .purple
        case .manager: return .blue
        case .technician: return .green
        case .frontDesk: return .orange
        }
    }
    
    struct StatusBadge: View {
        let isActive: Bool
        
        var body: some View {
            HStack(spacing: 4) {
                Circle()
                    .fill(isActive ? Color.green : Color.red)
                    .frame(width: 6, height: 6)
                
                Text(isActive ? "Active" : "Inactive")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(isActive ? .green : .red)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background((isActive ? Color.green : Color.red).opacity(0.1))
            .cornerRadius(4)
        }
    }
}

#Preview {
    EmployeeManagementView()
}
