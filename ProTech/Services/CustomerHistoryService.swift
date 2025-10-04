//
//  CustomerHistoryService.swift
//  ProTech
//
//  Service for fetching customer purchase and repair history
//

import Foundation
import CoreData

class CustomerHistoryService {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = CoreDataManager.shared.viewContext) {
        self.context = context
    }
    
    // MARK: - Purchase History
    
    /// Fetch recent purchases for a customer
    func fetchPurchaseHistory(for customer: Customer, limit: Int = 10) -> [PurchaseHistory] {
        guard let customerId = customer.id else { return [] }
        
        let fetchRequest: NSFetchRequest<PurchaseHistory> = PurchaseHistory.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "customerId == %@", customerId as CVarArg)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \PurchaseHistory.purchaseDate, ascending: false)]
        fetchRequest.fetchLimit = limit
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching purchase history: \(error)")
            return []
        }
    }
    
    /// Fetch all purchases for a customer
    func fetchAllPurchases(for customer: Customer) -> [PurchaseHistory] {
        return fetchPurchaseHistory(for: customer, limit: 0)
    }
    
    /// Get total lifetime spending for a customer
    func getTotalSpending(for customer: Customer) -> Double {
        let purchases = fetchAllPurchases(for: customer)
        return purchases.reduce(0.0) { $0 + $1.totalAmount }
    }
    
    /// Get purchase count for a customer
    func getPurchaseCount(for customer: Customer) -> Int {
        guard let customerId = customer.id else { return 0 }
        
        let fetchRequest: NSFetchRequest<PurchaseHistory> = PurchaseHistory.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "customerId == %@", customerId as CVarArg)
        
        do {
            return try context.count(for: fetchRequest)
        } catch {
            print("Error counting purchases: \(error)")
            return 0
        }
    }
    
    // MARK: - Repair History
    
    /// Fetch recent repair tickets for a customer
    func fetchRepairHistory(for customer: Customer, limit: Int = 10) -> [Ticket] {
        guard let customerId = customer.id else { return [] }
        
        let fetchRequest: NSFetchRequest<Ticket> = Ticket.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "customerId == %@", customerId as CVarArg)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Ticket.createdAt, ascending: false)]
        fetchRequest.fetchLimit = limit
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching repair history: \(error)")
            return []
        }
    }
    
    /// Get active (incomplete) repairs for a customer
    func getActiveRepairs(for customer: Customer) -> [Ticket] {
        guard let customerId = customer.id else { return [] }
        
        let fetchRequest: NSFetchRequest<Ticket> = Ticket.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "customerId == %@ AND status != %@ AND status != %@",
            customerId as CVarArg,
            "completed",
            "picked_up"
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Ticket.createdAt, ascending: false)]
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching active repairs: \(error)")
            return []
        }
    }
    
    /// Get repair count for a customer
    func getRepairCount(for customer: Customer) -> Int {
        guard let customerId = customer.id else { return 0 }
        
        let fetchRequest: NSFetchRequest<Ticket> = Ticket.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "customerId == %@", customerId as CVarArg)
        
        do {
            return try context.count(for: fetchRequest)
        } catch {
            print("Error counting repairs: \(error)")
            return 0
        }
    }
    
    // MARK: - Combined Stats
    
    struct CustomerStats {
        let totalPurchases: Int
        let totalSpent: Double
        let totalRepairs: Int
        let activeRepairs: Int
        let lastPurchaseDate: Date?
        let lastRepairDate: Date?
    }
    
    /// Get comprehensive customer statistics
    func getCustomerStats(for customer: Customer) -> CustomerStats {
        let purchases = fetchPurchaseHistory(for: customer, limit: 1)
        let repairs = fetchRepairHistory(for: customer, limit: 1)
        
        return CustomerStats(
            totalPurchases: getPurchaseCount(for: customer),
            totalSpent: getTotalSpending(for: customer),
            totalRepairs: getRepairCount(for: customer),
            activeRepairs: getActiveRepairs(for: customer).count,
            lastPurchaseDate: purchases.first?.purchaseDate,
            lastRepairDate: repairs.first?.createdAt
        )
    }
    
    // MARK: - Create Purchase Record
    
    /// Save a completed sale as purchase history
    func savePurchase(
        customer: Customer?,
        cart: POSCart,
        paymentMethod: String,
        squareTransactionId: String? = nil,
        squareCheckoutId: String? = nil,
        discount: Double = 0
    ) throws -> PurchaseHistory {
        let purchase = PurchaseHistory(context: context)
        purchase.id = UUID()
        purchase.customerId = customer?.id
        purchase.totalAmount = cart.total - discount
        purchase.subtotal = cart.subtotal
        purchase.taxAmount = cart.taxAmount
        purchase.discountAmount = discount
        purchase.paymentMethod = paymentMethod
        purchase.squareTransactionId = squareTransactionId
        purchase.squareTerminalCheckoutId = squareCheckoutId
        purchase.itemCount = Int32(cart.items.count)
        purchase.purchaseDate = Date()
        purchase.createdAt = Date()
        
        // Serialize cart items to JSON
        let itemsData = cart.items.map { item in
            [
                "name": item.name,
                "quantity": item.quantity,
                "price": item.price,
                "total": item.totalPrice
            ] as [String : Any]
        }
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: itemsData),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            purchase.items = jsonString
        }
        
        try context.save()
        return purchase
    }
}
