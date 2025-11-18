import CoreData

@objc(Ticket)
public class Ticket: NSManagedObject {}

extension Ticket {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Ticket> {
        NSFetchRequest<Ticket>(entityName: "Ticket")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var ticketNumber: Int32
    @NSManaged public var customerId: UUID?
    @NSManaged public var deviceType: String?
    @NSManaged public var deviceModel: String?
    @NSManaged public var issueDescription: String?
    @NSManaged public var status: String?
    @NSManaged public var priority: String?
    @NSManaged public var notes: String?
    @NSManaged public var estimatedCost: NSDecimalNumber?
    @NSManaged public var actualCost: NSDecimalNumber?
    @NSManaged public var checkedInAt: Date?
    @NSManaged public var startedAt: Date?
    @NSManaged public var completedAt: Date?
    @NSManaged public var pickedUpAt: Date?
    @NSManaged public var estimatedCompletion: Date?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var deviceSerialNumber: String?
    @NSManaged public var marketingOptInSMS: Bool
    @NSManaged public var marketingOptInEmail: Bool
    @NSManaged public var marketingOptInMail: Bool
    @NSManaged public var hasDataBackup: Bool
    @NSManaged public var devicePasscode: String?
    @NSManaged public var findMyDisabled: Bool
    @NSManaged public var alternateContactName: String?
    @NSManaged public var alternateContactNumber: String?
    @NSManaged public var additionalRepairDetails: String?
    @NSManaged public var checkInSignature: Data?
    @NSManaged public var checkInAgreedAt: Date?
}

extension Ticket: Identifiable {}

extension Ticket {
    /// Display name for migration purposes
    var migrationDisplayName: String {
        return "Ticket #\(ticketNumber)"
    }
    
    /// Customer display name (requires fetching customer from Core Data)
    var customerDisplayName: String {
        guard let customerId = customerId else { return "Unknown Customer" }
        
        let context = CoreDataManager.shared.viewContext
        let request: NSFetchRequest<Customer> = Customer.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", customerId as CVarArg)
        request.fetchLimit = 1
        
        if let customer = try? context.fetch(request).first {
            return customer.displayName
        }
        
        return "Unknown Customer"
    }
}

extension Ticket {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "Ticket"
        entity.managedObjectClassName = NSStringFromClass(Ticket.self)
        
        func makeAttribute(_ name: String, type: NSAttributeType, optional: Bool = true, defaultValue: Any? = nil) -> NSAttributeDescription {
            let attribute = NSAttributeDescription()
            attribute.name = name
            attribute.attributeType = type
            attribute.isOptional = optional
            if let defaultValue = defaultValue {
                attribute.defaultValue = defaultValue
            }
            return attribute
        }
        
        let idAttribute = makeAttribute("id", type: .UUIDAttributeType, optional: false)
        let ticketNumberAttribute = makeAttribute("ticketNumber", type: .integer32AttributeType)
        let customerIdAttribute = makeAttribute("customerId", type: .UUIDAttributeType, optional: false)
        let deviceTypeAttribute = makeAttribute("deviceType", type: .stringAttributeType)
        let deviceModelAttribute = makeAttribute("deviceModel", type: .stringAttributeType)
        let issueDescriptionAttribute = makeAttribute("issueDescription", type: .stringAttributeType)
        let statusAttribute = makeAttribute("status", type: .stringAttributeType)
        let priorityAttribute = makeAttribute("priority", type: .stringAttributeType)
        let notesAttribute = makeAttribute("notes", type: .stringAttributeType)
        let estimatedCostAttribute = makeAttribute("estimatedCost", type: .decimalAttributeType)
        let actualCostAttribute = makeAttribute("actualCost", type: .decimalAttributeType)
        let checkedInAtAttribute = makeAttribute("checkedInAt", type: .dateAttributeType)
        let startedAtAttribute = makeAttribute("startedAt", type: .dateAttributeType)
        let completedAtAttribute = makeAttribute("completedAt", type: .dateAttributeType)
        let pickedUpAtAttribute = makeAttribute("pickedUpAt", type: .dateAttributeType)
        let estimatedCompletionAttribute = makeAttribute("estimatedCompletion", type: .dateAttributeType)
        let createdAtAttribute = makeAttribute("createdAt", type: .dateAttributeType, optional: false)
        let updatedAtAttribute = makeAttribute("updatedAt", type: .dateAttributeType, optional: false)
        let deviceSerialAttribute = makeAttribute("deviceSerialNumber", type: .stringAttributeType)
        let smsOptInAttribute = makeAttribute("marketingOptInSMS", type: .booleanAttributeType, optional: false, defaultValue: false)
        let emailOptInAttribute = makeAttribute("marketingOptInEmail", type: .booleanAttributeType, optional: false, defaultValue: false)
        let mailOptInAttribute = makeAttribute("marketingOptInMail", type: .booleanAttributeType, optional: false, defaultValue: false)
        let dataBackupAttribute = makeAttribute("hasDataBackup", type: .booleanAttributeType, optional: false, defaultValue: false)
        let passcodeAttribute = makeAttribute("devicePasscode", type: .stringAttributeType)
        let findMyAttribute = makeAttribute("findMyDisabled", type: .booleanAttributeType, optional: false, defaultValue: false)
        let altContactNameAttribute = makeAttribute("alternateContactName", type: .stringAttributeType)
        let altContactNumberAttribute = makeAttribute("alternateContactNumber", type: .stringAttributeType)
        let additionalDetailsAttribute = makeAttribute("additionalRepairDetails", type: .stringAttributeType)

        let signatureAttribute = NSAttributeDescription()
        signatureAttribute.name = "checkInSignature"
        signatureAttribute.attributeType = .binaryDataAttributeType
        signatureAttribute.isOptional = true
        signatureAttribute.allowsExternalBinaryDataStorage = true

        let agreementDateAttribute = makeAttribute("checkInAgreedAt", type: .dateAttributeType)

        entity.properties = [
            idAttribute,
            ticketNumberAttribute,
            customerIdAttribute,
            deviceTypeAttribute,
            deviceModelAttribute,
            issueDescriptionAttribute,
            statusAttribute,
            priorityAttribute,
            notesAttribute,
            estimatedCostAttribute,
            actualCostAttribute,
            checkedInAtAttribute,
            startedAtAttribute,
            completedAtAttribute,
            pickedUpAtAttribute,
            estimatedCompletionAttribute,
            createdAtAttribute,
            updatedAtAttribute,
            deviceSerialAttribute,
            smsOptInAttribute,
            emailOptInAttribute,
            mailOptInAttribute,
            dataBackupAttribute,
            passcodeAttribute,
            findMyAttribute,
            altContactNameAttribute,
            altContactNumberAttribute,
            additionalDetailsAttribute,
            signatureAttribute,
            agreementDateAttribute
        ]
        
        let idIndex = NSFetchIndexDescription(name: "ticket_id_index", elements: [NSFetchIndexElementDescription(property: idAttribute, collationType: .binary)])
        let customerIndex = NSFetchIndexDescription(name: "ticket_customer_index", elements: [NSFetchIndexElementDescription(property: customerIdAttribute, collationType: .binary)])
        entity.indexes = [idIndex, customerIndex]
        
        return entity
    }
}
