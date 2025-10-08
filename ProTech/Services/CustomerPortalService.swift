//
//  CustomerPortalService.swift
//  ProTech
//
//  Customer Portal Service for managing customer-facing operations
//

import Foundation
import CoreData

@MainActor
class CustomerPortalService: ObservableObject {
    static let shared = CustomerPortalService()
    
    private let viewContext = CoreDataManager.shared.viewContext
    
    // MARK: - Estimate Actions
    
    /// Approve an estimate
    func approveEstimate(_ estimate: Estimate) async throws {
        estimate.status = "approved"
        estimate.approvedAt = Date()
        estimate.updatedAt = Date()
        
        try viewContext.save()
        
        // Send notification to shop
        NotificationCenter.default.post(
            name: .estimateApproved,
            object: nil,
            userInfo: ["estimateId": estimate.id as Any]
        )
    }
    
    /// Decline an estimate
    func declineEstimate(_ estimate: Estimate, reason: String?) async throws {
        estimate.status = "declined"
        estimate.declinedAt = Date()
        estimate.updatedAt = Date()
        
        if let reason = reason {
            let currentNotes = estimate.notes ?? ""
            estimate.notes = currentNotes.isEmpty ? "Declined reason: \(reason)" : "\(currentNotes)\n\nDeclined reason: \(reason)"
        }
        
        try viewContext.save()
        
        // Send notification to shop
        NotificationCenter.default.post(
            name: .estimateDeclined,
            object: nil,
            userInfo: ["estimateId": estimate.id as Any, "reason": reason as Any]
        )
    }
    
    // MARK: - Fetch Customer Data
    
    /// Fetch all tickets for a customer
    func fetchTickets(for customer: Customer) -> [Ticket] {
        guard let customerId = customer.id else { return [] }
        
        let request: NSFetchRequest<Ticket> = Ticket.fetchRequest()
        request.predicate = NSPredicate(format: "customerId == %@", customerId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Ticket.createdAt, ascending: false)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching tickets: \(error)")
            return []
        }
    }
    
    /// Fetch all invoices for a customer
    func fetchInvoices(for customer: Customer) -> [Invoice] {
        guard let customerId = customer.id else { return [] }
        
        let request: NSFetchRequest<Invoice> = Invoice.fetchRequest()
        request.predicate = NSPredicate(format: "customerId == %@", customerId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Invoice.issueDate, ascending: false)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching invoices: \(error)")
            return []
        }
    }
    
    /// Fetch all estimates for a customer
    func fetchEstimates(for customer: Customer) -> [Estimate] {
        guard let customerId = customer.id else { return [] }
        
        let request: NSFetchRequest<Estimate> = Estimate.fetchRequest()
        request.predicate = NSPredicate(format: "customerId == %@", customerId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Estimate.issueDate, ascending: false)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching estimates: \(error)")
            return []
        }
    }
    
    /// Fetch all payments for a customer
    func fetchPayments(for customer: Customer) -> [Payment] {
        guard let customerId = customer.id else { return [] }
        
        let request: NSFetchRequest<Payment> = Payment.fetchRequest()
        request.predicate = NSPredicate(format: "customerId == %@", customerId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Payment.paymentDate, ascending: false)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching payments: \(error)")
            return []
        }
    }
    
    /// Get customer by email (for portal login)
    func findCustomer(byEmail email: String) -> Customer? {
        let request: NSFetchRequest<Customer> = Customer.fetchRequest()
        request.predicate = NSPredicate(format: "email ==[c] %@", email)
        request.fetchLimit = 1
        
        do {
            return try viewContext.fetch(request).first
        } catch {
            print("Error finding customer: \(error)")
            return nil
        }
    }
    
    /// Get customer by phone (for portal login)
    func findCustomer(byPhone phone: String) -> Customer? {
        let request: NSFetchRequest<Customer> = Customer.fetchRequest()
        request.predicate = NSPredicate(format: "phone == %@", phone)
        request.fetchLimit = 1
        
        do {
            return try viewContext.fetch(request).first
        } catch {
            print("Error finding customer: \(error)")
            return nil
        }
    }
    
    // MARK: - Portal Statistics
    
    /// Get portal overview stats for customer
    func getPortalStats(for customer: Customer) -> CustomerPortalStats {
        let tickets = fetchTickets(for: customer)
        let invoices = fetchInvoices(for: customer)
        let estimates = fetchEstimates(for: customer)
        let payments = fetchPayments(for: customer)
        
        let activeTickets = tickets.filter { $0.status != "completed" && $0.status != "picked_up" && $0.status != "cancelled" }
        let completedTickets = tickets.filter { $0.status == "completed" || $0.status == "picked_up" }
        let pendingEstimates = estimates.filter { $0.status == "pending" }
        let unpaidInvoices = invoices.filter { $0.status != "paid" && $0.status != "cancelled" }
        
        let totalSpent = payments.reduce(Decimal(0)) { $0 + $1.amount }
        let outstandingBalance = unpaidInvoices.reduce(Decimal(0)) { $0 + $1.balance }
        
        let alerts = buildAlerts(from: estimates, invoices: invoices, payments: payments)
        let trends = buildTrends(payments: payments, tickets: tickets, estimates: estimates)
        let recentActivity = buildRecentActivity(tickets: tickets, estimates: estimates, invoices: invoices, payments: payments)
        let engagement = buildEngagementMetrics(estimates: estimates, payments: payments, tickets: tickets)
        
        let expiringEstimates = pendingEstimates.filter { estimate in
            guard let validUntil = estimate.validUntil else { return false }
            let now = Date()
            let soon = Calendar.current.date(byAdding: .day, value: 3, to: now) ?? now
            return validUntil >= now && validUntil <= soon
        }
        
        let recentPayments = payments
            .sorted { ($0.paymentDate ?? $0.createdAt ?? .distantPast) > ($1.paymentDate ?? $1.createdAt ?? .distantPast) }
            .prefix(3)
            .map { $0 }
        
        return CustomerPortalStats(
            activeRepairs: activeTickets.count,
            completedRepairs: completedTickets.count,
            pendingEstimates: pendingEstimates.count,
            unpaidInvoices: unpaidInvoices.count,
            totalSpent: totalSpent,
            outstandingBalance: outstandingBalance,
            expiringEstimates: Array(expiringEstimates),
            overdueInvoices: invoices.filter { $0.isOverdue },
            recentPayments: Array(recentPayments),
            alerts: alerts,
            trends: trends,
            recentActivity: recentActivity,
            engagement: engagement
        )
    }
}

// MARK: - Supporting Structures

struct CustomerPortalStats {
    let activeRepairs: Int
    let completedRepairs: Int
    let pendingEstimates: Int
    let unpaidInvoices: Int
    let totalSpent: Decimal
    let outstandingBalance: Decimal
    let expiringEstimates: [Estimate]
    let overdueInvoices: [Invoice]
    let recentPayments: [Payment]
    let alerts: [PortalDashboardAlert]
    let trends: [PortalTrendMetric]
    let recentActivity: [PortalActivity]
    let engagement: PortalEngagementMetrics
}

struct PortalDashboardAlert: Identifiable {
    enum AlertKind {
        case estimateExpiring
        case invoiceOverdue
        case newPayment
    }
    
    let id = UUID()
    let kind: AlertKind
    let title: String
    let message: String
}

struct PortalTrendMetric: Identifiable {
    let id = UUID()
    let title: String
    let currentValue: Decimal
    let comparisonValue: Decimal
    let unit: String
    
    var delta: Decimal {
        currentValue - comparisonValue
    }
}

struct PortalActivity: Identifiable {
    enum ActivityType {
        case repair
        case estimate
        case invoice
        case payment
    }
    
    let id = UUID()
    let type: ActivityType
    let title: String
    let detail: String
    let date: Date
}

struct PortalEngagementMetrics {
    let lastCustomerAction: Date?
    let approvalsLast30Days: Int
    let averageApprovalTime: TimeInterval?
    let paymentsLast30Days: Int
}

// MARK: - Private builders

private extension CustomerPortalService {
    func buildAlerts(from estimates: [Estimate], invoices: [Invoice], payments: [Payment]) -> [PortalDashboardAlert] {
        var items: [PortalDashboardAlert] = []
        let now = Date()
        let soonThreshold = Calendar.current.date(byAdding: .day, value: 3, to: now) ?? now
        
        let expiringEstimates = estimates.filter { estimate in
            guard estimate.status == "pending", let validUntil = estimate.validUntil else { return false }
            return validUntil >= now && validUntil <= soonThreshold
        }
        
        if !expiringEstimates.isEmpty {
            items.append(
                PortalDashboardAlert(
                    kind: .estimateExpiring,
                    title: "Estimates expiring soon",
                    message: expiringEstimates.count == 1 ? "Estimate \(expiringEstimates.first?.formattedEstimateNumber ?? "") expires soon." : "\(expiringEstimates.count) estimates are nearing expiration."
                )
            )
        }
        
        let overdueInvoices = invoices.filter { $0.isOverdue }
        if !overdueInvoices.isEmpty {
            let totalBalance = overdueInvoices.reduce(Decimal(0)) { $0 + $1.balance }
            items.append(
                PortalDashboardAlert(
                    kind: .invoiceOverdue,
                    title: "Overdue invoices",
                    message: "\(overdueInvoices.count) invoice(s) overdue – outstanding \(formattedCurrency(totalBalance))."
                )
            )
        }
        
        let recentPayments = payments.filter { payment in
            guard let date = payment.paymentDate else { return false }
            return DateInterval(start: Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now, end: now).contains(date)
        }
        if !recentPayments.isEmpty {
            let total = recentPayments.reduce(Decimal(0)) { $0 + $1.amount }
            items.append(
                PortalDashboardAlert(
                    kind: .newPayment,
                    title: "Recent payments received",
                    message: "\(recentPayments.count) payment(s) in the last 7 days totaling \(formattedCurrency(total))."
                )
            )
        }
        
        return items
    }
    
    func buildTrends(payments: [Payment], tickets: [Ticket], estimates: [Estimate]) -> [PortalTrendMetric] {
        let now = Date()
        let calendar = Calendar.current
        let last30Start = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        let prev30Start = calendar.date(byAdding: .day, value: -60, to: now) ?? now
        let prev30End = last30Start
        
        let paymentsLast30 = payments.filter { payment in
            guard let date = payment.paymentDate else { return false }
            return DateInterval(start: last30Start, end: now).contains(date)
        }
        let paymentsPrev30 = payments.filter { payment in
            guard let date = payment.paymentDate else { return false }
            return DateInterval(start: prev30Start, end: prev30End).contains(date)
        }
        
        let totalLast30 = paymentsLast30.reduce(Decimal(0)) { $0 + $1.amount }
        let totalPrev30 = paymentsPrev30.reduce(Decimal(0)) { $0 + $1.amount }
        
        let approvalsLast30 = estimates.filter { estimate in
            guard let approvedAt = estimate.approvedAt else { return false }
            return DateInterval(start: last30Start, end: now).contains(approvedAt)
        }.count
        let approvalsPrev30 = estimates.filter { estimate in
            guard let approvedAt = estimate.approvedAt else { return false }
            return DateInterval(start: prev30Start, end: prev30End).contains(approvedAt)
        }.count
        
        let completedTicketsLast30 = tickets.filter { ticket in
            guard let completedAt = ticket.completedAt else { return false }
            return DateInterval(start: last30Start, end: now).contains(completedAt)
        }.count
        let completedTicketsPrev30 = tickets.filter { ticket in
            guard let completedAt = ticket.completedAt else { return false }
            return DateInterval(start: prev30Start, end: prev30End).contains(completedAt)
        }.count
        
        return [
            PortalTrendMetric(title: "Spending (30d)", currentValue: totalLast30, comparisonValue: totalPrev30, unit: "currency"),
            PortalTrendMetric(title: "Estimate approvals", currentValue: Decimal(approvalsLast30), comparisonValue: Decimal(approvalsPrev30), unit: "count"),
            PortalTrendMetric(title: "Repairs completed", currentValue: Decimal(completedTicketsLast30), comparisonValue: Decimal(completedTicketsPrev30), unit: "count")
        ]
    }
    
    func buildRecentActivity(tickets: [Ticket], estimates: [Estimate], invoices: [Invoice], payments: [Payment]) -> [PortalActivity] {
        var items: [PortalActivity] = []
        
        for ticket in tickets {
            if let updated = ticket.updatedAt {
                items.append(
                    PortalActivity(
                        type: .repair,
                        title: "Repair \(ticket.ticketNumber)",
                        detail: ticket.status?.replacingOccurrences(of: "_", with: " ").capitalized ?? "Status updated",
                        date: updated
                    )
                )
            }
        }
        
        for estimate in estimates {
            if let approvedAt = estimate.approvedAt {
                items.append(
                    PortalActivity(
                        type: .estimate,
                        title: "Estimate \(estimate.formattedEstimateNumber)",
                        detail: "Approved",
                        date: approvedAt
                    )
                )
            } else if let declinedAt = estimate.declinedAt {
                items.append(
                    PortalActivity(
                        type: .estimate,
                        title: "Estimate \(estimate.formattedEstimateNumber)",
                        detail: "Declined",
                        date: declinedAt
                    )
                )
            } else if let issueDate = estimate.issueDate {
                items.append(
                    PortalActivity(
                        type: .estimate,
                        title: "Estimate \(estimate.formattedEstimateNumber)",
                        detail: "Sent",
                        date: issueDate
                    )
                )
            }
        }
        
        for invoice in invoices {
            if let paidAt = invoice.paidAt {
                items.append(
                    PortalActivity(
                        type: .invoice,
                        title: "Invoice \(invoice.formattedInvoiceNumber)",
                        detail: "Paid",
                        date: paidAt
                    )
                )
            } else if let issueDate = invoice.issueDate {
                items.append(
                    PortalActivity(
                        type: .invoice,
                        title: "Invoice \(invoice.formattedInvoiceNumber)",
                        detail: "Issued",
                        date: issueDate
                    )
                )
            }
        }
        
        for payment in payments {
            if let paymentDate = payment.paymentDate {
                items.append(
                    PortalActivity(
                        type: .payment,
                        title: payment.formattedPaymentNumber,
                        detail: payment.paymentMethodDisplayName,
                        date: paymentDate
                    )
                )
            }
        }
        
        return items
            .sorted { $0.date > $1.date }
            .prefix(6)
            .map { $0 }
    }
    
    func buildEngagementMetrics(estimates: [Estimate], payments: [Payment], tickets: [Ticket]) -> PortalEngagementMetrics {
        let lastEstimateAction = estimates.compactMap { $0.approvedAt ?? $0.declinedAt }.max()
        let lastPayment = payments.compactMap { $0.paymentDate ?? $0.createdAt }.max()
        let lastTicketUpdate = tickets.compactMap { $0.updatedAt }.max()
        
        let lastAction = [lastEstimateAction, lastPayment, lastTicketUpdate].compactMap { $0 }.max()
        
        let now = Date()
        let last30Start = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
        
        let approvalsLast30 = estimates.filter { estimate in
            guard let approvedAt = estimate.approvedAt else { return false }
            return DateInterval(start: last30Start, end: now).contains(approvedAt)
        }.count
        
        let paymentsLast30 = payments.filter { payment in
            guard let paymentDate = payment.paymentDate else { return false }
            return DateInterval(start: last30Start, end: now).contains(paymentDate)
        }.count
        
        let approvalDurations = estimates.compactMap { estimate -> TimeInterval? in
            guard let issueDate = estimate.issueDate, let approvedAt = estimate.approvedAt else { return nil }
            return approvedAt.timeIntervalSince(issueDate)
        }
        let averageApproval = approvalDurations.isEmpty ? nil : (approvalDurations.reduce(0, +) / Double(approvalDurations.count))
        
        return PortalEngagementMetrics(
            lastCustomerAction: lastAction,
            approvalsLast30Days: approvalsLast30,
            averageApprovalTime: averageApproval,
            paymentsLast30Days: paymentsLast30
        )
    }
    
    func formattedCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "$0.00"
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let estimateApproved = Notification.Name("estimateApproved")
    static let estimateDeclined = Notification.Name("estimateDeclined")
}
