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

// MARK: - Form Submission Data

struct FormResponseData: Codable {
    var responses: [String: String] // Field ID : Value
    var submitterName: String?
    var submitterEmail: String?
}

extension FormSubmission {
    var responses: [String: String] {
        guard let json = dataJSON,
              let data = json.data(using: .utf8),
              let responseData = try? JSONDecoder().decode(FormResponseData.self, from: data) else {
            return [:]
        }
        return responseData.responses
    }
    
    var responseData: FormResponseData? {
        guard let json = dataJSON,
              let data = json.data(using: .utf8) else {
            return nil
        }
        return try? JSONDecoder().decode(FormResponseData.self, from: data)
    }
    
    func setResponses(_ responses: [String: String], submitterName: String? = nil, submitterEmail: String? = nil) {
        let responseData = FormResponseData(responses: responses, submitterName: submitterName, submitterEmail: submitterEmail)
        if let data = try? JSONEncoder().encode(responseData),
           let json = String(data: data, encoding: .utf8) {
            self.dataJSON = json
        }
    }
    
    static func fetchSubmissions(for formId: UUID, context: NSManagedObjectContext) -> [FormSubmission] {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "formID == %@", formId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "submittedAt", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }
    
    static func fetchAllSubmissions(context: NSManagedObjectContext) -> [FormSubmission] {
        let request = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "submittedAt", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }
}


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
