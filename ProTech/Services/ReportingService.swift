import Foundation
import CoreData

class ReportingService {
    static let shared = ReportingService()
    
    private let coreDataManager = CoreDataManager.shared
    

    
    private let paymentService = PaymentService.shared
    private let invoiceService = InvoiceService.shared
    private var context: NSManagedObjectContext {
        coreDataManager.viewContext
    }
    
    private init() {}
    
    // MARK: - Revenue Reports
    
    /// Get revenue for a date range
    func getRevenue(from startDate: Date, to endDate: Date) -> Decimal {
        return paymentService.getTotalPayments(from: startDate, to: endDate)
    }
    
    /// Get daily revenue for a date range
    func getDailyRevenue(from startDate: Date, to endDate: Date) -> [(date: Date, amount: Decimal)] {
        let payments = paymentService.fetchPayments(from: startDate, to: endDate)
        
        var dailyRevenue: [Date: Decimal] = [:]
        let calendar = Calendar.current
        
        for payment in payments {
            guard let paymentDate = payment.paymentDate else { continue }
            let dayStart = calendar.startOfDay(for: paymentDate)
            dailyRevenue[dayStart, default: 0] += payment.amount
        }
        
        return dailyRevenue.sorted { $0.key < $1.key }.map { ($0.key, $0.value) }
    }
    
    /// Get monthly revenue for a year
    func getMonthlyRevenue(year: Int) -> [(month: Int, amount: Decimal)] {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = 1
        components.day = 1
        
        guard let startDate = calendar.date(from: components) else { return [] }
        guard let endDate = calendar.date(byAdding: .year, value: 1, to: startDate) else { return [] }
        
        let payments = paymentService.fetchPayments(from: startDate, to: endDate)
        
        var monthlyRevenue: [Int: Decimal] = [:]
        
        for payment in payments {
            guard let paymentDate = payment.paymentDate else { continue }
            let month = calendar.component(.month, from: paymentDate)
            monthlyRevenue[month, default: 0] += payment.amount
        }
        
        return (1...12).map { month in
            (month, monthlyRevenue[month] ?? 0)
        }
    }
    
    /// Get revenue by payment method
    func getRevenueByPaymentMethod(from startDate: Date, to endDate: Date) -> [(method: String, amount: Decimal)] {
        let payments = paymentService.fetchPayments(from: startDate, to: endDate)
        
        var methodRevenue: [String: Decimal] = [:]
        
        for payment in payments {
            let method = payment.paymentMethod ?? "unknown"
            methodRevenue[method, default: 0] += payment.amount
        }
        
        return methodRevenue.sorted { $0.value > $1.value }.map { ($0.key, $0.value) }
    }
    
    // MARK: - Invoice Reports
    
    /// Get invoice statistics
    func getInvoiceStats(from startDate: Date, to endDate: Date) -> InvoiceStats {
        let invoices = fetchInvoices(from: startDate, to: endDate)
        
        let totalInvoices = invoices.count
        let paidInvoices = invoices.filter { $0.status == "paid" }.count
        let unpaidInvoices = invoices.filter { $0.status != "paid" && $0.status != "cancelled" }.count
        let overdueInvoices = invoices.filter { $0.isOverdue }.count
        
        let totalAmount = invoices.reduce(Decimal(0)) { $0 + $1.total }
        let paidAmount = invoices.filter { $0.status == "paid" }.reduce(Decimal(0)) { $0 + $1.total }
        let outstandingAmount = invoices.filter { $0.status != "paid" && $0.status != "cancelled" }.reduce(Decimal(0)) { $0 + $1.balance }
        
        return InvoiceStats(
            totalInvoices: totalInvoices,
            paidInvoices: paidInvoices,
            unpaidInvoices: unpaidInvoices,
            overdueInvoices: overdueInvoices,
            totalAmount: totalAmount,
            paidAmount: paidAmount,
            outstandingAmount: outstandingAmount
        )
    }
    
    /// Get average invoice value
    func getAverageInvoiceValue(from startDate: Date, to endDate: Date) -> Decimal {
        let invoices = fetchInvoices(from: startDate, to: endDate)
        guard !invoices.isEmpty else { return 0 }
        
        let total = invoices.reduce(Decimal(0)) { $0 + $1.total }
        return total / Decimal(invoices.count)
    }
    
    /// Get invoice conversion rate (paid / total)
    func getInvoiceConversionRate(from startDate: Date, to endDate: Date) -> Double {
        let invoices = fetchInvoices(from: startDate, to: endDate)
        guard !invoices.isEmpty else { return 0 }
        
        let paidCount = invoices.filter { $0.status == "paid" }.count
        return Double(paidCount) / Double(invoices.count) * 100
    }
    
    // MARK: - Customer Reports
    
    /// Get top customers by revenue
    func getTopCustomers(limit: Int = 10, from startDate: Date, to endDate: Date) -> [(customer: Customer, revenue: Decimal)] {
        let payments = paymentService.fetchPayments(from: startDate, to: endDate)
        
        var customerRevenue: [UUID: Decimal] = [:]
        
        for payment in payments {
            guard let customerId = payment.customerId else { continue }
            customerRevenue[customerId, default: 0] += payment.amount
        }
        
        let topCustomerIds = customerRevenue.sorted { $0.value > $1.value }.prefix(limit)
        
        return topCustomerIds.compactMap { (customerId, revenue) in
            guard let customer = coreDataManager.fetchCustomer(id: customerId) else { return nil }
            return (customer, revenue)
        }
    }
    
    /// Get customer acquisition stats
    func getCustomerAcquisition(from startDate: Date, to endDate: Date) -> Int {
        let request: NSFetchRequest<Customer> = Customer.fetchRequest()
        request.predicate = NSPredicate(
            format: "createdAt >= %@ AND createdAt <= %@",
            startDate as NSDate, endDate as NSDate
        )
        
        return (try? context.count(for: request)) ?? 0
    }
    
    /// Get customer retention rate
    func getCustomerRetentionRate(from startDate: Date, to endDate: Date) -> Double {
        let payments = paymentService.fetchPayments(from: startDate, to: endDate)
        let uniqueCustomers = Set(payments.compactMap { $0.customerId })
        
        // Get customers who paid in previous period
        let calendar = Calendar.current
        let periodLength = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 30
        let previousStart = calendar.date(byAdding: .day, value: -periodLength, to: startDate) ?? startDate
        
        let previousPayments = paymentService.fetchPayments(from: previousStart, to: startDate)
        let previousCustomers = Set(previousPayments.compactMap { $0.customerId })
        
        guard !previousCustomers.isEmpty else { return 0 }
        
        let returningCustomers = uniqueCustomers.intersection(previousCustomers)
        return Double(returningCustomers.count) / Double(previousCustomers.count) * 100
    }
    
    // MARK: - Ticket Reports
    
    /// Get ticket statistics
    func getTicketStats(from startDate: Date, to endDate: Date) -> TicketStats {
        let tickets = fetchTickets(from: startDate, to: endDate)
        
        let totalTickets = tickets.count
        let completedTickets = tickets.filter { $0.status == "completed" || $0.status == "picked_up" }.count
        let inProgressTickets = tickets.filter { $0.status == "in_progress" }.count
        let pendingTickets = tickets.filter { $0.status == "checked_in" || $0.status == "pending" }.count
        
        // Calculate average turnaround time
        let completedWithDates = tickets.filter {
            $0.completedAt != nil && $0.checkedInAt != nil
        }
        
        var totalHours: Double = 0
        for ticket in completedWithDates {
            if let checkedIn = ticket.checkedInAt, let completed = ticket.completedAt {
                totalHours += completed.timeIntervalSince(checkedIn) / 3600
            }
        }
        
        let averageTurnaroundHours = completedWithDates.isEmpty ? 0 : totalHours / Double(completedWithDates.count)
        
        return TicketStats(
            totalTickets: totalTickets,
            completedTickets: completedTickets,
            inProgressTickets: inProgressTickets,
            pendingTickets: pendingTickets,
            averageTurnaroundHours: averageTurnaroundHours
        )
    }
    
    /// Get tickets by status
    func getTicketsByStatus(from startDate: Date, to endDate: Date) -> [(status: String, count: Int)] {
        let tickets = fetchTickets(from: startDate, to: endDate)
        
        var statusCounts: [String: Int] = [:]
        
        for ticket in tickets {
            let status = ticket.status ?? "unknown"
            statusCounts[status, default: 0] += 1
        }
        
        return statusCounts.sorted { $0.value > $1.value }.map { ($0.key, $0.value) }
    }
    
    /// Get tickets by device type
    func getTicketsByDeviceType(from startDate: Date, to endDate: Date) -> [(deviceType: String, count: Int)] {
        let tickets = fetchTickets(from: startDate, to: endDate)
        
        var deviceCounts: [String: Int] = [:]
        
        for ticket in tickets {
            let device = ticket.deviceType ?? "unknown"
            deviceCounts[device, default: 0] += 1
        }
        
        return deviceCounts.sorted { $0.value > $1.value }.map { ($0.key, $0.value) }
    }
    
    // MARK: - Performance Reports
    
    /// Get daily performance summary
    func getDailyPerformance(for date: Date) -> DailyPerformance {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let revenue = getRevenue(from: startOfDay, to: endOfDay)
        let payments = paymentService.fetchPayments(from: startOfDay, to: endOfDay)
        let invoices = fetchInvoices(from: startOfDay, to: endOfDay)
        let tickets = fetchTickets(from: startOfDay, to: endOfDay)
        
        return DailyPerformance(
            date: date,
            revenue: revenue,
            paymentCount: payments.count,
            invoiceCount: invoices.count,
            ticketCount: tickets.count
        )
    }
    
    /// Get weekly performance summary
    func getWeeklyPerformance(for date: Date) -> [DailyPerformance] {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
        
        return (0..<7).compactMap { dayOffset in
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek) else { return nil }
            return getDailyPerformance(for: day)
        }
    }
    
    // MARK: - Technician Performance
    
    /// Get technician performance metrics
    func getTechnicianPerformance(from startDate: Date, to endDate: Date) -> [TechnicianStats] {
        let tickets = fetchTickets(from: startDate, to: endDate)
        // Only count completed tickets
        let completedTickets = tickets.filter { $0.status == "completed" || $0.status == "picked_up" }
        
        var technicianStats: [UUID: (count: Int, totalRevenue: Decimal, totalTurnaround: Double)] = [:]
        
        for ticket in completedTickets {
            guard let techId = ticket.technicianId else { continue }
            
            let revenue = ticket.actualCost?.decimalValue ?? 0
            
            var turnaround: Double = 0
            if let checkedIn = ticket.checkedInAt, let completed = ticket.completedAt {
                turnaround = completed.timeIntervalSince(checkedIn) / 3600
            }
            
            let current = technicianStats[techId] ?? (count: 0, totalRevenue: 0, totalTurnaround: 0)
            technicianStats[techId] = (
                count: current.count + 1,
                totalRevenue: current.totalRevenue + revenue,
                totalTurnaround: current.totalTurnaround + turnaround
            )
        }
        
        return technicianStats.compactMap { (techId, stats) -> TechnicianStats? in
            guard let employee = coreDataManager.fetchEmployee(id: techId) else { return nil }
            
            return TechnicianStats(
                technician: employee,
                ticketsClosed: stats.count,
                revenueGenerated: stats.totalRevenue,
                averageTurnaroundHours: stats.count > 0 ? stats.totalTurnaround / Double(stats.count) : 0
            )
        }.sorted { $0.ticketsClosed > $1.ticketsClosed }
    }
    
    // MARK: - Export Data
    
    /// Generate CSV report
    func generateCSVReport(type: ReportType, from startDate: Date, to endDate: Date) -> String {
        switch type {
        case .revenue:
            return generateRevenueCSV(from: startDate, to: endDate)
        case .invoices:
            return generateInvoicesCSV(from: startDate, to: endDate)
        case .payments:
            return generatePaymentsCSV(from: startDate, to: endDate)
        case .tickets:
            return generateTicketsCSV(from: startDate, to: endDate)
        }
    }
    
    private func generateRevenueCSV(from startDate: Date, to endDate: Date) -> String {
        let dailyRevenue = getDailyRevenue(from: startDate, to: endDate)
        
        var csv = "Date,Revenue\n"
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        for (date, amount) in dailyRevenue {
            csv += "\(dateFormatter.string(from: date)),\(amount)\n"
        }
        
        return csv
    }
    
    private func generateInvoicesCSV(from startDate: Date, to endDate: Date) -> String {
        let invoices = fetchInvoices(from: startDate, to: endDate)
        
        var csv = "Invoice Number,Customer,Date,Total,Status\n"
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        for invoice in invoices {
            let customer = invoice.customerId != nil ? coreDataManager.fetchCustomer(id: invoice.customerId!) : nil
            let customerName = customer != nil ? "\(customer!.firstName ?? "") \(customer!.lastName ?? "")" : "Unknown"
            let date = invoice.issueDate != nil ? dateFormatter.string(from: invoice.issueDate!) : ""
            
            csv += "\(invoice.formattedInvoiceNumber),\(customerName),\(date),\(invoice.total),\(invoice.status ?? "")\n"
        }
        
        return csv
    }
    
    private func generatePaymentsCSV(from startDate: Date, to endDate: Date) -> String {
        let payments = paymentService.fetchPayments(from: startDate, to: endDate)
        
        var csv = "Payment Number,Customer,Date,Amount,Method\n"
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        for payment in payments {
            let customer = payment.customerId != nil ? coreDataManager.fetchCustomer(id: payment.customerId!) : nil
            let customerName = customer != nil ? "\(customer!.firstName ?? "") \(customer!.lastName ?? "")" : "Unknown"
            let date = payment.paymentDate != nil ? dateFormatter.string(from: payment.paymentDate!) : ""
            
            csv += "\(payment.formattedPaymentNumber),\(customerName),\(date),\(payment.amount),\(payment.paymentMethodDisplayName)\n"
        }
        
        return csv
    }
    
    private func generateTicketsCSV(from startDate: Date, to endDate: Date) -> String {
        let tickets = fetchTickets(from: startDate, to: endDate)
        
        var csv = "Ticket Number,Customer,Device,Status,Created Date\n"
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        for ticket in tickets {
            let customer = ticket.customerId != nil ? coreDataManager.fetchCustomer(id: ticket.customerId!) : nil
            let customerName = customer != nil ? "\(customer!.firstName ?? "") \(customer!.lastName ?? "")" : "Unknown"
            let device = "\(ticket.deviceType ?? "") \(ticket.deviceModel ?? "")"
            let date = ticket.createdAt != nil ? dateFormatter.string(from: ticket.createdAt!) : ""
            
            csv += "\(ticket.ticketNumber),\(customerName),\(device),\(ticket.status ?? ""),\(date)\n"
        }
        
        return csv
    }
    
    // MARK: - Helper Methods
    
    private func fetchInvoices(from startDate: Date, to endDate: Date) -> [Invoice] {
        let request: NSFetchRequest<Invoice> = Invoice.fetchRequest()
        request.predicate = NSPredicate(
            format: "issueDate >= %@ AND issueDate <= %@",
            startDate as NSDate, endDate as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Invoice.issueDate, ascending: true)]
        
        return (try? context.fetch(request)) ?? []
    }
    
    private func fetchTickets(from startDate: Date, to endDate: Date) -> [Ticket] {
        let request: NSFetchRequest<Ticket> = Ticket.fetchRequest()
        request.predicate = NSPredicate(
            format: "createdAt >= %@ AND createdAt <= %@",
            startDate as NSDate, endDate as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Ticket.createdAt, ascending: true)]
        
        return (try? context.fetch(request)) ?? []
    }
}

// MARK: - Supporting Types

struct InvoiceStats {
    let totalInvoices: Int
    let paidInvoices: Int
    let unpaidInvoices: Int
    let overdueInvoices: Int
    let totalAmount: Decimal
    let paidAmount: Decimal
    let outstandingAmount: Decimal
}

struct TicketStats {
    let totalTickets: Int
    let completedTickets: Int
    let inProgressTickets: Int
    let pendingTickets: Int
    let averageTurnaroundHours: Double
}

struct DailyPerformance {
    let date: Date
    let revenue: Decimal
    let paymentCount: Int
    let invoiceCount: Int
    let ticketCount: Int
}

enum ReportType: String, CaseIterable {
    case revenue = "Revenue Report"
    case invoices = "Invoices Report"
    case payments = "Payments Report"
    case tickets = "Tickets Report"
}

struct TechnicianStats: Identifiable {
    var id: UUID { technician.id ?? UUID() }
    let technician: Employee
    let ticketsClosed: Int
    let revenueGenerated: Decimal
    let averageTurnaroundHours: Double
}
