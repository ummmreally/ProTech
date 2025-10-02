//
//  AddEmployeeView.swift
//  ProTech
//
//  Form to add new employee
//

import SwiftUI

struct AddEmployeeView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var employeeService: EmployeeService
    
    var onSave: () -> Void
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var role: EmployeeRole = .technician
    @State private var hourlyRate = "25.00"
    @State private var pinCode = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var setPIN = false
    @State private var setPassword = false
    
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Add Employee")
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
            }
            .padding()
            
            Divider()
            
            // Form
            Form {
                Section("Personal Information") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                    TextField("Phone (Optional)", text: $phone)
                        .textContentType(.telephoneNumber)
                }
                
                Section("Employment Details") {
                    Picker("Role", selection: $role) {
                        ForEach(EmployeeRole.allCases, id: \.self) { role in
                            Text(role.rawValue).tag(role)
                        }
                    }
                    
                    HStack {
                        Text("Hourly Rate")
                        Spacer()
                        TextField("Rate", text: $hourlyRate)
                            .frame(width: 100)
                            .multilineTextAlignment(.trailing)
                        Text("per hour")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Authentication") {
                    Toggle("Set PIN Code", isOn: $setPIN)
                    
                    if setPIN {
                        HStack {
                            SecureField("4-6 digit PIN", text: $pinCode)
                                .frame(width: 150)
                            Text("Quick login with PIN")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Toggle("Set Password", isOn: $setPassword)
                    
                    if setPassword {
                        SecureField("Password", text: $password)
                        SecureField("Confirm Password", text: $confirmPassword)
                    }
                }
                
                Section("Permissions") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("This role has the following permissions:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ForEach(role.permissions, id: \.self) { permission in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(permission.rawValue)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
            .formStyle(.grouped)
            
            Divider()
            
            // Error message
            if showError {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.1))
            }
            
            // Actions
            HStack {
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Add Employee") {
                    saveEmployee()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(!isFormValid)
            }
            .padding()
        }
        .frame(width: 600, height: 700)
    }
    
    // MARK: - Validation
    
    private var isFormValid: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !email.isEmpty &&
        employeeService.isValidEmail(email) &&
        (!setPIN || !pinCode.isEmpty) &&
        (!setPassword || (!password.isEmpty && password == confirmPassword))
    }
    
    // MARK: - Actions
    
    private func saveEmployee() {
        showError = false
        
        // Validate PIN if set
        if setPIN && !employeeService.isValidPIN(pinCode) {
            showErrorMessage("PIN must be 4-6 digits")
            return
        }
        
        // Validate password match
        if setPassword && password != confirmPassword {
            showErrorMessage("Passwords do not match")
            return
        }
        
        guard let rate = Decimal(string: hourlyRate) else {
            showErrorMessage("Invalid hourly rate")
            return
        }
        
        do {
            _ = try employeeService.createEmployee(
                firstName: firstName,
                lastName: lastName,
                email: email,
                role: role,
                pinCode: setPIN ? pinCode : nil,
                password: setPassword ? password : nil,
                hourlyRate: rate,
                phone: phone.isEmpty ? nil : phone
            )
            
            onSave()
            dismiss()
        } catch {
            showErrorMessage(error.localizedDescription)
        }
    }
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
}

#Preview {
    AddEmployeeView(employeeService: EmployeeService()) {}
}
