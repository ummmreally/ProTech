//
//  SupplierListView.swift
//  ProTech
//
//  Management view for suppliers/vendors.
//

import SwiftUI
import CoreData

struct SupplierListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Supplier.name, ascending: true)],
        predicate: NSPredicate(format: "isActive == true"),
        animation: .default)
    private var suppliers: FetchedResults<Supplier>
    
    @State private var showingAddSheet = false
    @State private var selectedSupplier: Supplier?
    
    var body: some View {
        List {
            ForEach(suppliers) { supplier in
                Button {
                    selectedSupplier = supplier
                } label: {
                    VStack(alignment: .leading) {
                        Text(supplier.name ?? "Unknown Supplier")
                            .font(.headline)
                        if let contact = supplier.contactName {
                            Text("Contact: \(contact)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .onDelete(perform: deleteSuppliers)
        }
        .navigationTitle("Suppliers")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddSheet = true }) {
                    Label("Add Supplier", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            SupplierEditView(supplier: nil)
        }
        .sheet(item: $selectedSupplier) { supplier in
            SupplierEditView(supplier: supplier)
        }
    }
    
    private func deleteSuppliers(offsets: IndexSet) {
        withAnimation {
            offsets.map { suppliers[$0] }.forEach(viewContext.delete)
            CoreDataManager.shared.save()
        }
    }
}

struct SupplierEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    let supplier: Supplier?
    
    @State private var name = ""
    @State private var contactName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var website = ""
    
    init(supplier: Supplier?) {
        self.supplier = supplier
        _name = State(initialValue: supplier?.name ?? "")
        _contactName = State(initialValue: supplier?.contactName ?? "")
        _email = State(initialValue: supplier?.email ?? "")
        _phone = State(initialValue: supplier?.phone ?? "")
        _website = State(initialValue: supplier?.website ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Company Info") {
                    TextField("Company Name", text: $name)
                    TextField("Website", text: $website)
                        .textContentType(.URL)
                        #if os(iOS)
                        .keyboardType(.URL)
                        #endif
                }
                
                Section("Contact Person") {
                    TextField("Contact Name", text: $contactName)
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        #if os(iOS)
                        .keyboardType(.emailAddress)
                        #endif
                    TextField("Phone", text: $phone)
                        .textContentType(.telephoneNumber)
                        #if os(iOS)
                        .keyboardType(.phonePad)
                        #endif
                }
            }
            .navigationTitle(supplier == nil ? "New Supplier" : "Edit Supplier")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func save() {
        let s = supplier ?? Supplier(context: viewContext)
        if supplier == nil {
            s.id = UUID()
            s.createdAt = Date()
            s.isActive = true
        }
        
        s.name = name
        s.contactName = contactName
        s.email = email
        s.phone = phone
        s.website = website
        s.updatedAt = Date()
        
        CoreDataManager.shared.save()
        dismiss()
    }
}
