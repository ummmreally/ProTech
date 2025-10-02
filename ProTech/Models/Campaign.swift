//
//  Campaign.swift
//  ProTech
//
//  Marketing campaign model
//

import Foundation
import CoreData

@objc(Campaign)
public class Campaign: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var campaignType: String? // review_request, follow_up, birthday, anniversary, re_engagement, promotional
    @NSManaged public var status: String? // draft, scheduled, active, paused, completed
    @NSManaged public var emailSubject: String?
    @NSManaged public var emailBody: String?
    @NSManaged public var scheduledDate: Date?
    @NSManaged public var completedDate: Date?
    @NSManaged public var targetSegment: String? // all, recent_customers, inactive, high_value
    @NSManaged public var daysAfterEvent: Int16 // Days after ticket completion/purchase to send
    @NSManaged public var sendCount: Int32
    @NSManaged public var openCount: Int32
    @NSManaged public var clickCount: Int32
    @NSManaged public var unsubscribeCount: Int32
    @NSManaged public var isRecurring: Bool
    @NSManaged public var recurringInterval: String? // daily, weekly, monthly
    @NSManaged public var lastRunDate: Date?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    
    // Convenience initializer
    convenience init(context: NSManagedObjectContext,
                    name: String,
                    campaignType: String,
                    emailSubject: String,
                    emailBody: String,
                    targetSegment: String = "all") {
        self.init(context: context)
        self.id = UUID()
        self.name = name
        self.campaignType = campaignType
        self.emailSubject = emailSubject
        self.emailBody = emailBody
        self.targetSegment = targetSegment
        self.status = "draft"
        self.daysAfterEvent = 0
        self.sendCount = 0
        self.openCount = 0
        self.clickCount = 0
        self.unsubscribeCount = 0
        self.isRecurring = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Fetch Request

extension Campaign {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Campaign> {
        return NSFetchRequest<Campaign>(entityName: "Campaign")
    }
    
    static func fetchActiveCampaigns(context: NSManagedObjectContext) -> [Campaign] {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "status == %@", "active")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }
    
    static func fetchCampaignsByType(_ type: String, context: NSManagedObjectContext) -> [Campaign] {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "campaignType == %@", type)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }
}

extension Campaign {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "Campaign"
        entity.managedObjectClassName = NSStringFromClass(Campaign.self)
        
        func makeAttribute(_ name: String, type: NSAttributeType, optional: Bool = true, defaultValue: Any? = nil) -> NSAttributeDescription {
            let attribute = NSAttributeDescription()
            attribute.name = name
            attribute.attributeType = type
            attribute.isOptional = optional
            if let defaultValue {
                attribute.defaultValue = defaultValue
            }
            return attribute
        }
        
        entity.properties = [
            makeAttribute("id", type: .UUIDAttributeType, optional: false),
            makeAttribute("name", type: .stringAttributeType),
            makeAttribute("campaignType", type: .stringAttributeType),
            makeAttribute("status", type: .stringAttributeType, optional: false, defaultValue: "draft"),
            makeAttribute("emailSubject", type: .stringAttributeType),
            makeAttribute("emailBody", type: .stringAttributeType),
            makeAttribute("scheduledDate", type: .dateAttributeType),
            makeAttribute("completedDate", type: .dateAttributeType),
            makeAttribute("targetSegment", type: .stringAttributeType, optional: false, defaultValue: "all"),
            makeAttribute("daysAfterEvent", type: .integer16AttributeType, optional: false, defaultValue: 0),
            makeAttribute("sendCount", type: .integer32AttributeType, optional: false, defaultValue: 0),
            makeAttribute("openCount", type: .integer32AttributeType, optional: false, defaultValue: 0),
            makeAttribute("clickCount", type: .integer32AttributeType, optional: false, defaultValue: 0),
            makeAttribute("unsubscribeCount", type: .integer32AttributeType, optional: false, defaultValue: 0),
            makeAttribute("isRecurring", type: .booleanAttributeType, optional: false, defaultValue: false),
            makeAttribute("recurringInterval", type: .stringAttributeType),
            makeAttribute("lastRunDate", type: .dateAttributeType),
            makeAttribute("createdAt", type: .dateAttributeType),
            makeAttribute("updatedAt", type: .dateAttributeType)
        ]
        
        if let idAttribute = entity.properties.first(where: { $0.name == "id" }) as? NSAttributeDescription {
            let idIndex = NSFetchIndexDescription(name: "campaign_id_index", elements: [NSFetchIndexElementDescription(property: idAttribute, collationType: .binary)])
            entity.indexes = [idIndex]
        }
        
        return entity
    }
}

// MARK: - Computed Properties

extension Campaign {
    var openRate: Double {
        guard sendCount > 0 else { return 0 }
        return (Double(openCount) / Double(sendCount)) * 100
    }
    
    var clickRate: Double {
        guard sendCount > 0 else { return 0 }
        return (Double(clickCount) / Double(sendCount)) * 100
    }
    
    var unsubscribeRate: Double {
        guard sendCount > 0 else { return 0 }
        return (Double(unsubscribeCount) / Double(sendCount)) * 100
    }
    
    var statusDisplay: String {
        switch status {
        case "draft": return "Draft"
        case "scheduled": return "Scheduled"
        case "active": return "Active"
        case "paused": return "Paused"
        case "completed": return "Completed"
        default: return status?.capitalized ?? "Unknown"
        }
    }
    
    var typeDisplay: String {
        switch campaignType {
        case "review_request": return "Review Request"
        case "follow_up": return "Follow-up"
        case "birthday": return "Birthday"
        case "anniversary": return "Anniversary"
        case "re_engagement": return "Re-engagement"
        case "promotional": return "Promotional"
        default: return campaignType?.capitalized ?? "Unknown"
        }
    }
}

// MARK: - Marketing Rule Model

@objc(MarketingRule)
public class MarketingRule: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var ruleType: String? // review_request, follow_up, birthday, etc.
    @NSManaged public var triggerEvent: String? // ticket_completed, ticket_picked_up, customer_birthday
    @NSManaged public var daysAfterTrigger: Int16
    @NSManaged public var isActive: Bool
    @NSManaged public var campaignId: UUID?
    @NSManaged public var lastTriggeredDate: Date?
    @NSManaged public var triggerCount: Int32
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    
    convenience init(context: NSManagedObjectContext,
                    name: String,
                    ruleType: String,
                    triggerEvent: String,
                    daysAfterTrigger: Int = 3,
                    campaignId: UUID) {
        self.init(context: context)
        self.id = UUID()
        self.name = name
        self.ruleType = ruleType
        self.triggerEvent = triggerEvent
        self.daysAfterTrigger = Int16(daysAfterTrigger)
        self.campaignId = campaignId
        self.isActive = true
        self.triggerCount = 0
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

extension MarketingRule {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MarketingRule> {
        return NSFetchRequest<MarketingRule>(entityName: "MarketingRule")
    }
    
    static func fetchActiveRules(context: NSManagedObjectContext) -> [MarketingRule] {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "isActive == true")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }
}

// MARK: - Campaign Send Log

@objc(CampaignSendLog)
public class CampaignSendLog: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var campaignId: UUID?
    @NSManaged public var customerId: UUID?
    @NSManaged public var emailAddress: String?
    @NSManaged public var status: String? // sent, opened, clicked, bounced, unsubscribed
    @NSManaged public var sentAt: Date?
    @NSManaged public var openedAt: Date?
    @NSManaged public var clickedAt: Date?
    @NSManaged public var unsubscribedAt: Date?
    @NSManaged public var errorMessage: String?
    
    convenience init(context: NSManagedObjectContext,
                    campaignId: UUID,
                    customerId: UUID,
                    emailAddress: String) {
        self.init(context: context)
        self.id = UUID()
        self.campaignId = campaignId
        self.customerId = customerId
        self.emailAddress = emailAddress
        self.status = "sent"
        self.sentAt = Date()
    }
}

extension CampaignSendLog {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CampaignSendLog> {
        return NSFetchRequest<CampaignSendLog>(entityName: "CampaignSendLog")
    }
    
    static func fetchLogs(for campaignId: UUID, context: NSManagedObjectContext) -> [CampaignSendLog] {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "campaignId == %@", campaignId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "sentAt", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }
}
