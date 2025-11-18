//
//  EditCustomerView.swift
//  ProTech
//
//  Edit existing customer
//

import SwiftUI

struct EditCustomerView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var customer: Customer
    
    @State private var firstName: String
    @State private var lastName: String
    @State private var email: String
    @State private var phone: String
    @State private var address: String
    @State private var notes: String
    
    init(customer: Customer) {
        self.customer = customer
        _firstName = State(initialValue: customer.firstName ?? "")
        _lastName = State(initialValue: customer.lastName ?? "")
        _email = State(initialValue: customer.email ?? "")
        _phone = State(initialValue: customer.phone ?? "")
        _address = State(initialValue: customer.address ?? "")
        _notes = State(initialValue: customer.notes ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Customer Information") {
                    TextField("First Name *", text: $firstName)
                    TextField("Last Name *", text: $lastName)
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                    TextField("Phone", text: $phone)
                        .textContentType(.telephoneNumber)
                    TextField("Address", text: $address)
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Edit Customer")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(firstName.isEmpty || lastName.isEmpty)
                }
            }
        }
        .frame(width: 500, height: 500)
    }
    
    private func saveChanges() {
        customer.firstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        customer.lastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        customer.email = email.isEmpty ? nil : email.trimmingCharacters(in: .whitespacesAndNewlines)
        customer.phone = phone.isEmpty ? nil : phone.trimmingCharacters(in: .whitespacesAndNewlines)
        customer.address = address.isEmpty ? nil : address.trimmingCharacters(in: .whitespacesAndNewlines)
        customer.notes = notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines)
        customer.updatedAt = Date()
        customer.cloudSyncStatus = "pending"
        
        CoreDataManager.shared.save()
        
        // Sync to Supabase in background
        Task { @MainActor in
            do {
                let syncer = CustomerSyncer()
                try await syncer.upload(customer)
                customer.cloudSyncStatus = "synced"
                try? CoreDataManager.shared.viewContext.save()
            } catch {
                customer.cloudSyncStatus = "failed"
                try? CoreDataManager.shared.viewContext.save()
                print("⚠️ Customer sync failed: \(error.localizedDescription)")
            }
        }
        
        dismiss()
    }
}
