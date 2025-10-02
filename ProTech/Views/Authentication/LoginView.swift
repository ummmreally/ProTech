//
//  LoginView.swift
//  ProTech
//
//  Employee login screen with PIN and password options
//

import SwiftUI

struct LoginView: View {
    @StateObject private var authService = AuthenticationService.shared
    @StateObject private var employeeService = EmployeeService()
    
    @State private var loginMode: LoginMode = .pin
    @State private var pinCode = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var showError = false
    
    enum LoginMode {
        case pin
        case password
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.4)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Logo and title
                VStack(spacing: 10) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                    
                    Text("ProTech")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Repair Shop Management")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.bottom, 20)
                
                // Login card
                VStack(spacing: 25) {
                    // Mode selector
                    Picker("Login Mode", selection: $loginMode) {
                        Text("PIN").tag(LoginMode.pin)
                        Text("Password").tag(LoginMode.password)
                    }
                    .pickerStyle(.segmented)
                    
                    // PIN Login
                    if loginMode == .pin {
                        pinLoginView
                    }
                    // Password Login
                    else {
                        passwordLoginView
                    }
                    
                    // Login button
                    Button(action: handleLogin) {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("Login")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .keyboardShortcut(.return)
                }
                .padding(30)
                .background(Color(NSColor.windowBackgroundColor))
                .cornerRadius(20)
                .shadow(radius: 20)
                .frame(width: 400)
                
                // Error message
                if showError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(8)
                }
                
                Spacer()
                
                // Default credentials hint
                Text("Default: PIN 1234 or admin@protech.com / admin123")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding()
        }
        .onAppear {
            employeeService.createDefaultAdminIfNeeded()
        }
    }
    
    // MARK: - PIN Login View
    
    private var pinLoginView: some View {
        VStack(spacing: 15) {
            Text("Enter your 4-6 digit PIN")
                .font(.headline)
            
            SecureField("PIN Code", text: $pinCode)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 24, weight: .bold))
                .multilineTextAlignment(.center)
                .onChange(of: pinCode) { _, newValue in
                    // Limit to 6 digits
                    if newValue.count > 6 {
                        pinCode = String(newValue.prefix(6))
                    }
                }
            
            // PIN pad
            VStack(spacing: 12) {
                ForEach(0..<3) { row in
                    HStack(spacing: 12) {
                        ForEach(1...3, id: \.self) { col in
                            let number = row * 3 + col
                            pinButton(number: number)
                        }
                    }
                }
                
                HStack(spacing: 12) {
                    Button(action: { pinCode = "" }) {
                        Text("Clear")
                            .frame(width: 80, height: 60)
                            .background(Color.red.opacity(0.2))
                            .cornerRadius(8)
                    }
                    
                    pinButton(number: 0)
                    
                    Button(action: {
                        if !pinCode.isEmpty {
                            pinCode.removeLast()
                        }
                    }) {
                        Image(systemName: "delete.left")
                            .frame(width: 80, height: 60)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    private func pinButton(number: Int) -> some View {
        Button(action: {
            if pinCode.count < 6 {
                pinCode += "\(number)"
            }
        }) {
            Text("\(number)")
                .font(.title2)
                .fontWeight(.medium)
                .frame(width: 80, height: 60)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Password Login View
    
    private var passwordLoginView: some View {
        VStack(spacing: 15) {
            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .textContentType(.emailAddress)
            
            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
                .textContentType(.password)
        }
    }
    
    // MARK: - Actions
    
    private func handleLogin() {
        showError = false
        errorMessage = ""
        
        let result: Result<Employee, AuthError>
        
        if loginMode == .pin {
            guard !pinCode.isEmpty else {
                showErrorMessage("Please enter your PIN")
                return
            }
            result = authService.loginWithPIN(pinCode)
        } else {
            guard !email.isEmpty && !password.isEmpty else {
                showErrorMessage("Please enter email and password")
                return
            }
            result = authService.loginWithEmail(email, password: password)
        }
        
        switch result {
        case .success(let employee):
            print("Login successful: \(employee.fullName)")
            // Clear fields
            pinCode = ""
            email = ""
            password = ""
        case .failure(let error):
            showErrorMessage(error.localizedDescription)
        }
    }
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showError = false
        }
    }
}

#Preview {
    LoginView()
}
