//
//  SuppliersListView.swift
//  ProTech
//
//  Supplier management
//

import SwiftUI

struct SuppliersListView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Supplier.name, ascending: true)]
    ) var suppliers: FetchedResults<Supplier>
    
    @State private var showingAddSupplier = false
    @State private var selectedSupplier: Supplier?
    @State private var searchText = ""
    
    var filteredSuppliers: [Supplier] {
        if searchText.isEmpty {
            return Array(suppliers)
        }
        return suppliers.filter {
            ($0.name?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            ($0.contactName?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search suppliers...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(10)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .padding()
            
            Divider()
            
            // List
            if filteredSuppliers.isEmpty {
                emptyStateView
            } else {
                List {
                    ForEach(filteredSuppliers, id: \.id) { supplier in
                        SupplierRow(supplier: supplier)
                            .onTapGesture {
                                selectedSupplier = supplier
                            }
                    }
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle("Suppliers")
        .toolbar {
            Button {
                showingAddSupplier = true
            } label: {
                Label("Add Supplier", systemImage: "plus")
            }
        }
        .sheet(isPresented: $showingAddSupplier) {
            AddSupplierView()
        }
        .sheet(item: $selectedSupplier) { supplier in
            SupplierDetailView(supplier: supplier)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "building.2")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No Suppliers")
                .font(.title2)
            Button {
                showingAddSupplier = true
            } label: {
                Label("Add First Supplier", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SupplierRow: View {
    @ObservedObject var supplier: Supplier
    
    var body: some View {
        HStack {
            Image(systemName: "building.2.fill")
                .font(.title2)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(supplier.name ?? "Unknown")
                    .font(.headline)
                if let contact = supplier.contactName {
                    Text(contact)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if !supplier.isActive {
                Text("Inactive")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

// Placeholder views
struct AddSupplierView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var name = ""
    @State private var contactPerson = ""
    @State private var email = ""
    @State private var phone = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Supplier Name *", text: $name)
                    TextField("Contact Person", text: $contactPerson)
                    TextField("Email", text: $email)
                    TextField("Phone", text: $phone)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Add Supplier")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        _ = InventoryService.shared.createSupplier(
                            name: name,
                            contactName: contactPerson.isEmpty ? nil : contactPerson,
                            email: email.isEmpty ? nil : email,
                            phone: phone.isEmpty ? nil : phone
                        )
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .frame(width: 500, height: 400)
    }
}

struct SupplierDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let supplier: Supplier
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Information") {
                    LabeledContent("Name", value: supplier.name ?? "—")
                    if let contact = supplier.contactName {
                        LabeledContent("Contact", value: contact)
                    }
                    if let email = supplier.email {
                        LabeledContent("Email", value: email)
                    }
                    if let phone = supplier.phone {
                        LabeledContent("Phone", value: phone)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(supplier.name ?? "Supplier")
            .toolbar {
                ToolbarItem {
                    Button("Close") { dismiss() }
                }
            }
        }
        .frame(width: 500, height: 600)
    }
}
