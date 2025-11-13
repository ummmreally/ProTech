//
//  DashboardMetricsService.swift
//  ProTech
//
//  Dashboard metrics and data aggregation service
//

import Foundation
import CoreData
import SwiftUI

class DashboardMetricsService {
    static let shared = DashboardMetricsService()
    private let context = CoreDataManager.shared.viewContext
    
    private init() {}
    
    // MARK: - Financial Metrics
    
    func getTodayRevenue() -> Decimal {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<Payment> = Payment.fetchRequest()
        request.predicate = NSPredicate(format: "paymentDate >= %@ AND paymentDate < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        guard let payments = try? context.fetch(request) else { return 0 }
        return payments.reduce(Decimal(0)) { $0 + $1.amount }
    }
    
    func getWeekRevenue() -> Decimal {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        
        let request: NSFetchRequest<Payment> = Payment.fetchRequest()
        request.predicate = NSPredicate(format: "paymentDate >= %@", startOfWeek as NSDate)
        
        guard let payments = try? context.fetch(request) else { return 0 }
        return payments.reduce(Decimal(0)) { $0 + $1.amount }
    }
    
    func getMonthRevenue() -> Decimal {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: Date())
        guard let startOfMonth = calendar.date(from: components) else { return 0 }
        
        let request: NSFetchRequest<Payment> = Payment.fetchRequest()
        request.predicate = NSPredicate(format: "paymentDate >= %@", startOfMonth as NSDate)
        
        guard let payments = try? context.fetch(request) else { return 0 }
        return payments.reduce(Decimal(0)) { $0 + $1.amount }
    }
    
    func getRevenueGrowth() -> Double {
        let currentMonth = getMonthRevenue()
        let lastMonth = getLastMonthRevenue()
        
        guard lastMonth > 0 else { return 0 }
        let growth = (currentMonth - lastMonth) / lastMonth
        return NSDecimalNumber(decimal: growth).doubleValue * 100
    }
    
    private func getLastMonthRevenue() -> Decimal {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month], from: Date())
        components.month! -= 1
        
        guard let startOfLastMonth = calendar.date(from: components),
              let endOfLastMonth = calendar.date(byAdding: .month, value: 1, to: startOfLastMonth) else {
            return 0
        }
        
        let request: NSFetchRequest<Payment> = Payment.fetchRequest()
        request.predicate = NSPredicate(format: "paymentDate >= %@ AND paymentDate < %@",
                                       startOfLastMonth as NSDate,
                                       endOfLastMonth as NSDate)
        
        guard let payments = try? context.fetch(request) else { return 0 }
        return payments.reduce(Decimal(0)) { $0 + $1.amount }
    }
    
    func getOutstandingBalance() -> Decimal {
        let request: NSFetchRequest<Invoice> = Invoice.fetchRequest()
        request.predicate = NSPredicate(format: "status != %@ AND status != %@", "paid", "cancelled")
        
        guard let invoices = try? context.fetch(request) else { return 0 }
        return invoices.reduce(Decimal(0)) { $0 + $1.balance }
    }
    
    func getAverageTicketValue() -> Decimal {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: Date())
        guard let startOfMonth = calendar.date(from: components) else { return 0 }
        
        let request: NSFetchRequest<Invoice> = Invoice.fetchRequest()
        request.predicate = NSPredicate(format: "issueDate >= %@ AND status != %@", startOfMonth as NSDate, "cancelled")
        
        guard let invoices = try? context.fetch(request), !invoices.isEmpty else { return 0 }
        let total = invoices.reduce(Decimal(0)) { $0 + $1.total }
        return total / Decimal(invoices.count)
    }
    
    // MARK: - Operational Metrics
    
    func getActiveRepairs() -> Int {
        let request: NSFetchRequest<Ticket> = Ticket.fetchRequest()
        request.predicate = NSPredicate(format: "status != %@ AND status != %@", "completed", "picked_up")
        request.resultType = .countResultType
        
        return (try? context.count(for: request)) ?? 0
    }
    
    func getRepairsByStatus() -> [String: Int] {
        let request: NSFetchRequest<Ticket> = Ticket.fetchRequest()
        request.predicate = NSPredicate(format: "status != %@ AND status != %@", "completed", "picked_up")
        
        guard let tickets = try? context.fetch(request) else { return [:] }
        
        var statusCounts: [String: Int] = [:]
        for ticket in tickets {
            let status = ticket.status ?? "unknown"
            statusCounts[status, default: 0] += 1
        }
        return statusCounts
    }
    
    func getOverdueRepairs() -> [Ticket] {
        let request: NSFetchRequest<Ticket> = Ticket.fetchRequest()
        request.predicate = NSPredicate(format: "estimatedCompletion < %@ AND status != %@ AND status != %@",
                                       Date() as NSDate, "completed", "picked_up")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Ticket.estimatedCompletion, ascending: true)]
        
        return (try? context.fetch(request)) ?? []
    }
    
    func getPendingEstimates() -> Int {
        let request: NSFetchRequest<Estimate> = Estimate.fetchRequest()
        request.predicate = NSPredicate(format: "status == %@", "pending")
        request.resultType = .countResultType
        
        return (try? context.count(for: request)) ?? 0
    }
    
    func getUnpaidInvoices() -> [Invoice] {
        let request: NSFetchRequest<Invoice> = Invoice.fetchRequest()
        request.predicate = NSPredicate(format: "status != %@ AND status != %@ AND balance > 0",
                                       "paid", "cancelled")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Invoice.dueDate, ascending: true)]
        
        return (try? context.fetch(request)) ?? []
    }
    
    func getTodayPickups() -> [Ticket] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<Ticket> = Ticket.fetchRequest()
        request.predicate = NSPredicate(format: "estimatedCompletion >= %@ AND estimatedCompletion < %@ AND status == %@",
                                       startOfDay as NSDate, endOfDay as NSDate, "completed")
        
        return (try? context.fetch(request)) ?? []
    }
    
    // MARK: - Today's Schedule
    
    func getTodayAppointments() -> [Appointment] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<Appointment> = Appointment.fetchRequest()
        request.predicate = NSPredicate(format: "scheduledDate >= %@ AND scheduledDate < %@ AND status != %@",
                                       startOfDay as NSDate, endOfDay as NSDate, "cancelled")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Appointment.scheduledDate, ascending: true)]
        
        return (try? context.fetch(request)) ?? []
    }
    
    // MARK: - Recent Activity
    
    func getRecentActivity(limit: Int = 10) -> [ActivityItem] {
        var activities: [ActivityItem] = []
        
        // Recent payments
        let paymentRequest: NSFetchRequest<Payment> = Payment.fetchRequest()
        paymentRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Payment.createdAt, ascending: false)]
        paymentRequest.fetchLimit = limit
        
        if let payments = try? context.fetch(paymentRequest) {
            for payment in payments {
                if let customer = fetchCustomer(id: payment.customerId),
                   let paymentDate = payment.createdAt,
                   let paymentId = payment.id {
                    let formatter = NumberFormatter()
                    formatter.numberStyle = .currency
                    let amountString = formatter.string(from: payment.amount as NSDecimalNumber) ?? "$0"
                    
                    activities.append(ActivityItem(
                        type: .paymentReceived,
                        title: "Payment received: \(amountString)",
                        subtitle: customer.displayName,
                        timestamp: paymentDate,
                        icon: "dollarsign.circle.fill",
                        color: .green,
                        relatedId: paymentId
                    ))
                }
            }
        }
        
        // Recent tickets
        let ticketRequest: NSFetchRequest<Ticket> = Ticket.fetchRequest()
        ticketRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Ticket.checkedInAt, ascending: false)]
        ticketRequest.fetchLimit = limit
        
        if let tickets = try? context.fetch(ticketRequest) {
            for ticket in tickets.prefix(3) {
                if let customer = fetchCustomer(id: ticket.customerId), let date = ticket.checkedInAt {
                    activities.append(ActivityItem(
                        type: .ticketCreated,
                        title: "New repair checked in",
                        subtitle: "\(customer.displayName) - #\(ticket.ticketNumber)",
                        timestamp: date,
                        icon: "wrench.and.screwdriver.fill",
                        color: .blue,
                        relatedId: ticket.id
                    ))
                }
            }
        }
        
        // Recent estimates sent
        let estimateRequest: NSFetchRequest<Estimate> = Estimate.fetchRequest()
        estimateRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Estimate.createdAt, ascending: false)]
        estimateRequest.fetchLimit = limit
        
        if let estimates = try? context.fetch(estimateRequest) {
            for estimate in estimates.prefix(3) {
                if let customer = fetchCustomer(id: estimate.customerId),
                   let estimateDate = estimate.createdAt,
                   let estimateId = estimate.id {
                    let title = estimate.status == "approved" ? "Estimate approved" : "Estimate sent"
                    let color: Color = estimate.status == "approved" ? .green : .orange
                    let estimateNum = estimate.estimateNumber ?? "EST-\(estimateId.uuidString.prefix(8))"
                    
                    activities.append(ActivityItem(
                        type: estimate.status == "approved" ? .estimateApproved : .estimateSent,
                        title: title,
                        subtitle: "\(customer.displayName) - \(estimateNum)",
                        timestamp: estimateDate,
                        icon: "doc.plaintext.fill",
                        color: color,
                        relatedId: estimateId
                    ))
                }
            }
        }
        
        // Sort by timestamp and limit
        return activities.sorted { $0.timestamp > $1.timestamp }.prefix(limit).map { $0 }
    }
    
    // MARK: - Alerts
    
    func getCriticalAlerts() -> [DashboardAlert] {
        var alerts: [DashboardAlert] = []
        
        // Overdue invoices
        let overdueInvoices = getOverdueInvoices()
        if !overdueInvoices.isEmpty {
            alerts.append(DashboardAlert(
                severity: .critical,
                title: "\(overdueInvoices.count) Invoices Overdue",
                description: "Total overdue: \(formatCurrency(overdueInvoices.reduce(Decimal(0)) { $0 + $1.balance }))",
                icon: "exclamationmark.triangle.fill",
                actionTitle: "View Invoices",
                relatedIds: overdueInvoices.compactMap { $0.id }
            ))
        }
        
        // Overdue repairs
        let overdueRepairs = getOverdueRepairs()
        if !overdueRepairs.isEmpty {
            alerts.append(DashboardAlert(
                severity: .warning,
                title: "\(overdueRepairs.count) Repairs Past Due",
                description: "Repairs past estimated completion date",
                icon: "clock.badge.exclamationmark.fill",
                actionTitle: "View Queue",
                relatedIds: overdueRepairs.compactMap { $0.id }
            ))
        }
        
        // Pending estimates
        let pendingEstimates = getPendingEstimates()
        if pendingEstimates > 5 {
            alerts.append(DashboardAlert(
                severity: .info,
                title: "\(pendingEstimates) Pending Estimates",
                description: "Awaiting customer approval",
                icon: "doc.plaintext",
                actionTitle: "View Estimates",
                relatedIds: []
            ))
        }
        
        // Low stock items
        let lowStockItems = getLowStockItems()
        if !lowStockItems.isEmpty {
            alerts.append(DashboardAlert(
                severity: .info,
                title: "\(lowStockItems.count) Low Stock Items",
                description: "Inventory items need restocking",
                icon: "shippingbox.fill",
                actionTitle: "View Inventory",
                relatedIds: lowStockItems.compactMap { $0.id }
            ))
        }
        
        return alerts.sorted { $0.severity.rawValue > $1.severity.rawValue }
    }
    
    private func getOverdueInvoices() -> [Invoice] {
        let request: NSFetchRequest<Invoice> = Invoice.fetchRequest()
        request.predicate = NSPredicate(format: "dueDate < %@ AND status != %@ AND status != %@ AND balance > 0",
                                       Date() as NSDate, "paid", "cancelled")
        
        return (try? context.fetch(request)) ?? []
    }
    
    // MARK: - Inventory Metrics
    
    func getLowStockItems() -> [InventoryItem] {
        let request: NSFetchRequest<InventoryItem> = InventoryItem.fetchRequest()
        request.predicate = NSPredicate(format: "quantity <= minQuantity AND minQuantity > 0")
        
        return (try? context.fetch(request)) ?? []
    }
    
    func getOutOfStockItems() -> [InventoryItem] {
        let request: NSFetchRequest<InventoryItem> = InventoryItem.fetchRequest()
        request.predicate = NSPredicate(format: "quantity == 0 AND isActive == YES")
        
        return (try? context.fetch(request)) ?? []
    }
    
    // MARK: - Customer Metrics
    
    func getNewCustomersThisWeek() -> Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        
        let request: NSFetchRequest<Customer> = Customer.fetchRequest()
        request.predicate = NSPredicate(format: "createdAt >= %@", startOfWeek as NSDate)
        request.resultType = .countResultType
        
        return (try? context.count(for: request)) ?? 0
    }
    
    func getNewCustomersThisMonth() -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: Date())
        guard let startOfMonth = calendar.date(from: components) else { return 0 }
        
        let request: NSFetchRequest<Customer> = Customer.fetchRequest()
        request.predicate = NSPredicate(format: "createdAt >= %@", startOfMonth as NSDate)
        request.resultType = .countResultType
        
        return (try? context.count(for: request)) ?? 0
    }
    
    // MARK: - Helper Methods
    
    private func fetchCustomer(id: UUID?) -> Customer? {
        guard let id = id else { return nil }
        let request: NSFetchRequest<Customer> = Customer.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
    
    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: value as NSDecimalNumber) ?? "$0.00"
    }
}

// MARK: - Models

struct ActivityItem: Identifiable {
    let id = UUID()
    let type: ActivityType
    let title: String
    let subtitle: String?
    let timestamp: Date
    let icon: String
    let color: Color
    let relatedId: UUID?
    
    enum ActivityType {
        case ticketCreated
        case paymentReceived
        case estimateApproved
        case estimateDeclined
        case estimateSent
        case invoiceSent
        case loyaltyEarned
        case inventorySold
        case socialPost
        case customerAdded
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

struct DashboardAlert: Identifiable {
    let id = UUID()
    let severity: Severity
    let title: String
    let description: String
    let icon: String
    let actionTitle: String
    let relatedIds: [UUID]
    
    enum Severity: Int {
        case critical = 3
        case warning = 2
        case info = 1
        
        var color: Color {
            switch self {
            case .critical: return .red
            case .warning: return .orange
            case .info: return .blue
            }
        }
        
        var iconColor: Color {
            switch self {
            case .critical: return .red
            case .warning: return .orange
            case .info: return .yellow
            }
        }
    }
}
