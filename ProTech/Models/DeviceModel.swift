//
//  DeviceModel.swift
//  ProTech
//
//  Represents a specific device model (e.g., "iPhone 13 Pro")
//

import CoreData

@objc(DeviceModel)
public class DeviceModel: NSManagedObject {}

extension DeviceModel {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DeviceModel> {
        NSFetchRequest<DeviceModel>(entityName: "DeviceModel")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?       // "iPhone 13 Pro"
    @NSManaged public var identifier: String? // "A2638"
    @NSManaged public var type: String?       // "iPhone", "iPad", "Mac", "Watch"
    @NSManaged public var releaseYear: Int16
    @NSManaged public var imageSystemName: String? // "iphone"
    @NSManaged public var procedures: NSSet?
}

// MARK: - Core Data Generated Accessors for procedures
extension DeviceModel {
    @objc(addProceduresObject:)
    @NSManaged public func addToProcedures(_ value: RepairProcedure)

    @objc(removeProceduresObject:)
    @NSManaged public func removeFromProcedures(_ value: RepairProcedure)

    @objc(addProcedures:)
    @NSManaged public func addToProcedures(_ values: NSSet)

    @objc(removeProcedures:)
    @NSManaged public func removeFromProcedures(_ values: NSSet)
}

extension DeviceModel: Identifiable {}
