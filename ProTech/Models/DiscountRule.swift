//
//  DiscountRule.swift
//  ProTech
//
//  Represents a reusable discount rule (e.g. "Senior Citizen 10%")
//

import CoreData

@objc(DiscountRule)
public class DiscountRule: NSManagedObject {}

extension DiscountRule {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DiscountRule> {
        NSFetchRequest<DiscountRule>(entityName: "DiscountRule")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?       // "Employee Discount"
    @NSManaged public var code: String?       // "EMP10"
    @NSManaged public var type: String?       // "percentage", "fixed"
    @NSManaged public var value: NSDecimalNumber? // 10.0
    @NSManaged public var isActive: Bool
    @NSManaged public var createdAt: Date?
    
    var formattedValue: String {
        guard let value = value else { return "" }
        if type == "percentage" {
            return "\(value)%"
        } else {
            return NumberFormatter.currency.string(from: value) ?? ""
        }
    }
}

extension DiscountRule: Identifiable {}
