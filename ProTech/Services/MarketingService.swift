//
//  MarketingService.swift
//  ProTech
//
//  Marketing automation and campaign management
//

import Foundation
import CoreData

class MarketingService {
    static let shared = MarketingService()
    
    private let coreDataManager = CoreDataManager.shared
    
    private init() {
        setupDefaultCampaigns()
    }
    
    // MARK: - Campaign Management
    
    func createCampaign(name: String, type: String, subject: String, body: String, targetSegment: String = "all", daysAfterEvent: Int = 0) -> Campaign {
        let context = coreDataManager.viewContext
        let campaign = Campaign(
            context: context,
            name: name,
            campaignType: type,
            emailSubject: subject,
            emailBody: body,
            targetSegment: targetSegment
        )
        campaign.daysAfterEvent = Int16(daysAfterEvent)
        
        try? context.save()
        return campaign
    }
    
    func updateCampaign(_ campaign: Campaign, name: String? = nil, subject: String? = nil, body: String? = nil, status: String? = nil) {
        if let name = name { campaign.name = name }
        if let subject = subject { campaign.emailSubject = subject }
        if let body = body { campaign.emailBody = body }
        if let status = status { campaign.status = status }
        
        campaign.updatedAt = Date()
        try? coreDataManager.viewContext.save()
    }
    
    func activateCampaign(_ campaign: Campaign) {
        campaign.status = "active"
        campaign.updatedAt = Date()
        try? coreDataManager.viewContext.save()
    }
    
    func pauseCampaign(_ campaign: Campaign) {
        campaign.status = "paused"
        campaign.updatedAt = Date()
        try? coreDataManager.viewContext.save()
    }
    
    func deleteCampaign(_ campaign: Campaign) {
        coreDataManager.viewContext.delete(campaign)
        try? coreDataManager.viewContext.save()
    }
    
    // MARK: - Marketing Rules
    
    func createRule(name: String, type: String, triggerEvent: String, daysAfter: Int, campaignId: UUID) -> MarketingRule {
        let context = coreDataManager.viewContext
        let rule = MarketingRule(
            context: context,
            name: name,
            ruleType: type,
            triggerEvent: triggerEvent,
            daysAfterTrigger: daysAfter,
            campaignId: campaignId
        )
        
        try? context.save()
        return rule
    }
    
    func toggleRule(_ rule: MarketingRule) {
        rule.isActive.toggle()
        rule.updatedAt = Date()
        try? coreDataManager.viewContext.save()
    }
    
    func deleteRule(_ rule: MarketingRule) {
        coreDataManager.viewContext.delete(rule)
        try? coreDataManager.viewContext.save()
    }
    
    // MARK: - Automated Campaigns
    
    func sendReviewRequest(for ticket: Ticket) {
        guard let campaign = getActiveCampaign(type: "review_request"),
              let customer = getCustomer(for: ticket),
              let email = customer.email else { return }
        
        let personalizedBody = personalizeCampaignContent(
            campaign.emailBody ?? "",
            customer: customer,
            ticket: ticket
        )
        
        sendEmail(
            to: email,
            subject: campaign.emailSubject ?? "",
            body: personalizedBody,
            campaignId: campaign.id!,
            customerId: customer.id!
        )
        
        // Update campaign stats
        campaign.sendCount += 1
        campaign.lastRunDate = Date()
        try? coreDataManager.viewContext.save()
    }
    
    func sendFollowUpEmail(for ticket: Ticket, daysAfter: Int) {
        guard let campaign = getActiveCampaign(type: "follow_up"),
              let customer = getCustomer(for: ticket),
              let email = customer.email else { return }
        
        let personalizedBody = personalizeCampaignContent(
            campaign.emailBody ?? "",
            customer: customer,
            ticket: ticket
        )
        
        sendEmail(
            to: email,
            subject: campaign.emailSubject ?? "",
            body: personalizedBody,
            campaignId: campaign.id!,
            customerId: customer.id!
        )
        
        campaign.sendCount += 1
        campaign.lastRunDate = Date()
        try? coreDataManager.viewContext.save()
    }
    
    func sendBirthdayEmail(for customer: Customer) {
        guard let campaign = getActiveCampaign(type: "birthday"),
              let email = customer.email else { return }
        
        let personalizedBody = personalizeCampaignContent(
            campaign.emailBody ?? "",
            customer: customer,
            ticket: nil
        )
        
        sendEmail(
            to: email,
            subject: campaign.emailSubject ?? "",
            body: personalizedBody,
            campaignId: campaign.id!,
            customerId: customer.id!
        )
        
        campaign.sendCount += 1
        campaign.lastRunDate = Date()
        try? coreDataManager.viewContext.save()
    }
    
    func sendReEngagementEmail(for customer: Customer) {
        guard let campaign = getActiveCampaign(type: "re_engagement"),
              let email = customer.email else { return }
        
        let personalizedBody = personalizeCampaignContent(
            campaign.emailBody ?? "",
            customer: customer,
            ticket: nil
        )
        
        sendEmail(
            to: email,
            subject: campaign.emailSubject ?? "",
            body: personalizedBody,
            campaignId: campaign.id!,
            customerId: customer.id!
        )
        
        campaign.sendCount += 1
        campaign.lastRunDate = Date()
        try? coreDataManager.viewContext.save()
    }
    
    // MARK: - Campaign Execution
    
    func runScheduledCampaigns() {
        let campaigns = Campaign.fetchActiveCampaigns(context: coreDataManager.viewContext)
        
        for campaign in campaigns {
            guard let type = campaign.campaignType else { continue }
            
            switch type {
            case "review_request":
                runReviewRequestCampaign(campaign)
            case "follow_up":
                runFollowUpCampaign(campaign)
            case "birthday":
                runBirthdayCampaign(campaign)
            case "re_engagement":
                runReEngagementCampaign(campaign)
            default:
                break
            }
        }
    }
    
    private func runReviewRequestCampaign(_ campaign: Campaign) {
        // Find tickets completed X days ago
        let daysAgo = Int(campaign.daysAfterEvent)
        let targetDate = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
        
        let request = Ticket.fetchRequest()
        request.predicate = NSPredicate(format: "status == %@ AND completedAt >= %@ AND completedAt < %@",
                                       "completed",
                                       Calendar.current.startOfDay(for: targetDate) as NSDate,
                                       Calendar.current.date(byAdding: .day, value: 1, to: targetDate)! as NSDate)
        
        let tickets = (try? coreDataManager.viewContext.fetch(request)) ?? []
        
        for ticket in tickets {
            // Check if we haven't already sent to this customer
            if !hasRecentlySent(campaignId: campaign.id!, customerId: ticket.customerId) {
                sendReviewRequest(for: ticket)
            }
        }
    }
    
    private func runFollowUpCampaign(_ campaign: Campaign) {
        // Similar logic to review requests
        let daysAgo = Int(campaign.daysAfterEvent)
        let targetDate = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
        
        let request = Ticket.fetchRequest()
        request.predicate = NSPredicate(format: "status == %@ AND pickedUpAt >= %@ AND pickedUpAt < %@",
                                       "picked_up",
                                       Calendar.current.startOfDay(for: targetDate) as NSDate,
                                       Calendar.current.date(byAdding: .day, value: 1, to: targetDate)! as NSDate)
        
        let tickets = (try? coreDataManager.viewContext.fetch(request)) ?? []
        
        for ticket in tickets {
            if !hasRecentlySent(campaignId: campaign.id!, customerId: ticket.customerId) {
                sendFollowUpEmail(for: ticket, daysAfter: daysAgo)
            }
        }
    }
    
    private func runBirthdayCampaign(_ campaign: Campaign) {
        // Requires customer birthday data; left as a placeholder until the model stores birthdays.
        print("Birthday campaign for \(campaign.name ?? "Birthday") skipped — customer birthdays not available yet.")
    }

    private func runReEngagementCampaign(_ campaign: Campaign) {
        // Placeholder: requires tracking of customer last-visit dates before it can be implemented.
        print("Re-engagement campaign for \(campaign.name ?? "Re-engagement") skipped — last visit tracking not implemented.")
    }
    
    // MARK: - Email Sending
    
    private func sendEmail(to email: String, subject: String, body: String, campaignId: UUID, customerId: UUID) {
        // Create send log
        let context = coreDataManager.viewContext
        let log = CampaignSendLog(
            context: context,
            campaignId: campaignId,
            customerId: customerId,
            emailAddress: email
        )
        _ = log
        
        try? context.save()
        
        // In production, integrate with email service (SendGrid, Mailgun, etc.)
        print("📧 Sending email to: \(email)")
        print("Subject: \(subject)")
        print("Body: \(body)")
        
        // Simulate email sending
        // In real implementation, use URLSession to call email API
    }
    
    // MARK: - Personalization
    
    private func personalizeCampaignContent(_ content: String, customer: Customer, ticket: Ticket?) -> String {
        var personalized = content
        
        // Replace placeholders
        personalized = personalized.replacingOccurrences(of: "{customer_name}", with: "\(customer.firstName ?? "") \(customer.lastName ?? "")")
        personalized = personalized.replacingOccurrences(of: "{first_name}", with: customer.firstName ?? "")
        personalized = personalized.replacingOccurrences(of: "{last_name}", with: customer.lastName ?? "")
        
        if let ticket = ticket {
            personalized = personalized.replacingOccurrences(of: "{ticket_number}", with: "\(ticket.ticketNumber)")
            personalized = personalized.replacingOccurrences(of: "{device_type}", with: ticket.deviceType ?? "")
            personalized = personalized.replacingOccurrences(of: "{device_model}", with: ticket.deviceModel ?? "")
        }
        
        personalized = personalized.replacingOccurrences(of: "{company_name}", with: "ProTech")
        
        return personalized
    }
    
    // MARK: - Helper Methods
    
    private func getActiveCampaign(type: String) -> Campaign? {
        let campaigns = Campaign.fetchCampaignsByType(type, context: coreDataManager.viewContext)
        return campaigns.first { $0.status == "active" }
    }
    
    private func getCustomer(for ticket: Ticket) -> Customer? {
        guard let customerId = ticket.customerId else { return nil }
        return CoreDataManager.shared.fetchCustomer(id: customerId)
    }
    
    private func hasRecentlySent(campaignId: UUID, customerId: UUID?) -> Bool {
        guard let customerId = customerId else { return false }
        
        let request = CampaignSendLog.fetchRequest()
        request.predicate = NSPredicate(
            format: "campaignId == %@ AND customerId == %@ AND sentAt >= %@",
            campaignId as CVarArg,
            customerId as CVarArg,
            Calendar.current.date(byAdding: .day, value: -30, to: Date())! as NSDate
        )
        request.fetchLimit = 1
        
        let logs = (try? coreDataManager.viewContext.fetch(request)) ?? []
        return !logs.isEmpty
    }
    
    // MARK: - Analytics
    
    func getCampaignStats(for campaign: Campaign) -> CampaignStats {
        let logs = CampaignSendLog.fetchLogs(for: campaign.id!, context: coreDataManager.viewContext)
        
        return CampaignStats(
            totalSent: logs.count,
            opened: logs.filter { $0.openedAt != nil }.count,
            clicked: logs.filter { $0.clickedAt != nil }.count,
            unsubscribed: logs.filter { $0.unsubscribedAt != nil }.count,
            openRate: campaign.openRate,
            clickRate: campaign.clickRate
        )
    }
    
    // MARK: - Default Templates
    
    private func setupDefaultCampaigns() {
        // Check if defaults already exist
        let existing = Campaign.fetchCampaignsByType("review_request", context: coreDataManager.viewContext)
        if !existing.isEmpty { return }
        
        // Review Request Template
        _ = createCampaign(
            name: "Automatic Review Request",
            type: "review_request",
            subject: "How was your experience with {company_name}?",
            body: """
            Hi {first_name},
            
            Thank you for choosing {company_name} for your {device_type} repair (Ticket #{ticket_number}).
            
            We hope everything is working perfectly! We'd love to hear about your experience.
            
            Could you take a moment to leave us a review? Your feedback helps us improve and helps other customers find us.
            
            [Leave a Review]
            
            Thank you for your business!
            
            Best regards,
            The {company_name} Team
            """,
            targetSegment: "all",
            daysAfterEvent: 3
        )
        
        // Follow-up Template
        _ = createCampaign(
            name: "Post-Service Follow-up",
            type: "follow_up",
            subject: "Is everything working well?",
            body: """
            Hi {first_name},
            
            It's been a week since we completed your {device_type} repair. We wanted to check in and make sure everything is still working great!
            
            If you're experiencing any issues or have questions, please don't hesitate to reach out. We're here to help.
            
            [Contact Us]
            
            Best regards,
            The {company_name} Team
            """,
            targetSegment: "all",
            daysAfterEvent: 7
        )
        
        // Re-engagement Template
        _ = createCampaign(
            name: "Customer Re-engagement",
            type: "re_engagement",
            subject: "We miss you! Come back for a special offer",
            body: """
            Hi {first_name},
            
            It's been a while since we last saw you! We wanted to reach out and let you know we're here whenever you need us.
            
            As a valued customer, we'd like to offer you 10% off your next repair.
            
            Whether it's a quick fix or a major repair, we're ready to help.
            
            [Schedule Service]
            
            We look forward to seeing you soon!
            
            Best regards,
            The {company_name} Team
            """,
            targetSegment: "inactive",
            daysAfterEvent: 90
        )
    }
    
    func getDefaultTemplates() -> [CampaignTemplate] {
        return [
            CampaignTemplate(
                type: "review_request",
                name: "Review Request",
                subject: "How was your experience?",
                body: "Hi {first_name},\n\nThank you for your business! Please leave us a review."
            ),
            CampaignTemplate(
                type: "follow_up",
                name: "Follow-up",
                subject: "How's everything working?",
                body: "Hi {first_name},\n\nJust checking in to make sure everything is working well!"
            ),
            CampaignTemplate(
                type: "birthday",
                name: "Birthday Wishes",
                subject: "Happy Birthday from {company_name}!",
                body: "Hi {first_name},\n\nHappy Birthday! Here's a special gift for you."
            ),
            CampaignTemplate(
                type: "re_engagement",
                name: "We Miss You",
                subject: "Come back for a special offer!",
                body: "Hi {first_name},\n\nIt's been a while! Here's 10% off your next service."
            )
        ]
    }
}

// MARK: - Supporting Types

struct CampaignStats {
    let totalSent: Int
    let opened: Int
    let clicked: Int
    let unsubscribed: Int
    let openRate: Double
    let clickRate: Double
}

struct CampaignTemplate {
    let type: String
    let name: String
    let subject: String
    let body: String
}
