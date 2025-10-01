import CoreData

@objc(FormTemplate)
public class FormTemplate: NSManagedObject {
}

extension FormTemplate {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<FormTemplate> {
        NSFetchRequest<FormTemplate>(entityName: "FormTemplate")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var type: String?
    @NSManaged public var templateJSON: String?
    @NSManaged public var isDefault: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
}

extension FormTemplate: Identifiable {}


extension FormTemplate {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "FormTemplate"
        entity.managedObjectClassName = NSStringFromClass(FormTemplate.self)

        let idAttribute = NSAttributeDescription()
        idAttribute.name = "id"
        idAttribute.attributeType = .UUIDAttributeType
        idAttribute.isOptional = false

        let nameAttribute = NSAttributeDescription()
        nameAttribute.name = "name"
        nameAttribute.attributeType = .stringAttributeType
        nameAttribute.isOptional = true

        let typeAttribute = NSAttributeDescription()
        typeAttribute.name = "type"
        typeAttribute.attributeType = .stringAttributeType
        typeAttribute.isOptional = true

        let templateJSONAttribute = NSAttributeDescription()
        templateJSONAttribute.name = "templateJSON"
        templateJSONAttribute.attributeType = .stringAttributeType
        templateJSONAttribute.isOptional = true

        let isDefaultAttribute = NSAttributeDescription()
        isDefaultAttribute.name = "isDefault"
        isDefaultAttribute.attributeType = .booleanAttributeType
        isDefaultAttribute.defaultValue = false

        let createdAtAttribute = NSAttributeDescription()
        createdAtAttribute.name = "createdAt"
        createdAtAttribute.attributeType = .dateAttributeType
        createdAtAttribute.isOptional = true

        let updatedAtAttribute = NSAttributeDescription()
        updatedAtAttribute.name = "updatedAt"
        updatedAtAttribute.attributeType = .dateAttributeType
        updatedAtAttribute.isOptional = true

        entity.properties = [
            idAttribute,
            nameAttribute,
            typeAttribute,
            templateJSONAttribute,
            isDefaultAttribute,
            createdAtAttribute,
            updatedAtAttribute
        ]

        let idIndex = NSFetchIndexDescription(name: "form_template_id_index", elements: [NSFetchIndexElementDescription(property: idAttribute, collationType: .binary)])
        entity.indexes = [idIndex]

        return entity
    }
}
