//
//  CustomerSelfRegistrationView.swift
//  ProTech
//
//  Self-service customer registration for kiosk mode
//

import SwiftUI

struct CustomerSelfRegistrationView: View {
    let prefilledEmail: String?
    let prefilledPhone: String?
    let onComplete: (Customer) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Information") {
                    TextField("First Name", text: $firstName)
                        .textContentType(.givenName)
                    
                    TextField("Last Name", text: $lastName)
                        .textContentType(.familyName)
                }
                
                Section("Contact Information") {
                    TextField("Email Address", text: $email)
                        .textContentType(.emailAddress)
                    
                    TextField("Phone Number", text: $phone)
                        .textContentType(.telephoneNumber)
                }
                
                Section(footer: Text("We'll use this information to notify you about your repairs.")) {
                    Button {
                        Task {
                            await submitRegistration()
                        }
                    } label: {
                        if isSubmitting {
                            HStack {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Creating Profile...")
                            }
                        } else {
                            Text("Create Profile")
                        }
                    }
                    .disabled(!isValid || isSubmitting)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Create Profile")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .frame(width: 600, height: 520)
        .onAppear {
            if let email = prefilledEmail {
                self.email = email
            }
            if let phone = prefilledPhone {
                self.phone = phone
            }
        }
    }
    
    // MARK: - Validation
    
    private var isValid: Bool {
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Submission
    
    private func submitRegistration() async {
        isSubmitting = true
        
        // Create new customer
        let newCustomer = Customer(context: viewContext)
        newCustomer.id = UUID()
        newCustomer.firstName = firstName
        newCustomer.lastName = lastName
        newCustomer.email = email
        newCustomer.phone = phone
        newCustomer.createdAt = Date()
        newCustomer.updatedAt = Date()
        
        do {
            try viewContext.save()
            
            // Small delay for UX
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            // Notify admin of new walk-in customer
            NotificationCenter.default.post(
                name: .customerSelfRegistered,
                object: nil,
                userInfo: ["customerId": newCustomer.id as Any]
            )
            
            isSubmitting = false
            onComplete(newCustomer)
        } catch {
            isSubmitting = false
            print("Error creating customer: \(error)")
        }
    }
}

// MARK: - Success View

struct RegistrationSuccessView: View {
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(.green)
            
            Text("Profile Created!")
                .font(.largeTitle)
                .bold()
            
            Text("Please have a seat")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("A team member will call you shortly")
                .font(.body)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .frame(minWidth: 400, minHeight: 300)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }
}

#Preview {
    CustomerSelfRegistrationView(prefilledEmail: nil, prefilledPhone: nil) { _ in }
}
