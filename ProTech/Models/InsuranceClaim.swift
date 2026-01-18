//
//  InsuranceClaim.swift
//  ProTech
//
//  Represents a claim filed for a repair.
//

import CoreData

@objc(InsuranceClaim)
public class InsuranceClaim: NSManagedObject {}

extension InsuranceClaim {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<InsuranceClaim> {
        NSFetchRequest<InsuranceClaim>(entityName: "InsuranceClaim")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var ticketId: UUID?
    @NSManaged public var providerId: UUID?
    @NSManaged public var claimNumber: String? // "CLM-12345"
    @NSManaged public var status: String?      // "draft", "submitted", "approved", "rejected", "paid"
    @NSManaged public var deductibleAmount: NSDecimalNumber?
    @NSManaged public var coverageAmount: NSDecimalNumber?
    @NSManaged public var notes: String?
    @NSManaged public var filedAt: Date?
    @NSManaged public var updatedAt: Date?
    
    // Relationships could be defined here, but keeping it decoupled via IDs for simplicity in this iteration
    // @NSManaged public var provider: InsuranceProvider?
}

extension InsuranceClaim: Identifiable {}
