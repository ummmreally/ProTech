//
//  ShippingLabel.swift
//  ProTech
//
//  Represents a shipping label for a ticket (Inbound/Outbound).
//

import CoreData

@objc(ShippingLabel)
public class ShippingLabel: NSManagedObject {}

extension ShippingLabel {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ShippingLabel> {
        NSFetchRequest<ShippingLabel>(entityName: "ShippingLabel")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var ticketId: UUID?
    @NSManaged public var trackingNumber: String?
    @NSManaged public var carrier: String?       // "UPS", "FedEx", "USPS"
    @NSManaged public var status: String?        // "created", "shipped", "delivered"
    @NSManaged public var direction: String?     // "inbound", "outbound"
    @NSManaged public var labelUrl: String?      // URL to PDF
    @NSManaged public var cost: NSDecimalNumber?
    @NSManaged public var createdAt: Date?
    @NSManaged public var estimatedDelivery: Date?
}

extension ShippingLabel: Identifiable {}
