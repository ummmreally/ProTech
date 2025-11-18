import CoreData

@objc(Customer)
public class Customer: NSManagedObject {
}

extension Customer {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Customer> {
        NSFetchRequest<Customer>(entityName: "Customer")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var firstName: String?
    @NSManaged public var lastName: String?
    @NSManaged public var email: String?
    @NSManaged public var phone: String?
    @NSManaged public var address: String?
    @NSManaged public var notes: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var cloudSyncStatus: String?
    @NSManaged public var squareCustomerId: String?
}

extension Customer: Identifiable {}


extension Customer {
    /// Preferred display name using first/last name or fallback contact details.
    var displayName: String {
        let first = firstName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let last = lastName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let combined = "\(first) \(last)".trimmingCharacters(in: .whitespaces)
        if !combined.isEmpty {
            return combined
        }
        if let email = email, !email.isEmpty {
            return email
        }
        if let phone = phone, !phone.isEmpty {
            return phone
        }
        return "Customer"
    }
    
    /// Display name for migration purposes
    var migrationDisplayName: String {
        return displayName
    }
}


extension Customer {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "Customer"
        entity.managedObjectClassName = NSStringFromClass(Customer.self)

        let idAttribute = NSAttributeDescription()
        idAttribute.name = "id"
        idAttribute.attributeType = .UUIDAttributeType
        idAttribute.isOptional = false

        let firstNameAttribute = NSAttributeDescription()
        firstNameAttribute.name = "firstName"
        firstNameAttribute.attributeType = .stringAttributeType
        firstNameAttribute.isOptional = true

        let lastNameAttribute = NSAttributeDescription()
        lastNameAttribute.name = "lastName"
        lastNameAttribute.attributeType = .stringAttributeType
        lastNameAttribute.isOptional = true

        let emailAttribute = NSAttributeDescription()
        emailAttribute.name = "email"
        emailAttribute.attributeType = .stringAttributeType
        emailAttribute.isOptional = true

        let phoneAttribute = NSAttributeDescription()
        phoneAttribute.name = "phone"
        phoneAttribute.attributeType = .stringAttributeType
        phoneAttribute.isOptional = true

        let addressAttribute = NSAttributeDescription()
        addressAttribute.name = "address"
        addressAttribute.attributeType = .stringAttributeType
        addressAttribute.isOptional = true

        let notesAttribute = NSAttributeDescription()
        notesAttribute.name = "notes"
        notesAttribute.attributeType = .stringAttributeType
        notesAttribute.isOptional = true

        let createdAtAttribute = NSAttributeDescription()
        createdAtAttribute.name = "createdAt"
        createdAtAttribute.attributeType = .dateAttributeType
        createdAtAttribute.isOptional = true

        let updatedAtAttribute = NSAttributeDescription()
        updatedAtAttribute.name = "updatedAt"
        updatedAtAttribute.attributeType = .dateAttributeType
        updatedAtAttribute.isOptional = true

        let cloudSyncStatusAttribute = NSAttributeDescription()
        cloudSyncStatusAttribute.name = "cloudSyncStatus"
        cloudSyncStatusAttribute.attributeType = .stringAttributeType
        cloudSyncStatusAttribute.isOptional = true

        let squareCustomerIdAttribute = NSAttributeDescription()
        squareCustomerIdAttribute.name = "squareCustomerId"
        squareCustomerIdAttribute.attributeType = .stringAttributeType
        squareCustomerIdAttribute.isOptional = true

        entity.properties = [
            idAttribute,
            firstNameAttribute,
            lastNameAttribute,
            emailAttribute,
            phoneAttribute,
            addressAttribute,
            notesAttribute,
            createdAtAttribute,
            updatedAtAttribute,
            cloudSyncStatusAttribute,
            squareCustomerIdAttribute
        ]

        let idIndex = NSFetchIndexDescription(name: "customer_id_index", elements: [NSFetchIndexElementDescription(property: idAttribute, collationType: .binary)])
        entity.indexes = [idIndex]

        return entity
    }
}
