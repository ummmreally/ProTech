//
//  RepairProcedure.swift
//  ProTech
//
//  Represents a standard repair for a device (e.g., "Screen Replacement")
//

import CoreData

@objc(RepairProcedure)
public class RepairProcedure: NSManagedObject {}

extension RepairProcedure {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<RepairProcedure> {
        NSFetchRequest<RepairProcedure>(entityName: "RepairProcedure")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var name: String? // "Screen Replacement"
    @NSManaged public var baseCost: NSDecimalNumber?
    @NSManaged public var estimatedDurationMinutes: Int16
    @NSManaged public var deviceModel: DeviceModel?
}

extension RepairProcedure: Identifiable {}
