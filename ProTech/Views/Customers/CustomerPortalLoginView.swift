//
//  CustomerPortalLoginView.swift
//  ProTech
//
//  Customer Portal Login - Authentication for customer access
//

import SwiftUI

struct CustomerPortalLoginView: View {
    @StateObject private var portalService = CustomerPortalService.shared
    @State private var loginMethod: LoginMethod = .email
    @State private var emailInput = ""
    @State private var phoneInput = ""
    @State private var verificationCode = ""
    @State private var showingVerification = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var authenticatedCustomer: Customer?
    @State private var showingPortal = false
    
    enum LoginMethod {
        case email
        case phone
    }
    
    var body: some View {
        ZStack {
            if let customer = authenticatedCustomer, showingPortal {
                CustomerPortalView(customer: customer)
            } else {
                loginScreen
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .customerPortalLogout)) { _ in
            logout()
        }
    }
    
    private var loginScreen: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Customer Portal")
                    .font(.largeTitle)
                    .bold()
                
                Text("Access your repair status, invoices, and estimates")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 60)
            .padding(.bottom, 40)
            
            // Login Form
            VStack(spacing: 24) {
                // Login Method Picker
                Picker("Login Method", selection: $loginMethod) {
                    Text("Email").tag(LoginMethod.email)
                    Text("Phone").tag(LoginMethod.phone)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 40)
                
                // Input Field
                VStack(alignment: .leading, spacing: 8) {
                    if loginMethod == .email {
                        Text("Email Address")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("your.email@example.com", text: $emailInput)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.emailAddress)
                    } else {
                        Text("Phone Number")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("(555) 123-4567", text: $phoneInput)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.telephoneNumber)
                    }
                }
                .padding(.horizontal, 40)
                
                // Error Message
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                // Login Button
                Button {
                    Task {
                        await login()
                    }
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                        } else {
                            Text("Access Portal")
                                .bold()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canLogin ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!canLogin || isLoading)
                .padding(.horizontal, 40)
                
                // Help Text
                VStack(spacing: 8) {
                    Text("First time here?")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Use the email or phone number you provided when dropping off your device.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)
                .padding(.top, 8)
            }
            
            Spacer()
            
            // Footer
            VStack(spacing: 8) {
                Text("ProTech Repair Management")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Secure customer portal")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 20)
        }
        .frame(maxWidth: 500)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
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
        } else {
            errorMessage = "No account found with this \(loginMethod == .email ? "email" : "phone number"). Please check your information or contact us."
        }
        
        isLoading = false
    }
    
    private func logout() {
        withAnimation {
            showingPortal = false
            authenticatedCustomer = nil
            emailInput = ""
            phoneInput = ""
            errorMessage = nil
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
