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

    // @State private var employeeNumber = "" // Removed for PIN-only login
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
            // Professional Background
            ZStack {
                AppTheme.Colors.background
                    .ignoresSafeArea()
                
                // Subtle gradient overlay for depth
                LinearGradient(
                    colors: [
                        Color(nsColor: .windowBackgroundColor),
                        Color(nsColor: .windowBackgroundColor).opacity(0.8),
                        Color.blue.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Ambient orb for modern feel
                GeometryReader { proxy in
                    Circle()
                        .fill(Color.blue.opacity(0.05))
                        .frame(width: 800, height: 800)
                        .blur(radius: 100)
                        .position(x: proxy.size.width * 0.9, y: proxy.size.height * 0.1)
                    
                    Circle()
                        .fill(Color.purple.opacity(0.03))
                        .frame(width: 600, height: 600)
                        .blur(radius: 80)
                        .position(x: proxy.size.width * 0.1, y: proxy.size.height * 0.9)
                }
            }
            
            VStack(spacing: 40) {
                // Logo/Header Section
                VStack(spacing: 16) {
                    if !customLogoPath.isEmpty, let nsImage = NSImage(contentsOfFile: customLogoPath) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120) // Slightly larger
                            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
                    } else {
                        Image(systemName: "shield.check.fill") // More professional icon
                            .font(.system(size: 80))
                            .foregroundStyle(AppTheme.Colors.primaryGradient)
                            .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 0)
                    }
                    
                    Text(brandName)
                        .font(AppTheme.Typography.largeTitle)
                        .foregroundColor(.primary)
                    
                    // Date Time
                    HStack(spacing: 8) {
                        Text(currentTime, style: .date)
                        Text("•")
                        Text(currentTime, style: .time)
                    }
                    .font(AppTheme.Typography.body)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                }
                .padding(.top, 20)
                
                // Login Card
                VStack(spacing: 32) {
                    // Mode Selector
                    Picker("Login Mode", selection: $loginMode) {
                        Text("PIN Code").tag(LoginMode.pin)
                        Text("Password").tag(LoginMode.password)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 4)
                    
                    // Login Fields
                    Group {
                        if loginMode == .pin {
                            pinLoginView
                                .transition(.opacity.combined(with: .move(edge: .leading)))
                        } else {
                            passwordLoginView
                                .transition(.opacity.combined(with: .move(edge: .trailing)))
                        }
                    }
                    // .animation(AppTheme.Animation.standard, value: loginMode)
                    
                    // Login Action
                    Button(action: handleLogin) {
                        if isLoading {
                            ProgressView()
                                .controlSize(.small)
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Sign In")
                                .font(AppTheme.Typography.headline)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(PremiumButtonStyle(variant: .primary))
                    .disabled(isLoading)
                    .keyboardShortcut(.return)
                    
                    // Create Account
                    Button("Create Account") {
                        showSignup = true
                    }
                    .buttonStyle(LinkButtonStyle())
                }
                .padding(40)
                .frame(width: 420)
                .glassCard() // Custom DesignSystem modifier
                
                // Network Status Pill
                if !offlineQueue.isOnline {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 8, height: 8)
                        Text("Offline Mode")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(Capsule())
                }
                
                // Error Toast
                if showError {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .font(AppTheme.Typography.subheadline)
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(AppTheme.cardCornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 10)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
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
        .animation(AppTheme.Animation.standard, value: showError)
        .animation(AppTheme.Animation.standard, value: loginMode)
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
            VStack(spacing: 4) {
                Text("Enter PIN")
                    .font(AppTheme.Typography.title3)
                Text("Use your 6-digit staff PIN")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(.secondary)
            }
            
            /*
            TextField("Employee Number", text: $employeeNumber)
                .textFieldStyle(.roundedBorder)
                .textContentType(.username)
            */
            
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
                    HStack(spacing: 16) {
                        ForEach(1...3, id: \.self) { col in
                            let number = row * 3 + col
                            pinButton(number: number)
                        }
                    }
                }
                
                HStack(spacing: 16) {
                    Button(action: { pinCode = "" }) {
                        Text("Clear")
                            .font(AppTheme.Typography.subheadline)
                            .foregroundColor(.red)
                            .frame(width: 80, height: 60)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(16)
                    }
                    .buttonStyle(.plain)
                    
                    pinButton(number: 0)
                    
                    Button(action: {
                        if !pinCode.isEmpty {
                            pinCode.removeLast()
                        }
                    }) {
                        Image(systemName: "delete.left.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .frame(width: 80, height: 60)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(16)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Text("Session timeout 15 minutes after 5 failed attempts")
                .font(AppTheme.Typography.caption)
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
                .font(.title) // Larger font
                .fontWeight(.light)
                .frame(width: 80, height: 60)
                .background(.ultraThinMaterial) // Glass buttons
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
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
                    guard !pinCode.isEmpty else {
                        await MainActor.run {
                            showErrorMessage("Please enter PIN")
                            isLoading = false
                        }
                        return
                    }
                    
                    // Try Supabase PIN auth first
                    if offlineQueue.isOnline {
                        print("🌐 Online - using Supabase PIN auth")
                        try await supabaseAuth.signInWithPIN(
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
                        // employeeNumber = ""
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
