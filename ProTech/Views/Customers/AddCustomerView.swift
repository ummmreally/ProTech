//
//  AddCustomerView.swift
//  ProTech
//
//  Add new customer form
//

import SwiftUI
import CoreData

struct AddCustomerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var notes = ""
    
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
        }
        .frame(width: 500, height: 500)
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
        customer.cloudSyncStatus = "local"
        
        CoreDataManager.shared.save()
        dismiss()
    }
}
