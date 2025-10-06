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
        let pendingEstimates = estimates.filter { $0.status == "pending" }
        let unpaidInvoices = invoices.filter { $0.status != "paid" && $0.status != "cancelled" }
        
        let totalSpent = payments.reduce(Decimal(0)) { $0 + $1.amount }
        let outstandingBalance = unpaidInvoices.reduce(Decimal(0)) { $0 + $1.balance }
        
        return CustomerPortalStats(
            activeRepairs: activeTickets.count,
            completedRepairs: tickets.filter { $0.status == "completed" || $0.status == "picked_up" }.count,
            pendingEstimates: pendingEstimates.count,
            unpaidInvoices: unpaidInvoices.count,
            totalSpent: totalSpent,
            outstandingBalance: outstandingBalance
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
}

// MARK: - Notification Names

extension Notification.Name {
    static let estimateApproved = Notification.Name("estimateApproved")
    static let estimateDeclined = Notification.Name("estimateDeclined")
}
