import CoreData

@objc(FormSubmission)
public class FormSubmission: NSManagedObject {
}

extension FormSubmission {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<FormSubmission> {
        NSFetchRequest<FormSubmission>(entityName: "FormSubmission")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var formID: UUID?
    @NSManaged public var dataJSON: String?
    @NSManaged public var submittedAt: Date?
    @NSManaged public var signatureData: Data?
}

extension FormSubmission: Identifiable {}


extension FormSubmission {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "FormSubmission"
        entity.managedObjectClassName = NSStringFromClass(FormSubmission.self)

        let idAttribute = NSAttributeDescription()
        idAttribute.name = "id"
        idAttribute.attributeType = .UUIDAttributeType
        idAttribute.isOptional = false

        let formIDAttribute = NSAttributeDescription()
        formIDAttribute.name = "formID"
        formIDAttribute.attributeType = .UUIDAttributeType
        formIDAttribute.isOptional = true

        let dataJSONAttribute = NSAttributeDescription()
        dataJSONAttribute.name = "dataJSON"
        dataJSONAttribute.attributeType = .stringAttributeType
        dataJSONAttribute.isOptional = true

        let submittedAtAttribute = NSAttributeDescription()
        submittedAtAttribute.name = "submittedAt"
        submittedAtAttribute.attributeType = .dateAttributeType
        submittedAtAttribute.isOptional = true

        let signatureAttribute = NSAttributeDescription()
        signatureAttribute.name = "signatureData"
        signatureAttribute.attributeType = .binaryDataAttributeType
        signatureAttribute.isOptional = true
        signatureAttribute.allowsExternalBinaryDataStorage = true

        entity.properties = [
            idAttribute,
            formIDAttribute,
            dataJSONAttribute,
            submittedAtAttribute,
            signatureAttribute
        ]

        let idIndex = NSFetchIndexDescription(name: "form_submission_id_index", elements: [NSFetchIndexElementDescription(property: idAttribute, collationType: .binary)])
        entity.indexes = [idIndex]

        return entity
    }
}
