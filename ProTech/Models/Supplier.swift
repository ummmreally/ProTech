//
//  Supplier.swift
//  ProTech
//
//  Model for tracking product suppliers/vendors.
//

import CoreData

@objc(Supplier)
public class Supplier: NSManagedObject {}

extension Supplier {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Supplier> {
        NSFetchRequest<Supplier>(entityName: "Supplier")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var contactName: String?
    @NSManaged public var email: String?
    @NSManaged public var phone: String?
    @NSManaged public var website: String?
    @NSManaged public var notes: String?
    @NSManaged public var isActive: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
}

extension Supplier: Identifiable {}
