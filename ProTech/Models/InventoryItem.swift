import CoreData

@objc(InventoryItem)
public class InventoryItem: NSManagedObject {}

extension InventoryItem {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<InventoryItem> {
        NSFetchRequest<InventoryItem>(entityName: "InventoryItem")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var itemName: String? // Additional name field in schema
    @NSManaged public var partNumber: String?
    @NSManaged public var sku: String?
    @NSManaged public var category: String?
    @NSManaged public var categoryName: String? // Additional category field in schema
    
    // Stock
    @NSManaged public var quantity: Int32
    @NSManaged public var minQuantity: Int32
    
    // Pricing - Core Data uses Decimal type
    @NSManaged public var cost: NSDecimalNumber
    @NSManaged public var price: NSDecimalNumber
    
    // Status
    @NSManaged public var isActive: Bool
    
    // Metadata
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var cloudSyncStatus: String?
    
    // Convenience accessors for Double conversion
    var costDouble: Double {
        get { cost.doubleValue }
        set { cost = NSDecimalNumber(value: newValue) }
    }
    
    var priceDouble: Double {
        get { price.doubleValue }
        set { price = NSDecimalNumber(value: newValue) }
    }
    
    // Computed properties
    var totalValue: Double {
        Double(quantity) * costDouble
    }
    
    var isLowStock: Bool {
        quantity <= minQuantity
    }
    
    var isOutOfStock: Bool {
        quantity <= 0
    }
    
    var profitMargin: Double {
        guard priceDouble > 0 else { return 0 }
        return ((priceDouble - costDouble) / priceDouble) * 100
    }
    
    var formattedPrice: String {
        String(format: "$%.2f", priceDouble)
    }
    
    /// Display name for migration purposes
    var migrationDisplayName: String {
        return name ?? "Unknown Item"
    }
}

extension InventoryItem: Identifiable {}
