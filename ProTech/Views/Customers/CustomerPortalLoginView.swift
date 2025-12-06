//
//  CustomerPortalLoginView.swift
//  ProTech
//
//  Customer Portal Login - Authentication for customer access
//

import SwiftUI

struct CustomerPortalLoginView: View {
    @StateObject private var portalService = CustomerPortalService.shared
    @ObservedObject var kioskManager = KioskModeManager.shared
    
    @State private var loginMethod: LoginMethod = .email
    @State private var emailInput = ""
    @State private var phoneInput = ""
    @State private var verificationCode = ""
    @State private var showingVerification = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var authenticatedCustomer: Customer?
    @State private var showingPortal = false
    @State private var showingSelfRegistration = false
    @State private var customerNotFound = false
    @State private var showingAdminUnlock = false
    
    // Auto-logout timer
    @State private var inactivityTimer: Timer?
    @State private var lastActivityTime = Date()
    
    enum LoginMethod {
        case email
        case phone
    }
    
    var body: some View {
        ZStack {
            if let customer = authenticatedCustomer, showingPortal {
                CustomerPortalView(customer: customer)
                    .onTapGesture {
                        resetInactivityTimer()
                    }
            } else {
                loginScreen
            }
            
            // Hidden Admin Unlock Button (tap 5 times in corner)
            if kioskManager.isKioskModeEnabled {
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            showingAdminUnlock = true
                        } label: {
                            Color.clear
                                .frame(width: 50, height: 50)
                        }
                        .buttonStyle(.plain)
                        .keyboardShortcut("q", modifiers: [.command, .shift])
                    }
                    Spacer()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .customerPortalLogout)) { _ in
            logout()
        }
        .sheet(isPresented: $showingSelfRegistration) {
            CustomerSelfRegistrationView(
                prefilledEmail: loginMethod == .email ? emailInput : nil,
                prefilledPhone: loginMethod == .phone ? phoneInput : nil
            ) { newCustomer in
                showingSelfRegistration = false
                authenticatedCustomer = newCustomer
                withAnimation {
                    showingPortal = true
                }
                if kioskManager.isKioskModeEnabled {
                    startInactivityTimer()
                }
            }
        }
        .sheet(isPresented: $showingAdminUnlock) {
            AdminUnlockView()
        }
    }
    
    private var loginScreen: some View {
        ZStack {
            // Subtle background gradient
            LinearGradient(
                colors: [
                    Color(hex: "f8f9fa"),
                    Color(hex: "e9ecef")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Header with gradient icon
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Gradient circle icon
                    ZStack {
                        Circle()
                            .fill(AppTheme.Colors.portalWelcome)
                            .frame(width: 120, height: 120)
                            .shadow(color: Color(hex: "a855f7").opacity(0.3), radius: 20, x: 0, y: 10)
                        
                        Image(systemName: "hand.wave.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    }
                    
                    VStack(spacing: AppTheme.Spacing.sm) {
                        Text(kioskManager.isKioskModeEnabled ? kioskManager.kioskTitle : "Welcome!")
                            .font(.system(.largeTitle, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(AppTheme.Colors.portalWelcome)
                        
                        Text(kioskManager.isKioskModeEnabled ? kioskManager.kioskWelcomeMessage : "Let's check on your repairs")
                            .font(AppTheme.Typography.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding(.bottom, AppTheme.Spacing.xxl)
                
                // Login Form Card
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Login Method Picker
                    Picker("Login Method", selection: $loginMethod) {
                        Label("Email", systemImage: "envelope.fill").tag(LoginMethod.email)
                        Label("Phone", systemImage: "phone.fill").tag(LoginMethod.phone)
                    }
                    .pickerStyle(.segmented)
                    
                    // Input Field
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        if loginMethod == .email {
                            Text("Email Address")
                                .font(AppTheme.Typography.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            TextField("your.email@example.com", text: $emailInput)
                                .textFieldStyle(.plain)
                                .textContentType(.emailAddress)
                                .padding(AppTheme.Spacing.lg)
                                .background(Color.white)
                                .cornerRadius(AppTheme.cardCornerRadius)
                                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                        } else {
                            Text("Phone Number")
                                .font(AppTheme.Typography.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            TextField("(555) 123-4567", text: $phoneInput)
                                .textFieldStyle(.plain)
                                .textContentType(.telephoneNumber)
                                .padding(AppTheme.Spacing.lg)
                                .background(Color.white)
                                .cornerRadius(AppTheme.cardCornerRadius)
                                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                        }
                    }
                    
                    // Error Message or Self-Registration Option
                    if customerNotFound {
                        VStack(spacing: AppTheme.Spacing.md) {
                            HStack(spacing: AppTheme.Spacing.sm) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(Color(hex: "10b981"))
                                Text("New here? Let's get you set up!")
                                    .font(AppTheme.Typography.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(hex: "10b981"))
                            }
                            
                            Text("Create your profile to track repairs and manage payments")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Button {
                                showingSelfRegistration = true
                            } label: {
                                HStack {
                                    Image(systemName: "person.badge.plus")
                                    Text("Create Profile")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(AppTheme.Spacing.lg)
                                .background(AppTheme.Colors.portalSuccess)
                                .foregroundColor(.white)
                                .cornerRadius(AppTheme.cardCornerRadius)
                                .shadow(color: Color(hex: "10b981").opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(AppTheme.Spacing.lg)
                        .background(Color(hex: "d1fae5").opacity(0.3))
                        .cornerRadius(AppTheme.cardCornerRadius)
                    } else if let error = errorMessage {
                        HStack(spacing: AppTheme.Spacing.sm) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(.red)
                        }
                        .padding(AppTheme.Spacing.md)
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(AppTheme.cardCornerRadius)
                    }
                    
                    // Login Button
                    Button {
                        Task {
                            await login()
                        }
                    } label: {
                        HStack(spacing: AppTheme.Spacing.sm) {
                            if isLoading {
                                ProgressView()
                                    .controlSize(.small)
                                    .tint(.white)
                            } else {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.title3)
                                Text("Welcome In")
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(20)
                        .background(
                            canLogin ? AppTheme.Colors.portalWelcome : LinearGradient(
                                colors: [Color.gray.opacity(0.6), Color.gray.opacity(0.4)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(AppTheme.cardCornerRadius)
                        .shadow(color: canLogin ? Color(hex: "a855f7").opacity(0.3) : Color.clear, radius: 12, x: 0, y: 6)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canLogin || isLoading)
                    .scaleEffect(canLogin ? 1.0 : 0.98)
                    .animation(.easeInOut(duration: 0.2), value: canLogin)
                    
                    // Help Text
                    if !customerNotFound {
                        VStack(spacing: AppTheme.Spacing.xs) {
                            HStack(spacing: 6) {
                                Image(systemName: "info.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "6b7280"))
                                Text("First time here?")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text("Use the email or phone you provided when dropping off your device")
                                .font(AppTheme.Typography.caption2)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, AppTheme.Spacing.sm)
                    }
                }
                .padding(AppTheme.Spacing.xxl)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 10)
                )
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Footer
                VStack(spacing: AppTheme.Spacing.xs) {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.shield.fill")
                            .font(.caption)
                            .foregroundColor(Color(hex: "10b981"))
                        Text("Secure Portal")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("ProTech Repair Management")
                        .font(AppTheme.Typography.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, AppTheme.Spacing.xl)
            }
            .frame(maxWidth: 540)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private var canLogin: Bool {
        if loginMethod == .email {
            return !emailInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } else {
            return !phoneInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
    
    private func login() async {
        isLoading = true
        errorMessage = nil
        customerNotFound = false
        
        // Simulate a small delay for UX
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        let customer: Customer?
        
        if loginMethod == .email {
            customer = portalService.findCustomer(byEmail: emailInput.trimmingCharacters(in: .whitespacesAndNewlines))
        } else {
            customer = portalService.findCustomer(byPhone: phoneInput.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        
        if let customer = customer {
            authenticatedCustomer = customer
            withAnimation {
                showingPortal = true
            }
            
            // Start auto-logout timer if in kiosk mode
            if kioskManager.isKioskModeEnabled {
                startInactivityTimer()
            }
        } else {
            // Customer not found - offer self-registration
            customerNotFound = true
        }
        
        isLoading = false
    }
    
    private func logout() {
        stopInactivityTimer()
        
        withAnimation {
            showingPortal = false
            authenticatedCustomer = nil
            emailInput = ""
            phoneInput = ""
            errorMessage = nil
            customerNotFound = false
        }
    }
    
    // MARK: - Inactivity Timer (Kiosk Mode)
    
    private func startInactivityTimer() {
        stopInactivityTimer()
        
        lastActivityTime = Date()
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            checkInactivity()
        }
    }
    
    private func stopInactivityTimer() {
        inactivityTimer?.invalidate()
        inactivityTimer = nil
    }
    
    private func resetInactivityTimer() {
        lastActivityTime = Date()
    }
    
    private func checkInactivity() {
        let elapsed = Date().timeIntervalSince(lastActivityTime)
        if elapsed >= Double(kioskManager.autoLogoutAfterSeconds) {
            logout()
        }
    }
}

// MARK: - Standalone Portal Access View

struct CustomerPortalAccessView: View {
    @State private var showingPortal = false
    
    var body: some View {
        VStack {
            if showingPortal {
                CustomerPortalLoginView()
            } else {
                portalLandingView
            }
        }
    }
    
    private var portalLandingView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "laptopcomputer")
                    .font(.system(size: 100))
                    .foregroundColor(.blue)
                
                Text("Customer Portal")
                    .font(.system(size: 48, weight: .bold))
                
                Text("Track your repairs, view invoices, and manage estimates")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                PortalFeatureRow(icon: "wrench.and.screwdriver.fill", title: "Track Repairs", description: "View real-time status of your repairs")
                PortalFeatureRow(icon: "doc.text.fill", title: "View Invoices", description: "Access and download your invoices")
                PortalFeatureRow(icon: "checkmark.circle.fill", title: "Approve Estimates", description: "Review and approve repair estimates")
                PortalFeatureRow(icon: "creditcard.fill", title: "Payment History", description: "See all your past payments")
            }
            .padding(.horizontal, 40)
            
            Button {
                withAnimation {
                    showingPortal = true
                }
            } label: {
                Text("Access Portal")
                    .font(.headline)
                    .frame(maxWidth: 300)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .padding(.top, 20)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }
}

private struct PortalFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    CustomerPortalLoginView()
}

#Preview("Landing") {
    CustomerPortalAccessView()
}
