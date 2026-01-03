//
//  SharedPickers.swift
//  ProTech
//
//  Created for ProTech POS Overhaul
//

import SwiftUI

// MARK: - Customer Picker View

struct CustomerPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedCustomer: Customer?
    
    @State private var customers: [Customer] = []
    @State private var searchText = ""
    
    private let coreDataManager = CoreDataManager.shared
    
    var filteredCustomers: [Customer] {
        if searchText.isEmpty {
            return customers
        }
        return customers.filter { customer in
            let name = "\(customer.firstName ?? "") \(customer.lastName ?? "")"
            return name.localizedCaseInsensitiveContains(searchText) ||
                   customer.email?.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search customers...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(AppTheme.Typography.body)
                }
                .padding(12)
                .background(AppTheme.Colors.groupedBackground)
                .cornerRadius(AppTheme.cornerRadius)
                .padding()
                
                Divider()
                
                // Walk-in option
                Button(action: {
                    selectedCustomer = nil
                    dismiss()
                }) {
                    HStack {
                        Circle()
                            .fill(AppTheme.Colors.groupedBackground)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "person.fill.questionmark")
                                    .foregroundColor(.secondary)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Walk-in Customer")
                                .font(AppTheme.Typography.headline)
                                .foregroundColor(.primary)
                            Text("No customer selected")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if selectedCustomer == nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppTheme.Colors.success)
                        }
                    }
                    .padding()
                    .background(selectedCustomer == nil ? AppTheme.Colors.success.opacity(0.1) : Color.clear)
                }
                .buttonStyle(.plain)
                
                Divider()
                
                // Customer list
                List(filteredCustomers) { customer in
                    Button(action: {
                        selectedCustomer = customer
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(customer.firstName ?? "") \(customer.lastName ?? "")")
                                    .font(AppTheme.Typography.headline)
                                    .foregroundColor(.primary)
                                
                                if let email = customer.email {
                                    Text(email)
                                        .font(AppTheme.Typography.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if selectedCustomer?.id == customer.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppTheme.Colors.success)
                            }
                        }
                    }
                    .listRowBackground(AppTheme.Colors.cardBackground)
                }
                .listStyle(.plain)
            }
            .navigationTitle("Select Customer")
            .background(AppTheme.Colors.cardBackground)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 600, height: 500)
        .onAppear {
            customers = coreDataManager.fetchCustomers()
        }
    }
}

// MARK: - Ticket Picker View

struct TicketPickerView: View {
    @Environment(\.dismiss) var dismiss
    let customerId: UUID?
    @Binding var selectedTicket: Ticket?
    
    @State private var tickets: [Ticket] = []
    
    private let coreDataManager = CoreDataManager.shared
    
    var body: some View {
        NavigationStack {
            List(tickets) { ticket in
                Button(action: {
                    selectedTicket = ticket
                    dismiss()
                }) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ticket #\(ticket.ticketNumber)")
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(.primary)
                        
                        if let device = ticket.deviceType {
                            Text("\(device) - \(ticket.deviceModel ?? "")")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if let status = ticket.status {
                            Text("Status: \(status)")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .listRowBackground(AppTheme.Colors.cardBackground)
            }
            .listStyle(.plain)
            .navigationTitle("Select Ticket")
            .background(AppTheme.Colors.cardBackground)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 600, height: 500)
        .onAppear {
            loadTickets()
        }
    }
    
    private func loadTickets() {
        guard let customerId = customerId else { return }
        
        let request = Ticket.fetchRequest()
        request.predicate = NSPredicate(format: "customerId == %@", customerId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Ticket.createdAt, ascending: false)]
        
        tickets = (try? coreDataManager.viewContext.fetch(request)) ?? []
    }
}
