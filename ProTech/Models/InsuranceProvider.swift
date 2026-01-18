//
//  InsuranceProvider.swift
//  ProTech
//
//  Represents an insurance company or warranty provider.
//

import CoreData

@objc(InsuranceProvider)
public class InsuranceProvider: NSManagedObject {}

extension InsuranceProvider {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<InsuranceProvider> {
        NSFetchRequest<InsuranceProvider>(entityName: "InsuranceProvider")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?       // "Asurion"
    @NSManaged public var claimsEmail: String?
    @NSManaged public var portalUrl: String?
    @NSManaged public var phoneNumber: String?
    @NSManaged public var notes: String?
}

extension InsuranceProvider: Identifiable {}
