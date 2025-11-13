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
    @NSManaged public var templateDescription: String?
    @NSManaged public var instructions: String?
    @NSManaged public var isDefault: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
}

extension FormTemplate: Identifiable {}

// MARK: - Form Field Structures

struct FormField: Codable, Identifiable {
    var id: UUID
    var type: FieldType
    var label: String
    var placeholder: String?
    var isRequired: Bool
    var options: [String]? // For dropdowns, checkboxes, radio buttons
    var defaultValue: String?
    var order: Int
    
    enum FieldType: String, Codable {
        case text
        case multiline
        case number
        case email
        case phone
        case date
        case dropdown
        case checkbox
        case radio
        case signature
        case yesNo
    }
}

struct FormTemplateData: Codable {
    var fields: [FormField]
    var description: String?
    var instructions: String?
}

extension FormTemplate {
    var fields: [FormField] {
        guard let json = templateJSON,
              let data = json.data(using: .utf8),
              let templateData = try? JSONDecoder().decode(FormTemplateData.self, from: data) else {
            return []
        }
        return templateData.fields.sorted { $0.order < $1.order }
    }
    
    var templateData: FormTemplateData? {
        guard let json = templateJSON,
              let data = json.data(using: .utf8) else {
            return nil
        }
        return try? JSONDecoder().decode(FormTemplateData.self, from: data)
    }
    
    func setFields(_ fields: [FormField], description: String? = nil, instructions: String? = nil) {
        let templateData = FormTemplateData(fields: fields, description: description, instructions: instructions)
        if let data = try? JSONEncoder().encode(templateData),
           let json = String(data: data, encoding: .utf8) {
            self.templateJSON = json
        }
        if let description {
            self.templateDescription = description
        }
        if let instructions {
            self.instructions = instructions
        }
    }
    
    static func fetchAllTemplates(context: NSManagedObjectContext) -> [FormTemplate] {
        let request = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        return (try? context.fetch(request)) ?? []
    }
    
    static func fetchDefaultTemplates(context: NSManagedObjectContext) -> [FormTemplate] {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "isDefault == true")
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        return (try? context.fetch(request)) ?? []
    }
    
    static func fetchTemplate(byId id: UUID, context: NSManagedObjectContext) -> FormTemplate? {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
}


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
