//
//  CustomerPortalComponents.swift
//  ProTech
//
//  Reusable components for Customer Portal
//

import SwiftUI

// MARK: - Ticket Card

struct PortalTicketCard: View {
    let ticket: Ticket
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ticket #\(ticket.ticketNumber)")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(.primary)
                    
                    if let deviceType = ticket.deviceType {
                        Text(deviceType)
                            .font(AppTheme.Typography.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                PortalStatusBadge(status: ticket.status ?? "")
            }
            
            // Issue Description
            if let issue = ticket.issueDescription, !issue.isEmpty {
                Text(issue)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .padding(.vertical, 4)
            }
            
            Divider()
                .background(Color.gray.opacity(0.1))
            
            // Dates
            HStack(spacing: AppTheme.Spacing.xl) {
                if let checkedIn = ticket.checkedInAt {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Checked In")
                            .font(AppTheme.Typography.caption2)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        Text(dateFormatter.string(from: checkedIn))
                            .font(AppTheme.Typography.caption)
                            .fontWeight(.medium)
                    }
                }
                
                if let estimated = ticket.estimatedCompletion {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Est. Completion")
                            .font(AppTheme.Typography.caption2)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        Text(dateFormatter.string(from: estimated))
                            .font(AppTheme.Typography.caption)
                            .fontWeight(.medium)
                            .foregroundColor(estimated < Date() ? .red : .primary)
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Ticket Detail View

struct PortalTicketDetailView: View {
    let ticket: Ticket
    @Environment(\.dismiss) private var dismiss
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ticket #\(ticket.ticketNumber)")
                            .font(.title)
                            .bold()
                        
                        PortalStatusBadge(status: ticket.status ?? "")
                    }
                    .padding()
                    
                    // Device Information
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            if let deviceType = ticket.deviceType {
                                PortalInfoRow(label: "Device Type", value: deviceType)
                            }
                            
                            if let model = ticket.deviceModel {
                                PortalInfoRow(label: "Model", value: model)
                            }
                            
                            if let serial = ticket.deviceSerialNumber {
                                PortalInfoRow(label: "Serial Number", value: serial)
                            }
                        }
                    } label: {
                        Label("Device Information", systemImage: "iphone")
                            .font(.headline)
                    }
                    .padding(.horizontal)
                    
                    // Issue Description
                    if let issue = ticket.issueDescription, !issue.isEmpty {
                        GroupBox {
                            Text(issue)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } label: {
                            Label("Issue Description", systemImage: "exclamationmark.triangle")
                                .font(.headline)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Timeline
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            if let checkedIn = ticket.checkedInAt {
                                TimelineRow(title: "Checked In", date: checkedIn, icon: "calendar.badge.plus", color: .blue)
                            }
                            
                            if let started = ticket.startedAt {
                                TimelineRow(title: "Started", date: started, icon: "play.circle", color: .green)
                            }
                            
                            if let estimated = ticket.estimatedCompletion {
                                TimelineRow(title: "Estimated Completion", date: estimated, icon: "clock", color: .orange)
                            }
                            
                            if let completed = ticket.completedAt {
                                TimelineRow(title: "Completed", date: completed, icon: "checkmark.circle", color: .green)
                            }
                            
                            if let pickedUp = ticket.pickedUpAt {
                                TimelineRow(title: "Picked Up", date: pickedUp, icon: "checkmark.circle.fill", color: .purple)
                            }
                        }
                    } label: {
                        Label("Timeline", systemImage: "clock.arrow.circlepath")
                            .font(.headline)
                    }
                    .padding(.horizontal)
                    
                    // Notes
                    if let notes = ticket.notes, !notes.isEmpty {
                        GroupBox {
                            Text(notes)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } label: {
                            Label("Notes", systemImage: "note.text")
                                .font(.headline)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Repair Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Invoice Row

struct PortalInvoiceRow: View {
    let invoice: Invoice
    
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }()
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.purple)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(invoice.formattedInvoiceNumber)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(.primary)
                
                if let dueDate = invoice.dueDate {
                    Text("Due: \(dateFormatter.string(from: dueDate))")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(invoice.isOverdue ? .red : .secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(currencyFormatter.string(from: invoice.total as NSDecimalNumber) ?? "$0.00")
                    .font(AppTheme.Typography.headline)
                    .fontWeight(.bold)
                
                PortalStatusBadge(status: invoice.status ?? "draft")
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Invoice Detail View

struct PortalInvoiceDetailView: View {
    let invoice: Invoice
    @Environment(\.dismiss) private var dismiss
    
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }()
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(invoice.formattedInvoiceNumber)
                            .font(.title)
                            .bold()
                        
                        PortalStatusBadge(status: invoice.status ?? "draft")
                    }
                    .padding()
                    
                    // Dates
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            if let issueDate = invoice.issueDate {
                                PortalInfoRow(label: "Issue Date", value: dateFormatter.string(from: issueDate))
                            }
                            
                            if let dueDate = invoice.dueDate {
                                PortalInfoRow(label: "Due Date", value: dateFormatter.string(from: dueDate))
                            }
                            
                            if let sentAt = invoice.sentAt {
                                PortalInfoRow(label: "Sent", value: dateFormatter.string(from: sentAt))
                            }
                            
                            if let paidAt = invoice.paidAt {
                                PortalInfoRow(label: "Paid", value: dateFormatter.string(from: paidAt))
                            }
                        }
                    } label: {
                        Label("Invoice Information", systemImage: "calendar")
                            .font(.headline)
                    }
                    .padding(.horizontal)
                    
                    // Line Items
                    GroupBox {
                        VStack(spacing: 12) {
                            ForEach(invoice.lineItemsArray) { lineItem in
                                let unitPriceString = currencyFormatter.string(from: lineItem.unitPrice as NSDecimalNumber) ?? "$0.00"
                                let totalString = currencyFormatter.string(from: lineItem.total as NSDecimalNumber) ?? "$0.00"
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(lineItem.itemDescription ?? "Item")
                                            .font(.body)
                                        
                                        Text(verbatim: "Qty: \(lineItem.quantity) × \(unitPriceString)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(verbatim: totalString)
                                        .font(.body)
                                        .bold()
                                }
                                
                                if lineItem != invoice.lineItemsArray.last {
                                    Divider()
                                }
                            }
                        }
                    } label: {
                        Label("Line Items", systemImage: "list.bullet")
                            .font(.headline)
                    }
                    .padding(.horizontal)
                    
                    // Totals
                    GroupBox {
                        VStack(spacing: 12) {
                            HStack {
                                Text("Subtotal")
                                Spacer()
                                Text(currencyFormatter.string(from: invoice.subtotal as NSDecimalNumber) ?? "$0.00")
                            }
                            
                            HStack {
                                Text("Tax (\(invoice.taxRate as NSDecimalNumber)%)")
                                Spacer()
                                Text(currencyFormatter.string(from: invoice.taxAmount as NSDecimalNumber) ?? "$0.00")
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Total")
                                    .font(.headline)
                                Spacer()
                                Text(currencyFormatter.string(from: invoice.total as NSDecimalNumber) ?? "$0.00")
                                    .font(.headline)
                                    .bold()
                            }
                            
                            HStack {
                                Text("Amount Paid")
                                Spacer()
                                Text(currencyFormatter.string(from: invoice.amountPaid as NSDecimalNumber) ?? "$0.00")
                                    .foregroundColor(.green)
                            }
                            
                            HStack {
                                Text("Balance Due")
                                    .font(.headline)
                                Spacer()
                                Text(currencyFormatter.string(from: invoice.balance as NSDecimalNumber) ?? "$0.00")
                                    .font(.headline)
                                    .bold()
                                    .foregroundColor(invoice.balance > 0 ? .red : .green)
                            }
                        }
                    } label: {
                        Label("Summary", systemImage: "dollarsign.circle")
                            .font(.headline)
                    }
                    .padding(.horizontal)
                    
                    // Notes
                    if let notes = invoice.notes, !notes.isEmpty {
                        GroupBox {
                            Text(notes)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } label: {
                            Label("Notes", systemImage: "note.text")
                                .font(.headline)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Terms
                    if let terms = invoice.terms, !terms.isEmpty {
                        GroupBox {
                            Text(terms)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } label: {
                            Label("Terms", systemImage: "doc.text")
                                .font(.headline)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Invoice Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Estimate Row

struct PortalEstimateRow: View {
    let estimate: Estimate
    
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }()
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: "doc.plaintext.fill")
                    .foregroundColor(.orange)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(estimate.formattedEstimateNumber)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(.primary)
                
                if let validUntil = estimate.validUntil {
                    Text("Valid until: \(dateFormatter.string(from: validUntil))")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(estimate.isExpired ? .red : .secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(currencyFormatter.string(from: estimate.total as NSDecimalNumber) ?? "$0.00")
                    .font(AppTheme.Typography.headline)
                    .fontWeight(.bold)
                
                PortalStatusBadge(status: estimate.status ?? "pending")
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Estimate Detail View

struct PortalEstimateDetailView: View {
    let estimate: Estimate
    let customer: Customer
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var portalService = CustomerPortalService.shared
    @State private var showingApproveConfirmation = false
    @State private var showingDeclineSheet = false
    @State private var declineReason = ""
    @State private var isProcessing = false
    @State private var errorMessage: String?
    
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }()
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    var canApproveOrDecline: Bool {
        estimate.status == "pending" && !estimate.isExpired
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(estimate.formattedEstimateNumber)
                            .font(.title)
                            .bold()
                        
                        PortalStatusBadge(status: estimate.status ?? "pending")
                        
                        if estimate.isExpired {
                            Label("This estimate has expired", systemImage: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    .padding()
                    
                    // Action Buttons
                    if canApproveOrDecline {
                        HStack(spacing: 12) {
                            Button {
                                showingApproveConfirmation = true
                            } label: {
                                Label("Approve", systemImage: "checkmark.circle.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                            .disabled(isProcessing)
                            
                            Button {
                                showingDeclineSheet = true
                            } label: {
                                Label("Decline", systemImage: "xmark.circle.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                            .disabled(isProcessing)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Error Message
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }
                    
                    // Dates
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            if let issueDate = estimate.issueDate {
                                PortalInfoRow(label: "Issue Date", value: dateFormatter.string(from: issueDate))
                            }
                            
                            if let validUntil = estimate.validUntil {
                                PortalInfoRow(label: "Valid Until", value: dateFormatter.string(from: validUntil))
                            }
                            
                            if let approvedAt = estimate.approvedAt {
                                PortalInfoRow(label: "Approved", value: dateFormatter.string(from: approvedAt))
                            }
                            
                            if let declinedAt = estimate.declinedAt {
                                PortalInfoRow(label: "Declined", value: dateFormatter.string(from: declinedAt))
                            }
                        }
                    } label: {
                        Label("Estimate Information", systemImage: "calendar")
                            .font(.headline)
                    }
                    .padding(.horizontal)
                    
                    // Line Items
                    GroupBox {
                        VStack(spacing: 12) {
                            ForEach(estimate.lineItemsArray) { lineItem in
                                let unitPriceString = currencyFormatter.string(from: lineItem.unitPrice as NSDecimalNumber) ?? "$0.00"
                                let totalString = currencyFormatter.string(from: lineItem.total as NSDecimalNumber) ?? "$0.00"
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(lineItem.itemDescription ?? "Item")
                                            .font(.body)
                                        
                                        Text(verbatim: "Qty: \(lineItem.quantity) × \(unitPriceString)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(verbatim: totalString)
                                        .font(.body)
                                        .bold()
                                }
                                
                                if lineItem != estimate.lineItemsArray.last {
                                    Divider()
                                }
                            }
                        }
                    } label: {
                        Label("Line Items", systemImage: "list.bullet")
                            .font(.headline)
                    }
                    .padding(.horizontal)
                    
                    // Totals
                    GroupBox {
                        VStack(spacing: 12) {
                            HStack {
                                Text("Subtotal")
                                Spacer()
                                Text(currencyFormatter.string(from: estimate.subtotal as NSDecimalNumber) ?? "$0.00")
                            }
                            
                            HStack {
                                Text("Tax (\(estimate.taxRate as NSDecimalNumber)%)")
                                Spacer()
                                Text(currencyFormatter.string(from: estimate.taxAmount as NSDecimalNumber) ?? "$0.00")
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Total")
                                    .font(.headline)
                                Spacer()
                                Text(currencyFormatter.string(from: estimate.total as NSDecimalNumber) ?? "$0.00")
                                    .font(.headline)
                                    .bold()
                            }
                        }
                    } label: {
                        Label("Summary", systemImage: "dollarsign.circle")
                            .font(.headline)
                    }
                    .padding(.horizontal)
                    
                    // Notes
                    if let notes = estimate.notes, !notes.isEmpty {
                        GroupBox {
                            Text(notes)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } label: {
                            Label("Notes", systemImage: "note.text")
                                .font(.headline)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Estimate Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog("Approve Estimate", isPresented: $showingApproveConfirmation) {
                Button("Approve") {
                    Task {
                        await approveEstimate()
                    }
                }
            } message: {
                Text("Are you sure you want to approve this estimate?")
            }
            .sheet(isPresented: $showingDeclineSheet) {
                DeclineEstimateSheet(
                    isPresented: $showingDeclineSheet,
                    reason: $declineReason,
                    onDecline: {
                        Task {
                            await declineEstimate()
                        }
                    }
                )
            }
        }
    }
    
    private func approveEstimate() async {
        isProcessing = true
        errorMessage = nil
        
        do {
            try await portalService.approveEstimate(estimate)
            dismiss()
        } catch {
            errorMessage = "Failed to approve estimate: \(error.localizedDescription)"
        }
        
        isProcessing = false
    }
    
    private func declineEstimate() async {
        isProcessing = true
        errorMessage = nil
        
        do {
            try await portalService.declineEstimate(estimate, reason: declineReason.isEmpty ? nil : declineReason)
            showingDeclineSheet = false
            dismiss()
        } catch {
            errorMessage = "Failed to decline estimate: \(error.localizedDescription)"
        }
        
        isProcessing = false
    }
}

// MARK: - Payment Row

struct PortalPaymentRow: View {
    let payment: Payment
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: "creditcard.fill")
                    .foregroundColor(.green)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(payment.formattedPaymentNumber)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(.primary)
                
                if let paymentDate = payment.paymentDate {
                    Text(dateFormatter.string(from: paymentDate))
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(payment.formattedAmount)
                    .font(AppTheme.Typography.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                Label(payment.paymentMethodDisplayName, systemImage: payment.paymentMethodIcon)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Helper Components

private struct PortalStatusBadge: View {
    let status: String
    
    var statusColor: Color {
        switch status.lowercased() {
        case "completed", "paid", "approved":
            return .green
        case "in_progress", "sent", "pending":
            return .blue
        case "waiting":
            return .orange
        case "cancelled", "declined", "overdue":
            return .red
        case "expired":
            return .gray
        default:
            return .secondary
        }
    }
    
    var body: some View {
        Text(status.replacingOccurrences(of: "_", with: " ").capitalized)
            .font(AppTheme.Typography.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(statusColor.opacity(0.1))
            .foregroundColor(statusColor)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(statusColor.opacity(0.2), lineWidth: 1)
            )
    }
}

private struct PortalInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .bold()
        }
    }
}

struct TimelineRow: View {
    let title: String
    let date: Date
    let icon: String
    let color: Color
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(dateFormatter.string(from: date))
                    .font(.body)
            }
            
            Spacer()
        }
    }
}

struct DeclineEstimateSheet: View {
    @Binding var isPresented: Bool
    @Binding var reason: String
    let onDecline: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextEditor(text: $reason)
                        .frame(height: 120)
                } header: {
                    Text("Reason for Declining (Optional)")
                } footer: {
                    Text("Let us know why you're declining this estimate. This helps us improve our service.")
                }
            }
            .navigationTitle("Decline Estimate")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Decline") {
                        onDecline()
                    }
                }
            }
        }
    }
}
