//
//  AutomationService.swift
//  ProTech
//
//  Handles automated background tasks for marketing and engagement.
//

import Foundation
import CoreData
import SwiftUI

class AutomationService: ObservableObject {
    static let shared = AutomationService()
    
    private let viewContext = CoreDataManager.shared.viewContext
    
    private init() {}
    
    // MARK: - Public API
    
    /// Run all daily automation checks
    func runDailyChecks() async {
        print("🤖 Running Automation Service checks...")
        
        await checkBirthdays()
        await checkReviewRequests()
        
        // Mark last run time user defaults or similar if needed to avoid spam
        UserDefaults.standard.set(Date(), forKey: "lastAutomationRun")
    }
    
    // MARK: - Triggers
    
    private func checkBirthdays() async {
        let today = Date()
        let calendar = Calendar.current
        let day = calendar.component(.day, from: today)
        let month = calendar.component(.month, from: today)
        
        // 1. Find customers with birthday today
        // Note: Core Data predicate for day/month on Date is tricky, usually fetching all with birthdays and filtering in memory is acceptable for small-medium datasets
        // For larger datasets, we would store day/month automatically in separate integer fields.
        let request: NSFetchRequest<Customer> = Customer.fetchRequest()
        request.predicate = NSPredicate(format: "birthday != nil AND marketingOptInSMS == true")
        
        do {
            let customers = try viewContext.fetch(request)
            let birthdayCustomers = customers.filter { customer in
                guard let bday = customer.birthday else { return false }
                let bComponent = calendar.dateComponents([.day, .month], from: bday)
                return bComponent.day == day && bComponent.month == month
            }
            
            for customer in birthdayCustomers {
                print("🎂 Found birthday: \(customer.displayName)")
                // Trigger Birthday Campaign
                // In a real app, we would look up the active "Birthday" campaign template and send it.
                // For now, we simulate the action or create a notification log.
                createNotificationLog(
                    type: "Birthday",
                    message: "Happy Birthday, \(customer.firstName ?? "Valued Customer")! Come in for a free diagnostic.",
                    customer: customer
                )
            }
            
        } catch {
            print("Error checking birthdays: \(error)")
        }
    }
    
    private func checkReviewRequests() async {
        // Find tickets completed 2 days ago
        let calendar = Calendar.current
        guard let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: Date()) else { return }
        let startOfDay = calendar.startOfDay(for: twoDaysAgo)
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: twoDaysAgo)!
        
        let request: NSFetchRequest<Ticket> = Ticket.fetchRequest()
        request.predicate = NSPredicate(
            format: "status == 'picked_up' AND updatedAt >= %@ AND updatedAt <= %@",
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        
        do {
            let tickets = try viewContext.fetch(request)
            for ticket in tickets {
                if let customerId = ticket.customerId,
                   let customer = CoreDataManager.shared.fetchCustomer(id: customerId),
                   customer.marketingOptInSMS {
                    
                    print("⭐ Found review candidate: \(customer.displayName)")
                    createNotificationLog(
                        type: "Review Request",
                        message: "Hi \(customer.firstName ?? "there"), how is your repair holding up? We'd love a review!",
                        customer: customer
                    )
                }
            }
        } catch {
            print("Error checking review requests: \(error)")
        }
    }
    
    private func createNotificationLog(type: String, message: String, customer: Customer) {
        // Log this action so we can see it in campaigns/history
        // Logic to actually send SMS would go here (TwilioService.shared.send...)
        
        // For MVP, just print to console to verify logic
        print(">>> SENDING \(type) to \(customer.displayName): \(message)")
    }
}
