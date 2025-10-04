//
//  PurchaseHistory.swift
//  ProTech
//
//  Tracks completed POS sales for customer purchase history
//

import Foundation
import CoreData

@objc(PurchaseHistory)
public class PurchaseHistory: NSManagedObject {}

extension PurchaseHistory {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<PurchaseHistory> {
        return NSFetchRequest<PurchaseHistory>(entityName: "PurchaseHistory")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var customerId: UUID?
    @NSManaged public var totalAmount: Double
    @NSManaged public var subtotal: Double
    @NSManaged public var taxAmount: Double
    @NSManaged public var discountAmount: Double
    @NSManaged public var paymentMethod: String? // "card", "cash", "upi"
    @NSManaged public var squareTransactionId: String?
    @NSManaged public var squareTerminalCheckoutId: String?
    @NSManaged public var items: String? // JSON string of items
    @NSManaged public var itemCount: Int32
    @NSManaged public var purchaseDate: Date?
    @NSManaged public var notes: String?
    @NSManaged public var createdAt: Date?
    
    // Computed properties
    var customerName: String? {
        guard customerId != nil else { return nil }
        // Fetch customer name if needed
        return nil // Will be populated by relationship
    }
    
    var formattedTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: totalAmount)) ?? "$0.00"
    }
    
    var formattedDate: String {
        guard let date = purchaseDate else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var paymentMethodIcon: String {
        switch paymentMethod {
        case "card": return "creditcard.fill"
        case "cash": return "dollarsign.circle.fill"
        case "upi": return "qrcode"
        default: return "questionmark.circle"
        }
    }
}

extension PurchaseHistory: Identifiable {}

// MARK: - Entity Description

extension PurchaseHistory {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "PurchaseHistory"
        entity.managedObjectClassName = NSStringFromClass(PurchaseHistory.self)
        
        // ID
        let idAttribute = NSAttributeDescription()
        idAttribute.name = "id"
        idAttribute.attributeType = .UUIDAttributeType
        idAttribute.isOptional = false
        
        // Customer ID
        let customerIdAttribute = NSAttributeDescription()
        customerIdAttribute.name = "customerId"
        customerIdAttribute.attributeType = .UUIDAttributeType
        customerIdAttribute.isOptional = true
        
        // Total Amount
        let totalAmountAttribute = NSAttributeDescription()
        totalAmountAttribute.name = "totalAmount"
        totalAmountAttribute.attributeType = .doubleAttributeType
        totalAmountAttribute.isOptional = false
        totalAmountAttribute.defaultValue = 0.0
        
        // Subtotal
        let subtotalAttribute = NSAttributeDescription()
        subtotalAttribute.name = "subtotal"
        subtotalAttribute.attributeType = .doubleAttributeType
        subtotalAttribute.isOptional = false
        subtotalAttribute.defaultValue = 0.0
        
        // Tax Amount
        let taxAmountAttribute = NSAttributeDescription()
        taxAmountAttribute.name = "taxAmount"
        taxAmountAttribute.attributeType = .doubleAttributeType
        taxAmountAttribute.isOptional = false
        taxAmountAttribute.defaultValue = 0.0
        
        // Discount Amount
        let discountAmountAttribute = NSAttributeDescription()
        discountAmountAttribute.name = "discountAmount"
        discountAmountAttribute.attributeType = .doubleAttributeType
        discountAmountAttribute.isOptional = false
        discountAmountAttribute.defaultValue = 0.0
        
        // Payment Method
        let paymentMethodAttribute = NSAttributeDescription()
        paymentMethodAttribute.name = "paymentMethod"
        paymentMethodAttribute.attributeType = .stringAttributeType
        paymentMethodAttribute.isOptional = true
        
        // Square Transaction ID
        let squareTransactionIdAttribute = NSAttributeDescription()
        squareTransactionIdAttribute.name = "squareTransactionId"
        squareTransactionIdAttribute.attributeType = .stringAttributeType
        squareTransactionIdAttribute.isOptional = true
        
        // Square Terminal Checkout ID
        let squareTerminalCheckoutIdAttribute = NSAttributeDescription()
        squareTerminalCheckoutIdAttribute.name = "squareTerminalCheckoutId"
        squareTerminalCheckoutIdAttribute.attributeType = .stringAttributeType
        squareTerminalCheckoutIdAttribute.isOptional = true
        
        // Items (JSON)
        let itemsAttribute = NSAttributeDescription()
        itemsAttribute.name = "items"
        itemsAttribute.attributeType = .stringAttributeType
        itemsAttribute.isOptional = true
        
        // Item Count
        let itemCountAttribute = NSAttributeDescription()
        itemCountAttribute.name = "itemCount"
        itemCountAttribute.attributeType = .integer32AttributeType
        itemCountAttribute.isOptional = false
        itemCountAttribute.defaultValue = 0
        
        // Purchase Date
        let purchaseDateAttribute = NSAttributeDescription()
        purchaseDateAttribute.name = "purchaseDate"
        purchaseDateAttribute.attributeType = .dateAttributeType
        purchaseDateAttribute.isOptional = true
        
        // Notes
        let notesAttribute = NSAttributeDescription()
        notesAttribute.name = "notes"
        notesAttribute.attributeType = .stringAttributeType
        notesAttribute.isOptional = true
        
        // Created At
        let createdAtAttribute = NSAttributeDescription()
        createdAtAttribute.name = "createdAt"
        createdAtAttribute.attributeType = .dateAttributeType
        createdAtAttribute.isOptional = true
        
        entity.properties = [
            idAttribute,
            customerIdAttribute,
            totalAmountAttribute,
            subtotalAttribute,
            taxAmountAttribute,
            discountAmountAttribute,
            paymentMethodAttribute,
            squareTransactionIdAttribute,
            squareTerminalCheckoutIdAttribute,
            itemsAttribute,
            itemCountAttribute,
            purchaseDateAttribute,
            notesAttribute,
            createdAtAttribute
        ]
        
        return entity
    }
}
