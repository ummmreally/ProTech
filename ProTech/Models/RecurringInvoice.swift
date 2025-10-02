//
//  RecurringInvoice.swift
//  ProTech
//
//  Recurring invoice model for subscriptions and contracts
//

import Foundation
import CoreData

@objc(RecurringInvoice)
public class RecurringInvoice: NSManagedObject {}

extension RecurringInvoice: Identifiable {}

extension RecurringInvoice {
    @NSManaged public var id: UUID?
    @NSManaged public var customerId: UUID?
    @NSManaged public var name: String?
    @NSManaged public var frequency: String? // daily, weekly, monthly, quarterly, yearly
    @NSManaged public var interval: Int16 // Every X periods (e.g., every 2 weeks)
    @NSManaged public var startDate: Date?
    @NSManaged public var endDate: Date? // Optional end date
    @NSManaged public var nextInvoiceDate: Date?
    @NSManaged public var lastInvoiceDate: Date?
    @NSManaged public var isActive: Bool
    @NSManaged public var autoSend: Bool // Automatically email invoice
    @NSManaged public var autoCharge: Bool // Automatically charge saved payment method
    @NSManaged public var paymentMethodId: UUID? // Saved payment method for auto-charge
    @NSManaged public var subtotal: Decimal
    @NSManaged public var taxRate: Decimal
    @NSManaged public var taxAmount: Decimal
    @NSManaged public var total: Decimal
    @NSManaged public var currency: String?
    @NSManaged public var notes: String?
    @NSManaged public var terms: String?
    @NSManaged public var invoiceCount: Int32 // Total invoices generated
    @NSManaged public var successfulCount: Int32 // Successfully generated/sent
    @NSManaged public var failedCount: Int32 // Failed attempts
    @NSManaged public var totalRevenue: Decimal // Total revenue from this recurring invoice
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    
    // Line items stored as JSON or separate entity
    @NSManaged public var lineItemsJson: String? // JSON array of line items
    
    // Convenience initializer
    convenience init(context: NSManagedObjectContext,
                    customerId: UUID,
                    name: String,
                    frequency: String,
                    interval: Int = 1,
                    startDate: Date = Date(),
                    subtotal: Decimal,
                    taxRate: Decimal = 0,
                    autoSend: Bool = true) {
        self.init(context: context)
        self.id = UUID()
        self.customerId = customerId
        self.name = name
        self.frequency = frequency
        self.interval = Int16(interval)
        self.startDate = startDate
        self.nextInvoiceDate = Self.calculateNextDate(from: startDate, frequency: frequency, interval: interval)
        self.isActive = true
        self.autoSend = autoSend
        self.autoCharge = false
        self.subtotal = subtotal
        self.taxRate = taxRate
        self.taxAmount = subtotal * (taxRate / 100)
        self.total = subtotal + self.taxAmount
        self.currency = "USD"
        self.invoiceCount = 0
        self.successfulCount = 0
        self.failedCount = 0
        self.totalRevenue = 0
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

extension RecurringInvoice {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "RecurringInvoice"
        entity.managedObjectClassName = NSStringFromClass(RecurringInvoice.self)
        
        func makeAttribute(_ name: String, type: NSAttributeType, optional: Bool = true, defaultValue: Any? = nil) -> NSAttributeDescription {
            let attribute = NSAttributeDescription()
            attribute.name = name
            attribute.attributeType = type
            attribute.isOptional = optional
            if let defaultValue {
                attribute.defaultValue = defaultValue
            }
            return attribute
        }
        
        entity.properties = [
            makeAttribute("id", type: .UUIDAttributeType, optional: false),
            makeAttribute("customerId", type: .UUIDAttributeType),
            makeAttribute("name", type: .stringAttributeType),
            makeAttribute("frequency", type: .stringAttributeType, optional: false, defaultValue: "monthly"),
            makeAttribute("interval", type: .integer16AttributeType, optional: false, defaultValue: 1),
            makeAttribute("startDate", type: .dateAttributeType),
            makeAttribute("endDate", type: .dateAttributeType),
            makeAttribute("nextInvoiceDate", type: .dateAttributeType),
            makeAttribute("lastInvoiceDate", type: .dateAttributeType),
            makeAttribute("isActive", type: .booleanAttributeType, optional: false, defaultValue: true),
            makeAttribute("autoSend", type: .booleanAttributeType, optional: false, defaultValue: true),
            makeAttribute("autoCharge", type: .booleanAttributeType, optional: false, defaultValue: false),
            makeAttribute("paymentMethodId", type: .UUIDAttributeType),
            makeAttribute("subtotal", type: .decimalAttributeType, optional: false, defaultValue: NSDecimalNumber.zero),
            makeAttribute("taxRate", type: .decimalAttributeType, optional: false, defaultValue: NSDecimalNumber.zero),
            makeAttribute("taxAmount", type: .decimalAttributeType, optional: false, defaultValue: NSDecimalNumber.zero),
            makeAttribute("total", type: .decimalAttributeType, optional: false, defaultValue: NSDecimalNumber.zero),
            makeAttribute("currency", type: .stringAttributeType, optional: false, defaultValue: "USD"),
            makeAttribute("notes", type: .stringAttributeType),
            makeAttribute("terms", type: .stringAttributeType),
            makeAttribute("invoiceCount", type: .integer32AttributeType, optional: false, defaultValue: 0),
            makeAttribute("successfulCount", type: .integer32AttributeType, optional: false, defaultValue: 0),
            makeAttribute("failedCount", type: .integer32AttributeType, optional: false, defaultValue: 0),
            makeAttribute("totalRevenue", type: .decimalAttributeType, optional: false, defaultValue: NSDecimalNumber.zero),
            makeAttribute("createdAt", type: .dateAttributeType),
            makeAttribute("updatedAt", type: .dateAttributeType),
            makeAttribute("lineItemsJson", type: .stringAttributeType)
        ]
        
        if let idAttribute = entity.properties.first(where: { $0.name == "id" }) as? NSAttributeDescription {
            let idIndex = NSFetchIndexDescription(name: "recurring_invoice_id_index", elements: [NSFetchIndexElementDescription(property: idAttribute, collationType: .binary)])
            entity.indexes = [idIndex]
        }
        
        return entity
    }
}

// MARK: - Fetch Request

extension RecurringInvoice {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<RecurringInvoice> {
        return NSFetchRequest<RecurringInvoice>(entityName: "RecurringInvoice")
    }
    
    static func fetchActiveRecurringInvoices(context: NSManagedObjectContext) -> [RecurringInvoice] {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "isActive == true")
        request.sortDescriptors = [NSSortDescriptor(key: "nextInvoiceDate", ascending: true)]
        return (try? context.fetch(request)) ?? []
    }
    
    static func fetchRecurringInvoices(for customerId: UUID, context: NSManagedObjectContext) -> [RecurringInvoice] {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "customerId == %@", customerId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }
    
    static func fetchDueRecurringInvoices(context: NSManagedObjectContext) -> [RecurringInvoice] {
        let request = fetchRequest()
        let now = Date()
        request.predicate = NSPredicate(format: "isActive == true AND nextInvoiceDate <= %@", now as NSDate)
        return (try? context.fetch(request)) ?? []
    }
}

// MARK: - Computed Properties

extension RecurringInvoice {
    var frequencyDisplay: String {
        let intervalText = interval > 1 ? "Every \(interval) " : ""
        switch frequency {
        case "daily":
            return "\(intervalText)Day\(interval > 1 ? "s" : "")"
        case "weekly":
            return "\(intervalText)Week\(interval > 1 ? "s" : "")"
        case "monthly":
            return "\(intervalText)Month\(interval > 1 ? "s" : "")"
        case "quarterly":
            return "\(intervalText)Quarter\(interval > 1 ? "s" : "")"
        case "yearly":
            return "\(intervalText)Year\(interval > 1 ? "s" : "")"
        default:
            return frequency?.capitalized ?? "Unknown"
        }
    }
    
    var formattedTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency ?? "USD"
        return formatter.string(from: total as NSDecimalNumber) ?? "$0.00"
    }
    
    var formattedRevenue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency ?? "USD"
        return formatter.string(from: totalRevenue as NSDecimalNumber) ?? "$0.00"
    }
    
    var successRate: Double {
        guard invoiceCount > 0 else { return 0 }
        return (Double(successfulCount) / Double(invoiceCount)) * 100
    }
    
    var isExpired: Bool {
        guard let endDate = endDate else { return false }
        return Date() > endDate
    }
    
    var shouldGenerateInvoice: Bool {
        guard isActive, !isExpired else { return false }
        guard let nextDate = nextInvoiceDate else { return false }
        return Date() >= nextDate
    }
    
    var lineItems: [LineItemData] {
        guard let json = lineItemsJson,
              let data = json.data(using: .utf8),
              let items = try? JSONDecoder().decode([LineItemData].self, from: data) else {
            return []
        }
        return items
    }
    
    func setLineItems(_ items: [LineItemData]) {
        if let data = try? JSONEncoder().encode(items),
           let json = String(data: data, encoding: .utf8) {
            lineItemsJson = json
        }
    }
}

// MARK: - Helper Methods

extension RecurringInvoice {
    func calculateNextInvoiceDate() {
        guard let current = nextInvoiceDate ?? startDate else { return }
        nextInvoiceDate = Self.calculateNextDate(from: current, frequency: frequency ?? "monthly", interval: Int(interval))
    }
    
    static func calculateNextDate(from date: Date, frequency: String, interval: Int) -> Date {
        let calendar = Calendar.current
        let intervalValue = max(1, interval)
        
        switch frequency {
        case "daily":
            return calendar.date(byAdding: .day, value: intervalValue, to: date) ?? date
        case "weekly":
            return calendar.date(byAdding: .weekOfYear, value: intervalValue, to: date) ?? date
        case "monthly":
            return calendar.date(byAdding: .month, value: intervalValue, to: date) ?? date
        case "quarterly":
            return calendar.date(byAdding: .month, value: intervalValue * 3, to: date) ?? date
        case "yearly":
            return calendar.date(byAdding: .year, value: intervalValue, to: date) ?? date
        default:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        }
    }
}

// MARK: - Recurring Invoice Template (for easier creation)

struct RecurringInvoiceTemplate {
    let name: String
    let frequency: String
    let interval: Int
    let lineItems: [LineItemData]
    
    static let monthlyMaintenance = RecurringInvoiceTemplate(
        name: "Monthly Maintenance Contract",
        frequency: "monthly",
        interval: 1,
        lineItems: [
            LineItemData(id: UUID(), description: "Monthly Maintenance", quantity: Decimal(1), unitPrice: Decimal(99.00), total: Decimal(99.00), itemType: "service")
        ]
    )
    
    static let quarterlyService = RecurringInvoiceTemplate(
        name: "Quarterly Service Plan",
        frequency: "quarterly",
        interval: 1,
        lineItems: [
            LineItemData(id: UUID(), description: "Quarterly Service", quantity: Decimal(1), unitPrice: Decimal(250.00), total: Decimal(250.00), itemType: "service")
        ]
    )
    
    static let yearlyContract = RecurringInvoiceTemplate(
        name: "Annual Service Contract",
        frequency: "yearly",
        interval: 1,
        lineItems: [
            LineItemData(id: UUID(), description: "Annual Contract", quantity: Decimal(1), unitPrice: Decimal(999.00), total: Decimal(999.00), itemType: "service")
        ]
    )
}
