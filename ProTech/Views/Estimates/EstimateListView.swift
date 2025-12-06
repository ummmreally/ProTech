//
//  EstimateListView.swift
//  ProTech
//
//  Estimates list and management
//

import SwiftUI
import CoreData

struct EstimateListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Estimate.createdAt, ascending: false)],
        animation: .default
    ) var estimates: FetchedResults<Estimate>
    
    @State private var searchText = ""
    @State private var filterStatus: String? = nil
    @State private var showingCreateEstimate = false
    @State private var selectedEstimate: Estimate?
    @State private var portalAlert: PortalAlert?
    
    struct PortalAlert: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }
    
    var filteredEstimates: [Estimate] {
        var filtered = Array(estimates)
        
        if !searchText.isEmpty {
            filtered = filtered.filter {
                ($0.estimateNumber?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (fetchCustomerName(for: $0).localizedCaseInsensitiveContains(searchText))
            }
        }
        
        if let status = filterStatus {
            filtered = filtered.filter { $0.status == status }
        }
        
        return filtered
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filters
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search estimates...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(AppTheme.Spacing.sm)
                .background(AppTheme.Colors.cardBackground.opacity(0.5))
                .cornerRadius(AppTheme.cardCornerRadius)
                
                Picker("Status", selection: $filterStatus) {
                    Text("All").tag(String?.none)
                    Text("Pending").tag(String?("pending"))
                    Text("Approved").tag(String?("approved"))
                    Text("Declined").tag(String?("declined"))
                    Text("Expired").tag(String?("expired"))
                }
                .frame(width: 150)
                
                Text("\(filteredEstimates.count) estimates")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(.secondary)
            }
            .padding(AppTheme.Spacing.xl)
            
            Divider()
            
            // List
            if filteredEstimates.isEmpty {
                emptyStateView
            } else {
                List {
                    ForEach(filteredEstimates, id: \.id) { estimate in
                        EstimateRow(estimate: estimate)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedEstimate = estimate
                            }
                            .contextMenu {
                                if estimate.status == "pending" {
                                    Button {
                                        approveEstimate(estimate)
                                    } label: {
                                        Label("Approve", systemImage: "checkmark.circle")
                                    }
                                    
                                    Button {
                                        declineEstimate(estimate)
                                    } label: {
                                        Label("Decline", systemImage: "xmark.circle")
                                    }
                                }
                                
                                if estimate.status == "approved" {
                                    Button {
                                        convertToInvoice(estimate)
                                    } label: {
                                        Label("Convert to Invoice", systemImage: "doc.text.fill")
                                    }
                                }
                                
                                Button {
                                    duplicateEstimate(estimate)
                                } label: {
                                    Label("Duplicate", systemImage: "doc.on.doc")
                                }
                                
                                Divider()
                                
                                Button(role: .destructive) {
                                    deleteEstimate(estimate)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle("Estimates")
        .toolbar {
            Button {
                showingCreateEstimate = true
            } label: {
                Label("New Estimate", systemImage: "plus")
            }
        }
        .sheet(isPresented: $showingCreateEstimate) {
            EstimateGeneratorView()
        }
        .sheet(item: $selectedEstimate) { estimate in
            EstimateDetailView(estimate: estimate)
        }
        .alert(item: $portalAlert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .estimateApproved)) { notification in
            handleEstimateApproval(notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: .estimateDeclined)) { notification in
            handleEstimateDecline(notification)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Image(systemName: searchText.isEmpty ? "doc.text" : "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text(searchText.isEmpty ? "No Estimates" : "No Results Found")
                .font(AppTheme.Typography.title2)
                .foregroundColor(.secondary)
            if searchText.isEmpty {
                Button {
                    showingCreateEstimate = true
                } label: {
                    Label("Create First Estimate", systemImage: "plus")
                }
                .buttonStyle(PremiumButtonStyle(variant: .primary))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func fetchCustomerName(for estimate: Estimate) -> String {
        guard let customerId = estimate.customerId else { return "" }
        let request = Customer.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", customerId as CVarArg)
        if let customer = try? viewContext.fetch(request).first {
            return "\(customer.firstName ?? "") \(customer.lastName ?? "")"
        }
        return ""
    }
    
    private func approveEstimate(_ estimate: Estimate) {
        EstimateService.shared.approveEstimate(estimate)
    }
    
    private func declineEstimate(_ estimate: Estimate) {
        EstimateService.shared.declineEstimate(estimate)
    }
    
    private func convertToInvoice(_ estimate: Estimate) {
        if let invoice = EstimateService.shared.convertToInvoice(estimate) {
            // Success - could show confirmation
            print("Created invoice: \(invoice.invoiceNumber ?? "N/A")")
        }
    }
    
    private func duplicateEstimate(_ estimate: Estimate) {
        let _ = EstimateService.shared.duplicateEstimate(estimate)
        // Estimate will automatically appear in list due to @FetchRequest
    }
    
    private func deleteEstimate(_ estimate: Estimate) {
        viewContext.delete(estimate)
        try? viewContext.save()
    }
    
    // MARK: - Portal Notification Handlers
    
    private func handleEstimateApproval(_ notification: Notification) {
        guard let estimateId = notification.userInfo?["estimateId"] as? UUID,
              let estimate = estimates.first(where: { $0.id == estimateId }) else {
            return
        }
        
        let customerName = fetchCustomerName(for: estimate)
        portalAlert = PortalAlert(
            title: "✅ Estimate Approved",
            message: "\(estimate.formattedEstimateNumber) was approved by \(customerName) via the Customer Portal."
        )
    }
    
    private func handleEstimateDecline(_ notification: Notification) {
        guard let estimateId = notification.userInfo?["estimateId"] as? UUID,
              let estimate = estimates.first(where: { $0.id == estimateId }) else {
            return
        }
        
        let customerName = fetchCustomerName(for: estimate)
        let reason = notification.userInfo?["reason"] as? String
        
        var message = "\(estimate.formattedEstimateNumber) was declined by \(customerName) via the Customer Portal."
        if let reason = reason, !reason.isEmpty {
            message += "\n\nReason: \(reason)"
        }
        
        portalAlert = PortalAlert(
            title: "❌ Estimate Declined",
            message: message
        )
    }
}

// MARK: - Estimate Row

struct EstimateRow: View {
    @ObservedObject var estimate: Estimate
    @Environment(\.managedObjectContext) private var viewContext
    
    var customer: Customer? {
        guard let customerId = estimate.customerId else { return nil }
        let request = Customer.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", customerId as CVarArg)
        return try? viewContext.fetch(request).first
    }
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Status Indicator
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                HStack {
                    Text(estimate.estimateNumber ?? "EST-000")
                        .font(AppTheme.Typography.headline)
                    
                    if estimate.isExpired {
                        Text("EXPIRED")
                            .font(AppTheme.Typography.caption2)
                            .bold()
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.2))
                            .foregroundColor(.red)
                            .cornerRadius(4)
                    }
                }
                
                if let customer = customer {
                    Text("\(customer.firstName ?? "") \(customer.lastName ?? "")")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: AppTheme.Spacing.sm) {
                    if let created = estimate.createdAt {
                        Text(created.formatted(date: .abbreviated, time: .omitted))
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let validUntil = estimate.validUntil {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("Valid until \(validUntil.formatted(date: .abbreviated, time: .omitted))")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: AppTheme.Spacing.xs) {
                Text(formatCurrency(estimate.total))
                    .font(AppTheme.Typography.headline)
                
                Text(estimate.status?.capitalized ?? "Pending")
                    .font(AppTheme.Typography.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(statusColor.opacity(0.2))
                    .foregroundColor(statusColor)
                    .cornerRadius(6)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var statusColor: Color {
        switch estimate.status {
        case "approved": return .green
        case "declined": return .red
        case "expired": return .orange
        default: return .blue
        }
    }
    
    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: value as NSDecimalNumber) ?? "$0.00"
    }
}
