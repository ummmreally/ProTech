//
//  CustomerListView.swift
//  ProTech
//
//  Customer list view with search and CRUD operations
//

import SwiftUI
import CoreData

struct CustomerListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Customer.lastName, ascending: true)],
        animation: .default
    ) private var customers: FetchedResults<Customer>
    
    @State private var searchText = ""
    @State private var showingAddCustomer = false
    @State private var selectedCustomer: Customer?
    @State private var isRefreshing = false
    @StateObject private var customerSyncer = CustomerSyncer()
    
    var filteredCustomers: [Customer] {
        if searchText.isEmpty {
            return Array(customers)
        } else {
            return customers.filter { customer in
                (customer.firstName?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (customer.lastName?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (customer.email?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (customer.phone?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Offline Banner
                OfflineBanner()
                
                // Header
                HStack {
                    Text("Customers")
                        .font(.largeTitle)
                        .bold()
                    
                    // Sync Status Badge
                    SyncStatusBadge()
                    
                    Spacer()
                    Button {
                        showingAddCustomer = true
                    } label: {
                        Label("Add Customer", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search customers...", text: $searchText)
                        .textFieldStyle(.plain)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
                
                Divider()
                    .padding(.top)
                
                // Customer list
                if filteredCustomers.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "person.3")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text(searchText.isEmpty ? "No customers yet" : "No customers found")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        if searchText.isEmpty {
                            Button {
                                showingAddCustomer = true
                            } label: {
                                Label("Add Your First Customer", systemImage: "plus")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredCustomers) { customer in
                            NavigationLink {
                                CustomerDetailView(customer: customer)
                            } label: {
                                CustomerRowView(customer: customer)
                            }
                        }
                        .onDelete(perform: deleteCustomers)
                    }
                    .listStyle(.inset)
                }
            }
            .sheet(isPresented: $showingAddCustomer) {
                AddCustomerView()
            }
            .onReceive(NotificationCenter.default.publisher(for: .newCustomer)) { _ in
                showingAddCustomer = true
            }
            .pullToRefresh(isRefreshing: $isRefreshing) {
                do {
                    try await customerSyncer.download()
                } catch {
                    print("⚠️ Failed to sync customers: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func deleteCustomers(offsets: IndexSet) {
        for index in offsets {
            let customer = filteredCustomers[index]
            
            // For Supabase sync, we should soft-delete (mark as deleted)
            // but Core Data doesn't have a deletedAt field for Customer yet
            // For now, hard delete locally and sync deletion to Supabase
            Task { @MainActor in
                // TODO: Implement soft delete when Customer model has deletedAt field
                // For now, just delete - Supabase will handle via RLS policies
                CoreDataManager.shared.deleteCustomer(customer)
            }
        }
    }
}

// MARK: - Customer Row View

struct CustomerRowView: View {
    let customer: Customer
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar circle with initials
            Circle()
                .fill(Color.blue.gradient)
                .frame(width: 40, height: 40)
                .overlay {
                    Text(initials)
                        .font(.headline)
                        .foregroundColor(.white)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(customer.firstName ?? "") \(customer.lastName ?? "")")
                    .font(.headline)
                
                if let phone = customer.phone {
                    Text(phone)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let email = customer.email {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Sync status indicator
            if let syncStatus = customer.cloudSyncStatus {
                syncStatusIcon(for: syncStatus)
            }
            
            if let createdAt = customer.createdAt {
                Text(createdAt, format: .dateTime.month().day())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func syncStatusIcon(for status: String) -> some View {
        Group {
            switch status {
            case "synced":
                Image(systemName: "checkmark.icloud.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                    .help("Synced to cloud")
            case "pending":
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.orange)
                    .font(.caption)
                    .help("Sync pending")
            case "failed":
                Image(systemName: "exclamationmark.icloud.fill")
                    .foregroundColor(.red)
                    .font(.caption)
                    .help("Sync failed - will retry")
            default:
                EmptyView()
            }
        }
        .padding(.vertical, 4)
    }
    
    private var initials: String {
        let first = customer.firstName?.prefix(1).uppercased() ?? ""
        let last = customer.lastName?.prefix(1).uppercased() ?? ""
        return first + last
    }
}
