//
//  PaymentMethod.swift
//  ProTech
//
//  Saved payment method model for card on file
//

import Foundation
import CoreData

@objc(PaymentMethod)
public class PaymentMethod: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var customerId: UUID?
    @NSManaged public var paymentMethodId: String? // Stripe payment method ID
    @NSManaged public var type: String? // card, bank_account, etc.
    @NSManaged public var cardBrand: String? // visa, mastercard, amex, discover
    @NSManaged public var cardLast4: String?
    @NSManaged public var cardExpMonth: Int16
    @NSManaged public var cardExpYear: Int16
    @NSManaged public var isDefault: Bool
    @NSManaged public var isActive: Bool
    @NSManaged public var billingName: String?
    @NSManaged public var billingEmail: String?
    @NSManaged public var billingAddress: String?
    @NSManaged public var billingCity: String?
    @NSManaged public var billingState: String?
    @NSManaged public var billingZip: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    
    // Convenience initializer
    convenience init(context: NSManagedObjectContext,
                    customerId: UUID,
                    paymentMethodId: String,
                    type: String,
                    cardBrand: String? = nil,
                    cardLast4: String? = nil,
                    cardExpMonth: Int = 0,
                    cardExpYear: Int = 0) {
        self.init(context: context)
        self.id = UUID()
        self.customerId = customerId
        self.paymentMethodId = paymentMethodId
        self.type = type
        self.cardBrand = cardBrand
        self.cardLast4 = cardLast4
        self.cardExpMonth = Int16(cardExpMonth)
        self.cardExpYear = Int16(cardExpYear)
        self.isActive = true
        self.isDefault = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Fetch Request

extension PaymentMethod {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<PaymentMethod> {
        return NSFetchRequest<PaymentMethod>(entityName: "PaymentMethod")
    }
    
    static func fetchPaymentMethods(for customerId: UUID, context: NSManagedObjectContext) -> [PaymentMethod] {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "customerId == %@ AND isActive == true", customerId as CVarArg)
        request.sortDescriptors = [
            NSSortDescriptor(key: "isDefault", ascending: false),
            NSSortDescriptor(key: "createdAt", ascending: false)
        ]
        return (try? context.fetch(request)) ?? []
    }
    
    static func fetchDefaultPaymentMethod(for customerId: UUID, context: NSManagedObjectContext) -> PaymentMethod? {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "customerId == %@ AND isDefault == true AND isActive == true", customerId as CVarArg)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
    
    static func fetchPaymentMethod(byId id: String, context: NSManagedObjectContext) -> PaymentMethod? {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "paymentMethodId == %@", id)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
}

extension PaymentMethod {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "PaymentMethod"
        entity.managedObjectClassName = NSStringFromClass(PaymentMethod.self)
        
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
            makeAttribute("paymentMethodId", type: .stringAttributeType),
            makeAttribute("type", type: .stringAttributeType),
            makeAttribute("cardBrand", type: .stringAttributeType),
            makeAttribute("cardLast4", type: .stringAttributeType),
            makeAttribute("cardExpMonth", type: .integer16AttributeType, optional: false, defaultValue: 0),
            makeAttribute("cardExpYear", type: .integer16AttributeType, optional: false, defaultValue: 0),
            makeAttribute("isDefault", type: .booleanAttributeType, optional: false, defaultValue: false),
            makeAttribute("isActive", type: .booleanAttributeType, optional: false, defaultValue: true),
            makeAttribute("billingName", type: .stringAttributeType),
            makeAttribute("billingEmail", type: .stringAttributeType),
            makeAttribute("billingAddress", type: .stringAttributeType),
            makeAttribute("billingCity", type: .stringAttributeType),
            makeAttribute("billingState", type: .stringAttributeType),
            makeAttribute("billingZip", type: .stringAttributeType),
            makeAttribute("createdAt", type: .dateAttributeType),
            makeAttribute("updatedAt", type: .dateAttributeType)
        ]
        
        if let idAttribute = entity.properties.first(where: { $0.name == "id" }) as? NSAttributeDescription {
            let idIndex = NSFetchIndexDescription(name: "payment_method_id_index", elements: [NSFetchIndexElementDescription(property: idAttribute, collationType: .binary)])
            entity.indexes = [idIndex]
        }
        
        return entity
    }
}

// MARK: - Computed Properties

extension PaymentMethod {
    var displayName: String {
        if type == "card", let brand = cardBrand, let last4 = cardLast4 {
            return "\(brand.capitalized) •••• \(last4)"
        }
        return type?.capitalized ?? "Unknown"
    }
    
    var displayExpiration: String {
        return String(format: "%02d/%d", cardExpMonth, cardExpYear)
    }
    
    var isExpired: Bool {
        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)
        
        if Int(cardExpYear) < currentYear {
            return true
        } else if Int(cardExpYear) == currentYear && Int(cardExpMonth) < currentMonth {
            return true
        }
        return false
    }
    
    var isExpiringSoon: Bool {
        // Check if expiring within 2 months
        let calendar = Calendar.current
        let now = Date()
        let twoMonthsFromNow = calendar.date(byAdding: .month, value: 2, to: now)!
        
        let expYear = Int(cardExpYear)
        let expMonth = Int(cardExpMonth)
        
        let expirationDate = calendar.date(from: DateComponents(year: expYear, month: expMonth, day: 1))!
        
        return expirationDate <= twoMonthsFromNow && !isExpired
    }
    
    var cardBrandIcon: String {
        switch cardBrand?.lowercased() {
        case "visa":
            return "creditcard.fill"
        case "mastercard":
            return "creditcard.fill"
        case "amex", "american express":
            return "creditcard.fill"
        case "discover":
            return "creditcard.fill"
        default:
            return "creditcard"
        }
    }
}
