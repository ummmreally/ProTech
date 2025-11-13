//
//  DiscountCode.swift
//  ProTech
//
//  Discount code model for promotional offers
//

import CoreData
import Foundation

@objc(DiscountCode)
public class DiscountCode: NSManagedObject {
}

extension DiscountCode {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DiscountCode> {
        NSFetchRequest<DiscountCode>(entityName: "DiscountCode")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var code: String?
    @NSManaged public var type: String? // "percentage" or "fixed_amount"
    @NSManaged public var value: NSDecimalNumber?
    @NSManaged public var startDate: Date?
    @NSManaged public var endDate: Date?
    @NSManaged public var usageLimit: Int32
    @NSManaged public var usageCount: Int32
    @NSManaged public var isActive: Bool
    @NSManaged public var minimumPurchase: NSDecimalNumber?
    @NSManaged public var maximumDiscount: NSDecimalNumber?
    @NSManaged public var applicableCategories: String? // JSON array of category names
    @NSManaged public var description_: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
}

extension DiscountCode: Identifiable {}

// MARK: - Computed Properties

extension DiscountCode {
    var discountValue: Decimal {
        value?.decimalValue ?? 0
    }
    
    var minimumPurchaseAmount: Decimal {
        minimumPurchase?.decimalValue ?? 0
    }
    
    var maximumDiscountAmount: Decimal? {
        maximumDiscount?.decimalValue
    }
    
    var discountType: DiscountType {
        get {
            DiscountType(rawValue: type ?? "percentage") ?? .percentage
        }
        set {
            type = newValue.rawValue
        }
    }
    
    var categories: [String] {
        get {
            guard let json = applicableCategories,
                  let data = json.data(using: .utf8),
                  let array = try? JSONDecoder().decode([String].self, from: data) else {
                return []
            }
            return array
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                applicableCategories = json
            }
        }
    }
    
    var isValid: Bool {
        guard isActive else { return false }
        
        let now = Date()
        if let start = startDate, now < start { return false }
        if let end = endDate, now > end { return false }
        
        if usageLimit > 0 && usageCount >= usageLimit { return false }
        
        return true
    }
    
    var formattedValue: String {
        if discountType == .percentage {
            let percentValue = NSDecimalNumber(decimal: discountValue).intValue
            return "\(percentValue)%"
        } else {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            return formatter.string(from: value ?? 0) ?? "$0.00"
        }
    }
    
    var statusText: String {
        if !isActive { return "Inactive" }
        if !isValid { return "Invalid" }
        
        if let end = endDate {
            let now = Date()
            if now > end { return "Expired" }
        }
        
        if usageLimit > 0 && usageCount >= usageLimit {
            return "Limit Reached"
        }
        
        return "Active"
    }
    
    var statusColor: String {
        switch statusText {
        case "Active": return "green"
        case "Inactive": return "gray"
        case "Expired", "Limit Reached", "Invalid": return "red"
        default: return "gray"
        }
    }
}

// MARK: - Discount Type

enum DiscountType: String, CaseIterable, Codable {
    case percentage = "percentage"
    case fixedAmount = "fixed_amount"
    
    var displayName: String {
        switch self {
        case .percentage: return "Percentage"
        case .fixedAmount: return "Fixed Amount"
        }
    }
}

// MARK: - Validation Result

struct DiscountValidationResult {
    let isValid: Bool
    let discountAmount: Decimal
    let errorMessage: String?
    
    static func valid(discountAmount: Decimal) -> DiscountValidationResult {
        DiscountValidationResult(isValid: true, discountAmount: discountAmount, errorMessage: nil)
    }
    
    static func invalid(_ message: String) -> DiscountValidationResult {
        DiscountValidationResult(isValid: false, discountAmount: 0, errorMessage: message)
    }
}

// MARK: - Core Data Entity Description

extension DiscountCode {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "DiscountCode"
        entity.managedObjectClassName = NSStringFromClass(DiscountCode.self)
        
        let idAttribute = NSAttributeDescription()
        idAttribute.name = "id"
        idAttribute.attributeType = .UUIDAttributeType
        idAttribute.isOptional = false
        
        let codeAttribute = NSAttributeDescription()
        codeAttribute.name = "code"
        codeAttribute.attributeType = .stringAttributeType
        codeAttribute.isOptional = false
        
        let typeAttribute = NSAttributeDescription()
        typeAttribute.name = "type"
        typeAttribute.attributeType = .stringAttributeType
        typeAttribute.isOptional = false
        
        let valueAttribute = NSAttributeDescription()
        valueAttribute.name = "value"
        valueAttribute.attributeType = .decimalAttributeType
        valueAttribute.isOptional = false
        
        let startDateAttribute = NSAttributeDescription()
        startDateAttribute.name = "startDate"
        startDateAttribute.attributeType = .dateAttributeType
        startDateAttribute.isOptional = true
        
        let endDateAttribute = NSAttributeDescription()
        endDateAttribute.name = "endDate"
        endDateAttribute.attributeType = .dateAttributeType
        endDateAttribute.isOptional = true
        
        let usageLimitAttribute = NSAttributeDescription()
        usageLimitAttribute.name = "usageLimit"
        usageLimitAttribute.attributeType = .integer32AttributeType
        usageLimitAttribute.defaultValue = 0
        
        let usageCountAttribute = NSAttributeDescription()
        usageCountAttribute.name = "usageCount"
        usageCountAttribute.attributeType = .integer32AttributeType
        usageCountAttribute.defaultValue = 0
        
        let isActiveAttribute = NSAttributeDescription()
        isActiveAttribute.name = "isActive"
        isActiveAttribute.attributeType = .booleanAttributeType
        isActiveAttribute.defaultValue = true
        
        let minimumPurchaseAttribute = NSAttributeDescription()
        minimumPurchaseAttribute.name = "minimumPurchase"
        minimumPurchaseAttribute.attributeType = .decimalAttributeType
        minimumPurchaseAttribute.isOptional = true
        
        let maximumDiscountAttribute = NSAttributeDescription()
        maximumDiscountAttribute.name = "maximumDiscount"
        maximumDiscountAttribute.attributeType = .decimalAttributeType
        maximumDiscountAttribute.isOptional = true
        
        let applicableCategoriesAttribute = NSAttributeDescription()
        applicableCategoriesAttribute.name = "applicableCategories"
        applicableCategoriesAttribute.attributeType = .stringAttributeType
        applicableCategoriesAttribute.isOptional = true
        
        let descriptionAttribute = NSAttributeDescription()
        descriptionAttribute.name = "description_"
        descriptionAttribute.attributeType = .stringAttributeType
        descriptionAttribute.isOptional = true
        
        let createdAtAttribute = NSAttributeDescription()
        createdAtAttribute.name = "createdAt"
        createdAtAttribute.attributeType = .dateAttributeType
        createdAtAttribute.isOptional = true
        
        let updatedAtAttribute = NSAttributeDescription()
        updatedAtAttribute.name = "updatedAt"
        updatedAtAttribute.attributeType = .dateAttributeType
        updatedAtAttribute.isOptional = true
        
        entity.properties = [
            idAttribute,
            codeAttribute,
            typeAttribute,
            valueAttribute,
            startDateAttribute,
            endDateAttribute,
            usageLimitAttribute,
            usageCountAttribute,
            isActiveAttribute,
            minimumPurchaseAttribute,
            maximumDiscountAttribute,
            applicableCategoriesAttribute,
            descriptionAttribute,
            createdAtAttribute,
            updatedAtAttribute
        ]
        
        let codeIndex = NSFetchIndexDescription(name: "discount_code_index", elements: [NSFetchIndexElementDescription(property: codeAttribute, collationType: .binary)])
        entity.indexes = [codeIndex]
        
        return entity
    }
}
