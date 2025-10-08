//
//  AdminUnlockView.swift
//  ProTech
//
//  Admin passcode entry to exit kiosk mode
//

import SwiftUI

struct AdminUnlockView: View {
    @ObservedObject var kioskManager = KioskModeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var passcode = ""
    @State private var showError = false
    @State private var attempts = 0
    @FocusState private var isPasscodeFocused: Bool
    
    private let maxAttempts = 3
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
                
                Text("Admin Access Required")
                    .font(.largeTitle)
                    .bold()
                
                Text("Enter passcode to exit kiosk mode")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 60)
            .padding(.bottom, 40)
            
            // Passcode Field
            VStack(spacing: 16) {
                SecureField("Enter Passcode", text: $passcode)
                    .textFieldStyle(.roundedBorder)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
                    .focused($isPasscodeFocused)
                    .onSubmit {
                        validatePasscode()
                    }
                
                if showError {
                    Text("Incorrect passcode. \(maxAttempts - attempts) attempt\(maxAttempts - attempts == 1 ? "" : "s") remaining.")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Buttons
            HStack(spacing: 16) {
                Button("Cancel") {
                    kioskManager.cancelAdminUnlock()
                    dismiss()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)
                
                Button("Unlock") {
                    validatePasscode()
                }
                .buttonStyle(.borderedProminent)
                .disabled(passcode.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.bottom, 40)
        }
        .frame(maxWidth: 500)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
        .onAppear {
            isPasscodeFocused = true
        }
    }
    
    private func validatePasscode() {
        if kioskManager.disableKioskMode(withPasscode: passcode) {
            // Success - exit kiosk mode
            dismiss()
        } else {
            // Failed attempt
            attempts += 1
            showError = true
            passcode = ""
            
            if attempts >= maxAttempts {
                // Lock out for security (optional)
                DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                    attempts = 0
                }
            }
            
            // Shake animation feedback
            withAnimation(.default.repeatCount(3)) {
                isPasscodeFocused = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPasscodeFocused = true
            }
        }
    }
}

#Preview {
    AdminUnlockView()
}
