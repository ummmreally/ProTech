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
    @StateObject private var customerSyncer = SquareCustomerSyncManager.shared
    
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
                        .font(AppTheme.Typography.largeTitle)
                        .bold()
                    
                    // Sync Status Badge
                    SyncStatusBadge()
                    
                    Spacer()
                    Button {
                       showingAddCustomer = true
                    } label: {
                        Label("Add Customer", systemImage: "plus")
                    }
                    .buttonStyle(PremiumButtonStyle(variant: .primary))
                    
                    // Sync Button
                    Button {
                        Task {
                            await customerSyncer.syncCustomersFromSquare()
                        }
                    } label: {
                        if customerSyncer.syncStatus == .syncing {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                    }
                    .buttonStyle(PremiumButtonStyle(variant: .secondary))
                    .disabled(customerSyncer.syncStatus == .syncing)
                    .help("Sync customers with Square")
                }
                .padding(AppTheme.Spacing.xl)
                
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
                .padding(AppTheme.Spacing.sm)
                .background(AppTheme.Colors.cardBackground.opacity(0.5))
                .cornerRadius(AppTheme.cardCornerRadius)
                .padding(.horizontal)
                
                Divider()
                    .padding(.top)
                
                // Customer list
                if filteredCustomers.isEmpty {
                    VStack(spacing: AppTheme.Spacing.xl) {
                        Image(systemName: "person.3")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text(searchText.isEmpty ? "No customers yet" : "No customers found")
                            .font(AppTheme.Typography.title2)
                            .foregroundColor(.secondary)
                        if searchText.isEmpty {
                            Button {
                                showingAddCustomer = true
                            } label: {
                                Label("Add Your First Customer", systemImage: "plus")
                            }
                            .buttonStyle(PremiumButtonStyle(variant: .primary))
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
                await customerSyncer.syncCustomersFromSquare()
                isRefreshing = false
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
        HStack(spacing: AppTheme.Spacing.md) {
            // Avatar circle with initials
            Circle()
                .fill(Color.blue.gradient)
                .frame(width: 40, height: 40)
                .overlay {
                    Text(initials)
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(.white)
                }
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("\(customer.firstName ?? "") \(customer.lastName ?? "")")
                    .font(AppTheme.Typography.headline)
                
                if let phone = customer.phone {
                    Text(phone)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(.secondary)
                }
                
                if let email = customer.email {
                    Text(email)
                        .font(AppTheme.Typography.caption)
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
                    .font(AppTheme.Typography.caption)
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
                    .font(AppTheme.Typography.caption)
                    .help("Synced to cloud")
            case "pending":
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.orange)
                    .font(AppTheme.Typography.caption)
                    .help("Sync pending")
            case "failed":
                Image(systemName: "exclamationmark.icloud.fill")
                    .foregroundColor(.red)
                    .font(AppTheme.Typography.caption)
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
