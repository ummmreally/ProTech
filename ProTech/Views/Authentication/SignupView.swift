//
//  SignupView.swift
//  ProTech
//
//  Employee signup with Supabase Auth integration
//

import SwiftUI

struct SignupView: View {
    @StateObject private var authService = SupabaseAuthService.shared
    @StateObject private var offlineQueue = OfflineQueueManager.shared
    @Environment(\.dismiss) private var dismiss
    
    // Form fields
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var employeeNumber = ""
    @State private var pin = ""
    @State private var role = "technician"
    @State private var shopId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    
    // UI State
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
    // Validation
    private var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        password == confirmPassword &&
        password.count >= 8 &&
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        pin.count == 6 &&
        pin.allSatisfy { $0.isNumber }
    }
    
    private var passwordStrength: PasswordStrength {
        guard !password.isEmpty else { return .none }
        
        var strength = 0
        if password.count >= 8 { strength += 1 }
        if password.count >= 12 { strength += 1 }
        if password.contains(where: { $0.isUppercase }) { strength += 1 }
        if password.contains(where: { $0.isLowercase }) { strength += 1 }
        if password.contains(where: { $0.isNumber }) { strength += 1 }
        if password.contains(where: { "!@#$%^&*()".contains($0) }) { strength += 1 }
        
        switch strength {
        case 0...2: return .weak
        case 3...4: return .medium
        default: return .strong
        }
    }
    
    enum PasswordStrength {
        case none, weak, medium, strong
        
        var color: Color {
            switch self {
            case .none: return .gray
            case .weak: return .red
            case .medium: return .orange
            case .strong: return .green
            }
        }
        
        var text: String {
            switch self {
            case .none: return ""
            case .weak: return "Weak"
            case .medium: return "Medium"
            case .strong: return "Strong"
            }
        }
        
        var ordinal: Int {
            switch self {
            case .none: return 0
            case .weak: return 1
            case .medium: return 2
            case .strong: return 3
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "person.badge.plus.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Create Employee Account")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Set up your ProTech account with Supabase sync")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 20)
                
                // Network Status
                if !offlineQueue.isOnline {
                    HStack {
                        Image(systemName: "wifi.slash")
                        Text("Offline - Account will be created when connection is restored")
                            .font(.caption)
                    }
                    .foregroundColor(.orange)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Form
                VStack(alignment: .leading, spacing: 20) {
                    // Personal Information
                    GroupBox("Personal Information") {
                        VStack(spacing: 15) {
                            HStack(spacing: 15) {
                                TextField("First Name", text: $firstName)
                                    .textFieldStyle(.roundedBorder)
                                
                                TextField("Last Name", text: $lastName)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            TextField("Employee Number (optional)", text: $employeeNumber)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    
                    // Account Credentials
                    GroupBox("Account Credentials") {
                        VStack(alignment: .leading, spacing: 15) {
#if os(iOS)
                            if #available(iOS 15.0, *) {
                                TextField("Email", text: $email)
                                    .textFieldStyle(.roundedBorder)
                                    .textContentType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled(true)
                            } else {
                                TextField("Email", text: $email)
                                    .textFieldStyle(.roundedBorder)
                                    .textContentType(.emailAddress)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                            }
#else
                            TextField("Email", text: $email)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.emailAddress)
#endif
                            
                            SecureField("Password", text: $password)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.newPassword)
                            
                            if !password.isEmpty {
                                HStack {
                                    Text("Password Strength:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text(passwordStrength.text)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(passwordStrength.color)
                                    
                                    Spacer()
                                    
                                    // Strength indicator
                                    HStack(spacing: 3) {
                                        ForEach(0..<4) { index in
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(index < passwordStrength.ordinal ? passwordStrength.color : Color.gray.opacity(0.3))
                                                .frame(width: 20, height: 4)
                                        }
                                    }
                                }
                            }
                            
                            SecureField("Confirm Password", text: $confirmPassword)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.newPassword)
                            
                            if !confirmPassword.isEmpty && password != confirmPassword {
                                Text("Passwords don't match")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    // Security
                    GroupBox("Security") {
                        VStack(alignment: .leading, spacing: 15) {
                            SecureField("6-Digit PIN (for quick login)", text: $pin)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: pin) { _, newValue in
                                    let digitsOnly = newValue.filter { $0.isNumber }
                                    pin = String(digitsOnly.prefix(6))
                                }
                            
                            Text("PIN must be exactly 6 digits. Used for kiosk/quick login.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Role Selection
                    GroupBox("Role") {
                        Picker("Employee Role", selection: $role) {
                            Text("Technician").tag("technician")
                            Text("Manager").tag("manager")
                            Text("Receptionist").tag("receptionist")
                            Text("Admin").tag("admin")
                        }
                        .pickerStyle(.radioGroup)
                    }
                }
                
                // Action Buttons
                HStack(spacing: 15) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: handleSignup) {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .frame(width: 20, height: 20)
                        } else {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                Text("Create Account")
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isFormValid || isLoading)
                }
                .padding(.top)
            }
            .padding(30)
        }
        .frame(width: 600, height: 700)
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                showError = false
            }
        } message: {
            Text(errorMessage)
        }
        .alert("Success", isPresented: $showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Account created successfully! You can now log in.")
        }
    }
    
    private func handleSignup() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                _ = try await authService.signUpEmployee(
                    email: email,
                    password: password,
                    firstName: firstName,
                    lastName: lastName,
                    shopId: shopId,
                    role: role,
                    pin: pin
                )
                
                await MainActor.run {
                    showSuccess = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isLoading = false
                }
            }
        }
    }
}

// PasswordStrength ordinal is now defined in the enum itself

#Preview {
    SignupView()
}
