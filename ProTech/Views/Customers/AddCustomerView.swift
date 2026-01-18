//
//  AddCustomerView.swift
//  ProTech
//
//  Add new customer form
//

import SwiftUI
import CoreData

struct AddCustomerView: View {
    let onSave: ((Customer) -> Void)?
    let onCancel: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var notes = ""
    @State private var errorMessage: String?
    @State private var showError = false
    
    init(onSave: ((Customer) -> Void)? = nil, onCancel: (() -> Void)? = nil) {
        self.onSave = onSave
        self.onCancel = onCancel
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Customer Information") {
                    TextField("First Name *", text: $firstName)
                    TextField("Last Name *", text: $lastName)
                    TextField("Email", text: $email)
#if os(iOS)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
#endif
                    TextField("Phone", text: $phone)
#if os(iOS)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
#endif
                    TextField("Address", text: $address)
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                        .font(.body)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("New Customer")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel?()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveCustomer()
                    }
                    .disabled(firstName.isEmpty || lastName.isEmpty)
                }
            }
            .alert("Unable to Save Customer", isPresented: $showError, presenting: errorMessage) { _ in
                Button("OK", role: .cancel) {}
            } message: { message in
                Text(message)
            }
        }
        .frame(minWidth: 600, minHeight: 600)
    }
    
    private func saveCustomer() {
        let customer = Customer(context: viewContext)
        customer.id = UUID()
        customer.firstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        customer.lastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        customer.email = email.isEmpty ? nil : email.trimmingCharacters(in: .whitespacesAndNewlines)
        customer.phone = phone.isEmpty ? nil : phone.trimmingCharacters(in: .whitespacesAndNewlines)
        customer.address = address.isEmpty ? nil : address.trimmingCharacters(in: .whitespacesAndNewlines)
        customer.notes = notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines)
        customer.createdAt = Date()
        customer.updatedAt = Date()
        customer.cloudSyncStatus = "pending"
        
        do {
            try viewContext.save()
            
            // Sync to Supabase in background
            Task { @MainActor in
                do {
                    let syncer = CustomerSyncer()
                    try await syncer.upload(customer)
                    customer.cloudSyncStatus = "synced"
                    try? viewContext.save()
                } catch {
                    customer.cloudSyncStatus = "failed"
                    try? viewContext.save()
                    print("⚠️ Customer sync failed: \(error.localizedDescription)")
                    // Don't block user flow - will retry later
                }
            }
            
            
            // Sync to Supabase in background
            Task { @MainActor in
                do {
                    let syncer = CustomerSyncer()
                    try await syncer.upload(customer)
                    customer.cloudSyncStatus = "synced"
                    try? viewContext.save()
                } catch {
                    customer.cloudSyncStatus = "failed"
                    try? viewContext.save()
                    print("⚠️ Customer sync failed: \(error.localizedDescription)")
                    // Don't block user flow - will retry later
                }
            }
            
            onSave?(customer)
            NotificationManager.shared.post(title: "Customer Added", message: "\(customer.firstName ?? "") \(customer.lastName ?? "") added successfully.", type: .success)
            dismiss()
        } catch {
            viewContext.delete(customer)
            errorMessage = error.localizedDescription
            NotificationManager.shared.post(title: "Error Saving Customer", message: error.localizedDescription, type: .error)
            showError = true
        }
    }
}
