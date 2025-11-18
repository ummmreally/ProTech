//
//  InventoryService.swift
//  ProTech
//
//  Comprehensive inventory management service
//

import Foundation
import CoreData

class InventoryService {
    static let shared = InventoryService()
    
    private init() {}
    
    // MARK: - Inventory Items
    
    func createItem(
        name: String,
        partNumber: String,
        sku: String? = nil,
        category: InventoryCategory,
        quantity: Int,
        minQuantity: Int = 5,
        cost: Double,
        price: Double
    ) -> InventoryItem {
        let context = CoreDataManager.shared.viewContext
        let item = InventoryItem(context: context)
        
        item.id = UUID()
        item.name = name
        item.partNumber = partNumber
        item.sku = sku
        item.category = category.rawValue
        item.quantity = Int32(quantity)
        item.minQuantity = Int32(minQuantity)
        item.cost = NSDecimalNumber(value: cost)
        item.price = NSDecimalNumber(value: price)
        item.isActive = true
        item.createdAt = Date()
        item.updatedAt = Date()
        
        CoreDataManager.shared.save()
        return item
    }
    
    func updateItem(_ item: InventoryItem) {
        item.updatedAt = Date()
        CoreDataManager.shared.save()
    }
    
    func deleteItem(_ item: InventoryItem) {
        let context = CoreDataManager.shared.viewContext
        context.delete(item)
        CoreDataManager.shared.save()
    }
    
    func getAllItems() -> [InventoryItem] {
        let request = InventoryItem.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \InventoryItem.name, ascending: true)]
        return (try? CoreDataManager.shared.viewContext.fetch(request)) ?? []
    }
    
    func getLowStockItems() -> [InventoryItem] {
        let request = InventoryItem.fetchRequest()
        request.predicate = NSPredicate(format: "quantity <= minQuantity AND isActive == true")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \InventoryItem.quantity, ascending: true)]
        return (try? CoreDataManager.shared.viewContext.fetch(request)) ?? []
    }
    
    func getOutOfStockItems() -> [InventoryItem] {
        let request = InventoryItem.fetchRequest()
        request.predicate = NSPredicate(format: "quantity <= 0 AND isActive == true")
        return (try? CoreDataManager.shared.viewContext.fetch(request)) ?? []
    }
    
    func getItemsByCategory(_ category: InventoryCategory) -> [InventoryItem] {
        guard category != .all else { return getAllItems() }
        let request = InventoryItem.fetchRequest()
        request.predicate = NSPredicate(format: "category == %@ AND isActive == true", category.rawValue)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \InventoryItem.name, ascending: true)]
        return (try? CoreDataManager.shared.viewContext.fetch(request)) ?? []
    }
    
    func searchItems(query: String) -> [InventoryItem] {
        let request = InventoryItem.fetchRequest()
        request.predicate = NSPredicate(
            format: "(name CONTAINS[cd] %@ OR partNumber CONTAINS[cd] %@ OR sku CONTAINS[cd] %@) AND isActive == true",
            query, query, query
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \InventoryItem.name, ascending: true)]
        return (try? CoreDataManager.shared.viewContext.fetch(request)) ?? []
    }
    
    func getTotalInventoryValue() -> Double {
        let items = getAllItems()
        return items.reduce(0) { $0 + $1.totalValue }
    }
    
    // MARK: - Stock Adjustments
    
    func adjustStock(
        item: InventoryItem,
        change: Int,
        type: StockAdjustmentType,
        reason: String,
        reference: String? = nil,
        notes: String? = nil
    ) {
        let context = CoreDataManager.shared.viewContext
        let adjustment = StockAdjustment(context: context)
        
        adjustment.id = UUID()
        adjustment.itemId = item.id
        adjustment.itemName = item.name
        adjustment.type = type.rawValue
        adjustment.quantityBefore = item.quantity
        adjustment.quantityChange = Int32(change)
        adjustment.quantityAfter = item.quantity + Int32(change)
        adjustment.reason = reason
        adjustment.reference = reference
        adjustment.notes = notes
        adjustment.performedBy = NSUserName()
        adjustment.createdAt = Date()
        
        // Update item quantity
        item.quantity += Int32(change)
        item.updatedAt = Date()
        
        CoreDataManager.shared.save()
        
        // Check if reorder needed
        if item.isLowStock {
            NotificationCenter.default.post(
                name: NSNotification.Name("LowStockAlert"),
                object: item
            )
        }
    }
    
    func getStockHistory(for item: InventoryItem) -> [StockAdjustment] {
        guard let itemId = item.id else { return [] }
        
        let request = StockAdjustment.fetchRequest()
        request.predicate = NSPredicate(format: "itemId == %@", itemId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \StockAdjustment.createdAt, ascending: false)]
        return (try? CoreDataManager.shared.viewContext.fetch(request)) ?? []
    }
    
    // MARK: - Suppliers
    
    func createSupplier(
        name: String,
        contactPerson: String? = nil,
        email: String? = nil,
        phone: String? = nil
    ) -> Supplier {
        let context = CoreDataManager.shared.viewContext
        let supplier = Supplier(context: context)
        
        supplier.id = UUID()
        supplier.name = name
        supplier.companyName = name
        supplier.contactPerson = contactPerson
        supplier.email = email
        supplier.phone = phone
        supplier.isActive = true
        supplier.rating = 0
        supplier.leadTimeDays = 7
        supplier.createdAt = Date()
        supplier.updatedAt = Date()
        
        CoreDataManager.shared.save()
        return supplier
    }
    
    func getAllSuppliers() -> [Supplier] {
        let request = Supplier.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Supplier.name, ascending: true)]
        return (try? CoreDataManager.shared.viewContext.fetch(request)) ?? []
    }
    
    func getActiveSuppliers() -> [Supplier] {
        let request = Supplier.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == true")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Supplier.name, ascending: true)]
        return (try? CoreDataManager.shared.viewContext.fetch(request)) ?? []
    }
    
    // MARK: - Purchase Orders
    
    func createPurchaseOrder(
        supplier: Supplier,
        lineItems: [PurchaseOrderLineItem],
        expectedDeliveryDate: Date? = nil
    ) -> PurchaseOrder {
        let context = CoreDataManager.shared.viewContext
        let po = PurchaseOrder(context: context)
        
        po.id = UUID()
        po.orderNumber = generatePONumber()
        po.supplierId = supplier.id
        po.supplierName = supplier.name
        po.status = "draft"
        po.orderDate = Date()
        po.expectedDeliveryDate = expectedDeliveryDate
        
        // Calculate totals
        let subtotal = lineItems.reduce(0) { $0 + $1.total }
        po.subtotal = subtotal
        po.tax = subtotal * 0.08 // 8% tax
        po.shipping = 0.0
        po.total = po.subtotal + po.tax + po.shipping
        
        // Store line items as JSON
        if let jsonData = try? JSONEncoder().encode(lineItems),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            po.lineItemsJSON = jsonString
        }
        
        po.createdAt = Date()
        po.updatedAt = Date()
        
        CoreDataManager.shared.save()
        return po
    }
    
    func updatePOStatus(_ po: PurchaseOrder, status: String) {
        po.status = status
        po.updatedAt = Date()
        
        if status == "sent" && po.orderDate == nil {
            po.orderDate = Date()
        }
        
        CoreDataManager.shared.save()
    }
    
    func receivePurchaseOrder(_ po: PurchaseOrder, receivedItems: [(itemId: UUID, quantity: Int)]) {
        guard let lineItemsJSON = po.lineItemsJSON,
              let data = lineItemsJSON.data(using: .utf8),
              var lineItems = try? JSONDecoder().decode([PurchaseOrderLineItem].self, from: data) else {
            return
        }
        
        // Update received quantities
        for received in receivedItems {
            if let index = lineItems.firstIndex(where: { $0.itemId == received.itemId }) {
                lineItems[index].receivedQuantity += received.quantity
                
                // Update inventory
                let request = InventoryItem.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", received.itemId as CVarArg)
                if let item = try? CoreDataManager.shared.viewContext.fetch(request).first {
                    adjustStock(
                        item: item,
                        change: received.quantity,
                        type: .add,
                        reason: "Received from supplier",
                        reference: "PO-\(po.orderNumber ?? "")"
                    )
                }
            }
        }
        
        // Save updated line items
        if let jsonData = try? JSONEncoder().encode(lineItems),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            po.lineItemsJSON = jsonString
        }
        
        // Update PO status
        let allReceived = lineItems.allSatisfy { $0.isFullyReceived }
        po.status = allReceived ? "received" : "partially_received"
        
        if allReceived {
            po.actualDeliveryDate = Date()
        }
        
        po.updatedAt = Date()
        CoreDataManager.shared.save()
    }
    
    func getAllPurchaseOrders() -> [PurchaseOrder] {
        let request = PurchaseOrder.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PurchaseOrder.orderDate, ascending: false)]
        return (try? CoreDataManager.shared.viewContext.fetch(request)) ?? []
    }
    
    func getPendingPurchaseOrders() -> [PurchaseOrder] {
        let request = PurchaseOrder.fetchRequest()
        request.predicate = NSPredicate(format: "status IN %@", ["sent", "confirmed", "partially_received"])
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PurchaseOrder.orderDate, ascending: false)]
        return (try? CoreDataManager.shared.viewContext.fetch(request)) ?? []
    }
    
    // MARK: - Helpers
    
    private func generatePONumber() -> String {
        let request = PurchaseOrder.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PurchaseOrder.createdAt, ascending: false)]
        request.fetchLimit = 1
        
        if let lastPO = try? CoreDataManager.shared.viewContext.fetch(request).first,
           let lastNumber = lastPO.orderNumber,
           let number = Int(lastNumber.replacingOccurrences(of: "PO", with: "")) {
            return String(format: "PO%05d", number + 1)
        }
        
        return "PO00001"
    }
    
    // MARK: - Usage Tracking
    
    func usePartForTicket(itemId: UUID, quantity: Int, ticketNumber: Int32) {
        let request = InventoryItem.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", itemId as CVarArg)
        
        if let item = try? CoreDataManager.shared.viewContext.fetch(request).first {
            adjustStock(
                item: item,
                change: -quantity,
                type: .usage,
                reason: "Used for repair",
                reference: "Ticket #\(ticketNumber)",
                notes: "Part used in repair ticket"
            )
        }
    }
    
    func returnPartFromTicket(itemId: UUID, quantity: Int, ticketNumber: Int32) {
        let request = InventoryItem.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", itemId as CVarArg)
        
        if let item = try? CoreDataManager.shared.viewContext.fetch(request).first {
            adjustStock(
                item: item,
                change: quantity,
                type: .return,
                reason: "Returned from repair",
                reference: "Ticket #\(ticketNumber)",
                notes: "Part returned from repair ticket"
            )
        }
    }
}

// MARK: - Stock Adjustment Type

enum StockAdjustmentType: String, CaseIterable {
    case add = "add"
    case remove = "remove"
    case recount = "recount"
    case damaged = "damaged"
    case `return` = "return"
    case sale = "sale"
    case usage = "usage"
    
    var displayName: String {
        switch self {
        case .add: return "Added"
        case .remove: return "Removed"
        case .recount: return "Recounted"
        case .damaged: return "Damaged"
        case .return: return "Returned"
        case .sale: return "Sold"
        case .usage: return "Used"
        }
    }
    
    var icon: String {
        switch self {
        case .add: return "plus.circle.fill"
        case .remove: return "minus.circle.fill"
        case .recount: return "arrow.triangle.2.circlepath"
        case .damaged: return "exclamationmark.triangle.fill"
        case .return: return "arrow.uturn.left.circle.fill"
        case .sale: return "cart.fill"
        case .usage: return "wrench.and.screwdriver.fill"
        }
    }
    
    var color: String {
        switch self {
        case .add: return "green"
        case .remove: return "red"
        case .recount: return "blue"
        case .damaged: return "orange"
        case .return: return "blue"
        case .sale: return "purple"
        case .usage: return "indigo"
        }
    }
}

// MARK: - Inventory Category

// InventoryCategory moved to inventory UI module
