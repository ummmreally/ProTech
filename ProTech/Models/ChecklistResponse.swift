//
//  ChecklistResponse.swift
//  ProTech
//
//  Stores responses to checklist items (Intake, QC, etc.)
//

import CoreData

@objc(ChecklistResponse)
public class ChecklistResponse: NSManagedObject {}

extension ChecklistResponse {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChecklistResponse> {
        NSFetchRequest<ChecklistResponse>(entityName: "ChecklistResponse")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var ticketId: UUID?
    @NSManaged public var category: String? // "intake", "qc"
    @NSManaged public var item: String? // "Screen Cracked", "Touch ID"
    @NSManaged public var isPassed: Bool // true = Yes/Pass, false = No/Fail
    @NSManaged public var notes: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var checkedBy: String?
}

extension ChecklistResponse: Identifiable {}
