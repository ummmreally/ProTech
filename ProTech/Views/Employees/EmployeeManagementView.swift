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
    
    @State private var employees: [Employee] = []
    @State private var searchText = ""
    @State private var selectedRole: EmployeeRole?
    @State private var showInactive = false
    @State private var showAddEmployee = false
    @State private var selectedEmployee: Employee?
    
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
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Employees")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("\(filteredEmployees.count) employees")
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { showAddEmployee = true }) {
                    Label("Add Employee", systemImage: "person.badge.plus")
                }
                .buttonStyle(.borderedProminent)
                .disabled(!authService.hasPermission(.manageEmployees))
            }
            .padding()
            
            Divider()
            
            // Filters
            HStack {
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search employees...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                // Role filter
                Picker("Role", selection: $selectedRole) {
                    Text("All Roles").tag(nil as EmployeeRole?)
                    ForEach(EmployeeRole.allCases, id: \.self) { role in
                        Text(role.rawValue).tag(role as EmployeeRole?)
                    }
                }
                .frame(width: 180)
                
                // Show inactive toggle
                Toggle("Show Inactive", isOn: $showInactive)
                    .toggleStyle(.switch)
            }
            .padding()
            
            Divider()
            
            // Employee list
            if filteredEmployees.isEmpty {
                emptyStateView
            } else {
                employeeListView
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
        VStack(spacing: 20) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Employees Found")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add your first employee to get started")
                .foregroundColor(.secondary)
            
            if authService.hasPermission(.manageEmployees) {
                Button("Add Employee") {
                    showAddEmployee = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Actions
    
    private func loadEmployees() {
        employees = employeeService.fetchAllEmployees()
    }
}

// MARK: - Employee Row View
struct EmployeeRowView: View {
    let employee: Employee
    
    var body: some View {
        HStack(spacing: 15) {
            // Avatar
            ZStack {
                Circle()
                    .fill(employee.isActive ? Color.blue : Color.gray)
                    .frame(width: 50, height: 50)
                
                Text(employee.initials)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(employee.fullName)
                    .font(.headline)
                
                HStack {
                    Text(employee.displayRole)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(roleColor(employee.roleType).opacity(0.2))
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
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(employee.isActive ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    
                    Text(employee.isActive ? "Active" : "Inactive")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private func roleColor(_ role: EmployeeRole) -> Color {
        switch role {
        case .admin: return .purple
        case .manager: return .blue
        case .technician: return .green
        case .frontDesk: return .orange
        }
    }
}

#Preview {
    EmployeeManagementView()
}
