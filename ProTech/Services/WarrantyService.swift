//
//  WarrantyService.swift
//  ProTech
//
//  Manages warranty lifecycle, status checks, and expirations.
//

import Foundation
import CoreData

class WarrantyService {
    static let shared = WarrantyService()
    private let coreDataManager = CoreDataManager.shared
    
    private init() {}
    
    // MARK: - Warranty Status
    
    enum WarrantyStatus {
        case active(daysRemaining: Int)
        case expired(expiredOn: Date)
        case none
    }
    
    /// Calculate current warranty status for a ticket
    func getWarrantyStatus(for ticket: Ticket) -> WarrantyStatus {
        guard let expirationDate = ticket.warrantyExpirationDate else {
            return .none
        }
        
        let now = Date()
        
        if expirationDate < now {
            return .expired(expiredOn: expirationDate)
        } else {
            let daysRemaining = Calendar.current.dateComponents([.day], from: now, to: expirationDate).day ?? 0
            return .active(daysRemaining: max(0, daysRemaining))
        }
    }
    
    /// Set warranty for a ticket upon completion
    func activateWarranty(for ticket: Ticket, durationDays: Int16) {
        guard ticket.status == "completed" || ticket.status == "picked_up" else { return }
        
        let context = coreDataManager.viewContext
        
        context.performAndWait {
            ticket.warrantyDurationDays = durationDays
            
            if durationDays > 0 {
                let expirationDate = Calendar.current.date(byAdding: .day, value: Int(durationDays), to: Date())
                ticket.warrantyExpirationDate = expirationDate
            } else {
                ticket.warrantyExpirationDate = nil
            }
            
            try? context.save()
        }
    }
    
    // MARK: - Reporting
    
    /// Find tickets with warranties expiring soon (e.g., next 7 days)
    func getExpiringWarranties(daysThreshold: Int = 7) -> [Ticket] {
        let request: NSFetchRequest<Ticket> = Ticket.fetchRequest()
        
        let now = Date()
        guard let thresholdDate = Calendar.current.date(byAdding: .day, value: daysThreshold, to: now) else { return [] }
        
        // Predicate: Expiration date is between NOW and THRESHOLD
        request.predicate = NSPredicate(format: "warrantyExpirationDate >= %@ AND warrantyExpirationDate <= %@", now as CVarArg, thresholdDate as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Ticket.warrantyExpirationDate, ascending: true)]
        
        do {
            return try coreDataManager.viewContext.fetch(request)
        } catch {
            print("Error fetching expiring warranties: \(error)")
            return []
        }
    }
}
