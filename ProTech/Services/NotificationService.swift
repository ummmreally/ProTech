import Foundation
import CoreData
import AppKit

class NotificationService {
    static let shared = NotificationService()
    
    private let coreDataManager = CoreDataManager.shared
    private let twilioService = TwilioService.shared
    private var context: NSManagedObjectContext {
        coreDataManager.viewContext
    }
    
    private init() {}
    
    // MARK: - Notification Rules
    
    /// Create a notification rule
    func createRule(
        name: String,
        triggerEvent: String,
        statusTrigger: String?,
        notificationType: String,
        emailSubject: String?,
        emailBody: String?,
        smsBody: String?,
        delayMinutes: Int16 = 0
    ) -> NotificationRule {
        let rule = NotificationRule(context: context)
        rule.id = UUID()
        rule.name = name
        rule.triggerEvent = triggerEvent
        rule.statusTrigger = statusTrigger
        rule.notificationType = notificationType
        rule.isEnabled = true
        rule.emailSubject = emailSubject
        rule.emailBody = emailBody
        rule.smsBody = smsBody
        rule.delayMinutes = delayMinutes
        rule.createdAt = Date()
        rule.updatedAt = Date()
        
        coreDataManager.save()
        return rule
    }
    
    /// Update a notification rule
    func updateRule(
        _ rule: NotificationRule,
        name: String? = nil,
        notificationType: String? = nil,
        emailSubject: String? = nil,
        emailBody: String? = nil,
        smsBody: String? = nil,
        isEnabled: Bool? = nil
    ) {
        if let name = name {
            rule.name = name
        }
        if let notificationType = notificationType {
            rule.notificationType = notificationType
        }
        if let emailSubject = emailSubject {
            rule.emailSubject = emailSubject
        }
        if let emailBody = emailBody {
            rule.emailBody = emailBody
        }
        if let smsBody = smsBody {
            rule.smsBody = smsBody
        }
        if let isEnabled = isEnabled {
            rule.isEnabled = isEnabled
        }
        
        rule.updatedAt = Date()
        coreDataManager.save()
    }
    
    /// Delete a notification rule
    func deleteRule(_ rule: NotificationRule) {
        context.delete(rule)
        coreDataManager.save()
    }
    
    /// Fetch all notification rules
    func fetchRules() -> [NotificationRule] {
        let request: NSFetchRequest<NotificationRule> = NotificationRule.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \NotificationRule.name, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching notification rules: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Fetch enabled rules for a specific trigger
    func fetchEnabledRules(for statusTrigger: String) -> [NotificationRule] {
        let request: NSFetchRequest<NotificationRule> = NotificationRule.fetchRequest()
        request.predicate = NSPredicate(
            format: "isEnabled == YES AND triggerEvent == %@ AND statusTrigger == %@",
            "status_change", statusTrigger
        )
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching enabled rules: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Notification Sending
    
    /// Trigger notifications for a ticket status change
    func triggerNotifications(for ticket: Ticket, newStatus: String) {
        guard let customerId = ticket.customerId,
              let customer = coreDataManager.fetchCustomer(id: customerId) else {
            return
        }
        
        let rules = fetchEnabledRules(for: newStatus)
        
        for rule in rules {
            if rule.isEmailEnabled, let email = customer.email, !email.isEmpty {
                sendEmailNotification(
                    rule: rule,
                    ticket: ticket,
                    customer: customer,
                    recipient: email
                )
            }
            
            if rule.isSMSEnabled, let phone = customer.phone, !phone.isEmpty {
                sendSMSNotification(
                    rule: rule,
                    ticket: ticket,
                    customer: customer,
                    recipient: phone
                )
            }
        }
    }
    
    /// Send email notification
    private func sendEmailNotification(
        rule: NotificationRule,
        ticket: Ticket,
        customer: Customer,
        recipient: String
    ) {
        let subject = replacePlaceholders(
            rule.emailSubject ?? "Repair Status Update",
            ticket: ticket,
            customer: customer
        )
        
        let body = replacePlaceholders(
            rule.emailBody ?? "",
            ticket: ticket,
            customer: customer
        )
        
        // Log the notification
        let log = createNotificationLog(
            ruleId: rule.id,
            ticketId: ticket.id,
            customerId: customer.id,
            notificationType: "email",
            recipient: recipient,
            subject: subject,
            body: body
        )
        
        // Send email via mailto (or integrate with email service)
        sendEmail(to: recipient, subject: subject, body: body, log: log)
    }
    
    /// Send SMS notification
    private func sendSMSNotification(
        rule: NotificationRule,
        ticket: Ticket,
        customer: Customer,
        recipient: String
    ) {
        let body = replacePlaceholders(
            rule.smsBody ?? "",
            ticket: ticket,
            customer: customer
        )
        
        // Log the notification
        let log = createNotificationLog(
            ruleId: rule.id,
            ticketId: ticket.id,
            customerId: customer.id,
            notificationType: "sms",
            recipient: recipient,
            subject: nil,
            body: body
        )
        
        // Send SMS via Twilio
        sendSMS(to: recipient, body: body, log: log)
    }
    
    /// Send email (opens mail client)
    private func sendEmail(to recipient: String, subject: String, body: String, log: NotificationLog) {
        let mailtoString = "mailto:\(recipient)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        if let url = URL(string: mailtoString) {
            NSWorkspace.shared.open(url)
            
            // Mark as sent (in real implementation, this would be after confirmation)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.markNotificationSent(log)
            }
        } else {
            markNotificationFailed(log, reason: "Invalid email URL")
        }
    }
    
    /// Send SMS via Twilio
    private func sendSMS(to recipient: String, body: String, log: NotificationLog) {
        Task {
            do {
                _ = try await twilioService.sendSMS(to: recipient, body: body)
                await MainActor.run {
                    self.markNotificationSent(log)
                }
            } catch {
                let reason: String
                if let twilioError = error as? TwilioError {
                    reason = twilioError.errorDescription ?? "Unknown error"
                } else {
                    reason = error.localizedDescription
                }
                await MainActor.run {
                    self.markNotificationFailed(log, reason: reason)
                }
            }
        }
    }
    
    /// Send manual notification
    func sendManualNotification(
        to customer: Customer,
        ticket: Ticket?,
        subject: String,
        body: String,
        notificationType: String
    ) {
        if notificationType == "email" || notificationType == "both" {
            if let email = customer.email, !email.isEmpty {
                let log = createNotificationLog(
                    ruleId: nil,
                    ticketId: ticket?.id,
                    customerId: customer.id,
                    notificationType: "email",
                    recipient: email,
                    subject: subject,
                    body: body
                )
                sendEmail(to: email, subject: subject, body: body, log: log)
            }
        }
        
        if notificationType == "sms" || notificationType == "both" {
            if let phone = customer.phone, !phone.isEmpty {
                let log = createNotificationLog(
                    ruleId: nil,
                    ticketId: ticket?.id,
                    customerId: customer.id,
                    notificationType: "sms",
                    recipient: phone,
                    subject: nil,
                    body: body
                )
                sendSMS(to: phone, body: body, log: log)
            }
        }
    }
    
    // MARK: - Notification Logging
    
    /// Create notification log entry
    private func createNotificationLog(
        ruleId: UUID?,
        ticketId: UUID?,
        customerId: UUID?,
        notificationType: String,
        recipient: String,
        subject: String?,
        body: String
    ) -> NotificationLog {
        let log = NotificationLog(context: context)
        log.id = UUID()
        log.ruleId = ruleId
        log.ticketId = ticketId
        log.customerId = customerId
        log.notificationType = notificationType
        log.recipient = recipient
        log.subject = subject
        log.body = body
        log.status = "pending"
        log.createdAt = Date()
        
        coreDataManager.save()
        return log
    }
    
    /// Mark notification as sent
    private func markNotificationSent(_ log: NotificationLog) {
        log.status = "sent"
        log.sentAt = Date()
        coreDataManager.save()
    }
    
    /// Mark notification as failed
    private func markNotificationFailed(_ log: NotificationLog, reason: String) {
        log.status = "failed"
        log.failureReason = reason
        coreDataManager.save()
    }
    
    /// Fetch notification logs
    func fetchNotificationLogs(for ticketId: UUID? = nil) -> [NotificationLog] {
        let request: NSFetchRequest<NotificationLog> = NotificationLog.fetchRequest()
        
        if let ticketId = ticketId {
            request.predicate = NSPredicate(format: "ticketId == %@", ticketId as CVarArg)
        }
        
        request.sortDescriptors = [NSSortDescriptor(keyPath: \NotificationLog.createdAt, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching notification logs: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Fetch recent notification logs
    func fetchRecentLogs(limit: Int = 50) -> [NotificationLog] {
        let request: NSFetchRequest<NotificationLog> = NotificationLog.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \NotificationLog.createdAt, ascending: false)]
        request.fetchLimit = limit
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching recent logs: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Template Placeholders
    
    /// Replace placeholders in notification templates
    private func replacePlaceholders(_ template: String, ticket: Ticket, customer: Customer) -> String {
        var result = template
        
        // Customer placeholders
        result = result.replacingOccurrences(of: "{customer_name}", with: "\(customer.firstName ?? "") \(customer.lastName ?? "")".trimmingCharacters(in: .whitespaces))
        result = result.replacingOccurrences(of: "{customer_first_name}", with: customer.firstName ?? "")
        result = result.replacingOccurrences(of: "{customer_email}", with: customer.email ?? "")
        result = result.replacingOccurrences(of: "{customer_phone}", with: customer.phone ?? "")
        
        // Ticket placeholders
        result = result.replacingOccurrences(of: "{ticket_number}", with: String(ticket.ticketNumber))
        result = result.replacingOccurrences(of: "{device_type}", with: ticket.deviceType ?? "")
        result = result.replacingOccurrences(of: "{device_model}", with: ticket.deviceModel ?? "")
        result = result.replacingOccurrences(of: "{issue_description}", with: ticket.issueDescription ?? "")
        result = result.replacingOccurrences(of: "{status}", with: ticket.status ?? "")
        
        // Date placeholders
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        if let estimatedCompletion = ticket.estimatedCompletion {
            result = result.replacingOccurrences(of: "{estimated_completion}", with: dateFormatter.string(from: estimatedCompletion))
        }
        
        return result
    }
    
    // MARK: - Default Templates
    
    /// Get default notification templates
    func getDefaultTemplates() -> [String: (subject: String, emailBody: String, smsBody: String)] {
        return [
            "checked_in": (
                subject: "Repair Check-in Confirmation - Ticket #{ticket_number}",
                emailBody: """
                Hi {customer_first_name},
                
                Thank you for choosing ProTech! We've received your {device_type} ({device_model}) for repair.
                
                Ticket Number: #{ticket_number}
                Issue: {issue_description}
                
                We'll keep you updated on the progress of your repair.
                
                Best regards,
                ProTech Team
                """,
                smsBody: "ProTech: Your {device_type} repair has been checked in. Ticket #{ticket_number}. We'll keep you updated!"
            ),
            "in_progress": (
                subject: "Repair In Progress - Ticket #{ticket_number}",
                emailBody: """
                Hi {customer_first_name},
                
                Good news! Our technician has started working on your {device_type} ({device_model}).
                
                Ticket Number: #{ticket_number}
                Status: In Progress
                
                We'll notify you once the repair is complete.
                
                Best regards,
                ProTech Team
                """,
                smsBody: "ProTech: Your {device_type} repair is now in progress. Ticket #{ticket_number}"
            ),
            "completed": (
                subject: "Repair Completed - Ticket #{ticket_number}",
                emailBody: """
                Hi {customer_first_name},
                
                Great news! Your {device_type} ({device_model}) repair has been completed successfully!
                
                Ticket Number: #{ticket_number}
                Status: Completed
                
                Your device is ready for pickup at your convenience.
                
                Best regards,
                ProTech Team
                """,
                smsBody: "ProTech: Your {device_type} repair is complete! Ticket #{ticket_number}. Ready for pickup."
            ),
            "ready_for_pickup": (
                subject: "Device Ready for Pickup - Ticket #{ticket_number}",
                emailBody: """
                Hi {customer_first_name},
                
                Your {device_type} ({device_model}) is ready for pickup!
                
                Ticket Number: #{ticket_number}
                
                Please visit us during business hours to collect your device.
                
                Best regards,
                ProTech Team
                """,
                smsBody: "ProTech: Your {device_type} is ready for pickup! Ticket #{ticket_number}"
            ),
            "picked_up": (
                subject: "Thank You - Ticket #{ticket_number}",
                emailBody: """
                Hi {customer_first_name},
                
                Thank you for choosing ProTech for your {device_type} repair!
                
                We hope you're satisfied with our service. If you have any questions or concerns, please don't hesitate to contact us.
                
                We appreciate your business!
                
                Best regards,
                ProTech Team
                """,
                smsBody: "ProTech: Thank you for your business! We hope to serve you again soon."
            )
        ]
    }
    
    /// Initialize default notification rules
    func initializeDefaultRules() {
        let existingRules = fetchRules()
        if !existingRules.isEmpty {
            return // Already initialized
        }
        
        let templates = getDefaultTemplates()
        
        for (status, template) in templates {
            _ = createRule(
                name: "\(status.capitalized.replacingOccurrences(of: "_", with: " ")) Notification",
                triggerEvent: "status_change",
                statusTrigger: status,
                notificationType: "email",
                emailSubject: template.subject,
                emailBody: template.emailBody,
                smsBody: template.smsBody
            )
        }
    }
    
    // MARK: - Statistics
    
    /// Get notification statistics
    func getNotificationStats() -> (sent: Int, failed: Int, pending: Int) {
        let logs = fetchRecentLogs(limit: 1000)
        
        let sent = logs.filter { $0.status == "sent" }.count
        let failed = logs.filter { $0.status == "failed" }.count
        let pending = logs.filter { $0.status == "pending" }.count
        
        return (sent, failed, pending)
    }
}
