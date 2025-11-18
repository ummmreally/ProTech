//
//  LoginView.swift
//  ProTech
//
//  Employee login screen with PIN and password options
//

import SwiftUI

struct LoginView: View {
    @StateObject private var supabaseAuth = SupabaseAuthService.shared
    @StateObject private var offlineQueue = OfflineQueueManager.shared
    @StateObject private var oldAuthService = AuthenticationService.shared // Keep for fallback
    @AppStorage("brandName") private var brandName = "ProTech"
    @AppStorage("customLogoPath") private var customLogoPath = ""
    
    @State private var loginMode: LoginMode = .pin
    @State private var pinCode = ""
    @State private var employeeNumber = "" // For PIN login
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showSignup = false
    @State private var isLoading = false
    @State private var currentTime = Date()
    
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
                    // Custom logo or default icon
                    if !customLogoPath.isEmpty, let nsImage = NSImage(contentsOfFile: customLogoPath) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .cornerRadius(12)
                            .shadow(radius: 10)
                    } else {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                    }
                    
                    Text(brandName)
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Live date and time
                    Text(currentTime, style: .date)
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.9))
                    + Text(" • ")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.9))
                    + Text(currentTime, style: .time)
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
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            HStack {
                                Image(systemName: "arrow.right.circle.fill")
                                Text("Login")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        }
                    }
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .buttonStyle(.plain)
                    .disabled(isLoading)
                    .keyboardShortcut(.return)
                    
                    // Signup link
                    Button("Create Account") {
                        showSignup = true
                    }
                    .buttonStyle(.link)
                    .foregroundColor(.blue)
                }
                .padding(30)
                .background(Color(NSColor.windowBackgroundColor))
                .cornerRadius(20)
                .shadow(radius: 20)
                .frame(width: 400)
                
                // Network status
                if !offlineQueue.isOnline {
                    HStack {
                        Image(systemName: "wifi.slash")
                        Text("Offline Mode - Limited functionality")
                            .font(.caption)
                    }
                    .foregroundColor(.orange)
                    .padding(8)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(8)
                }
                
                // Error message
                if showError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(8)
                }
                
                Spacer()
                
            }
            .padding()
        }
        .onAppear {
            startTimeUpdater()
        }
        .sheet(isPresented: $showSignup) {
            SignupView()
        }
    }
    
    // MARK: - Time Updater
    
    private func startTimeUpdater() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            currentTime = Date()
        }
    }
    
    // MARK: - PIN Login View
    
    private var pinLoginView: some View {
        VStack(spacing: 15) {
            Text("Enter Employee Number and PIN")
                .font(.headline)
                .help("Use your employee number and 6-digit PIN")
            
            TextField("Employee Number", text: $employeeNumber)
                .textFieldStyle(.roundedBorder)
                .textContentType(.username)
            
            SecureField("PIN Code", text: $pinCode)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 18, weight: .bold))
                .multilineTextAlignment(.center)
                .onChange(of: pinCode) { _, newValue in
                    let digitsOnly = newValue.filter { $0.isNumber }
                    pinCode = String(digitsOnly.prefix(6))
                }
                .onSubmit {
                    handleLogin()
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
                    .buttonStyle(.plain)
                    
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
                    .buttonStyle(.plain)
                }
            }
            
            Text("Up to 5 failed attempts allowed. Accounts lock for 15 minutes after repeated failures.")
                .font(.caption)
                .foregroundColor(.secondary)
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
                .onSubmit {
                    handleLogin()
                }
            
            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
                .textContentType(.password)
                .onSubmit {
                    handleLogin()
                }
        }
    }
    
    // MARK: - Actions
    
    private func handleLogin() {
        print("🔑 Login button pressed - Mode: \(loginMode == .pin ? "PIN" : "Password")")
        showError = false
        errorMessage = ""
        isLoading = true
        
        Task {
            do {
                if loginMode == .pin {
                    guard !employeeNumber.isEmpty && !pinCode.isEmpty else {
                        await MainActor.run {
                            showErrorMessage("Please enter employee number and PIN")
                            isLoading = false
                        }
                        return
                    }
                    
                    // Try Supabase PIN auth first
                    if offlineQueue.isOnline {
                        print("🌐 Online - using Supabase PIN auth")
                        try await supabaseAuth.signInWithPIN(
                            employeeNumber: employeeNumber,
                            pin: pinCode
                        )
                    } else {
                        // Fallback to local auth when offline
                        print("📴 Offline - using local PIN auth")
                        let result = oldAuthService.loginWithPIN(pinCode)
                        switch result {
                        case .success:
                            break
                        case .failure(let error):
                            throw error
                        }
                    }
                } else {
                    guard !email.isEmpty && !password.isEmpty else {
                        await MainActor.run {
                            showErrorMessage("Please enter email and password")
                            isLoading = false
                        }
                        return
                    }
                    
                    print("🌐 Online - attempting Supabase email/password auth for: \(email)")
                    // Use Supabase email/password auth
                    if offlineQueue.isOnline {
                        try await supabaseAuth.signIn(
                            email: email,
                            password: password
                        )
                        print("✅ SignIn completed, checking auth state...")
                        print("   - supabaseAuth.isAuthenticated: \(supabaseAuth.isAuthenticated)")
                        print("   - oldAuthService.isAuthenticated: \(oldAuthService.isAuthenticated)")
                    } else {
                        // Fallback to local auth when offline
                        print("📴 Offline - using local email/password auth")
                        let result = oldAuthService.loginWithEmail(email, password: password)
                        switch result {
                        case .success:
                            break
                        case .failure(let error):
                            throw error
                        }
                    }
                }
                
                await MainActor.run {
                    // Only clear fields if authentication actually succeeded
                    if supabaseAuth.isAuthenticated || oldAuthService.isAuthenticated {
                        print("✅ Authentication successful - clearing form fields")
                        pinCode = ""
                        employeeNumber = ""
                        email = ""
                        password = ""
                    } else {
                        print("❌ Authentication state not updated - showing error")
                        showErrorMessage("Login failed - authentication state not updated. Please try again.")
                    }
                    isLoading = false
                }
            } catch {
                print("❌ Login error caught: \(error)")
                print("   Error type: \(type(of: error))")
                print("   Error description: \(error.localizedDescription)")
                await MainActor.run {
                    showErrorMessage(error.localizedDescription)
                    isLoading = false
                }
            }
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
