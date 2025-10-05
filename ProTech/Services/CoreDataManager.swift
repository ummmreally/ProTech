//
//  CoreDataManager.swift
//  TechStorePro
//
//  Core Data persistence controller
//

import CoreData
import Foundation

class CoreDataManager {
    static let shared = CoreDataManager()
    
    let container: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    private static let managedObjectModel: NSManagedObjectModel = {
        let model = NSManagedObjectModel()
        model.entities = [
            Customer.entityDescription(),
            FormTemplate.entityDescription(),
            FormSubmission.entityDescription(),
            SMSMessage.entityDescription(),
            Ticket.entityDescription(),
            TicketNote.entityDescription(),
            RepairProgress.entityDescription(),
            RepairStageRecord.entityDescription(),
            RepairPartUsage.entityDescription(),
            Invoice.entityDescription(),
            InvoiceLineItem.entityDescription(),
            Estimate.entityDescription(),
            EstimateLineItem.entityDescription(),
            Payment.entityDescription(),
            NotificationRule.entityDescription(),
            NotificationLog.entityDescription(),
            Appointment.entityDescription(),
            InventoryItem.entityDescription(),
            Supplier.entityDescription(),
            StockAdjustment.entityDescription(),
            PurchaseOrder.entityDescription(),
            PaymentMethod.entityDescription(),
            Campaign.entityDescription(),
            RecurringInvoice.entityDescription(),
            Transaction.entityDescription(),
            TimeEntry.entityDescription(),
            Employee.entityDescription(),
            TimeClockEntry.entityDescription(),
            // Square Integration entities
            SquareSyncMapping.entityDescription(),
            SyncLog.entityDescription(),
            SquareConfiguration.entityDescription(),
            // Loyalty Program entities
            LoyaltyProgram.entityDescription(),
            LoyaltyTier.entityDescription(),
            LoyaltyMember.entityDescription(),
            LoyaltyTransaction.entityDescription(),
            LoyaltyReward.entityDescription()
        ]

        if let invoiceEntity = model.entities.first(where: { $0.name == "Invoice" }),
           let lineItemEntity = model.entities.first(where: { $0.name == "InvoiceLineItem" }),
           let lineItemsRelationship = invoiceEntity.relationshipsByName["lineItems"],
           let invoiceRelationship = lineItemEntity.relationshipsByName["invoice"] {
            lineItemsRelationship.destinationEntity = lineItemEntity
            invoiceRelationship.destinationEntity = invoiceEntity
            lineItemsRelationship.inverseRelationship = invoiceRelationship
            invoiceRelationship.inverseRelationship = lineItemsRelationship
        }

        if let estimateEntity = model.entities.first(where: { $0.name == "Estimate" }),
           let estimateLineItemEntity = model.entities.first(where: { $0.name == "EstimateLineItem" }),
           let lineItemsRelationship = estimateEntity.relationshipsByName["lineItems"],
           let estimateRelationship = estimateLineItemEntity.relationshipsByName["estimate"] {
            lineItemsRelationship.destinationEntity = estimateLineItemEntity
            estimateRelationship.destinationEntity = estimateEntity
            lineItemsRelationship.inverseRelationship = estimateRelationship
            estimateRelationship.inverseRelationship = lineItemsRelationship
        }

        return model
    }()
    
    private init() {
        container = NSPersistentContainer(name: "ProTech", managedObjectModel: CoreDataManager.managedObjectModel)
        
        // Configure container
        let description = container.persistentStoreDescriptions.first
        description?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // MARK: - Save Context
    
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving context: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Background Context
    
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask(block)
    }
    
    // MARK: - Fetch Helpers
    
    func fetchCustomers(searchText: String = "", sortBy: CustomerSortOption = .lastNameAsc) -> [Customer] {
        let request: NSFetchRequest<Customer> = Customer.fetchRequest()
        
        // Search predicate
        if !searchText.isEmpty {
            let searchPredicate = NSPredicate(
                format: "firstName CONTAINS[cd] %@ OR lastName CONTAINS[cd] %@ OR email CONTAINS[cd] %@ OR phone CONTAINS[cd] %@",
                searchText, searchText, searchText, searchText
            )
            request.predicate = searchPredicate
        }
        
        // Sort descriptors
        request.sortDescriptors = sortBy.sortDescriptors
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching customers: \(error.localizedDescription)")
            return []
        }
    }
    
    func fetchCustomer(id: UUID) -> Customer? {
        let request: NSFetchRequest<Customer> = Customer.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        return try? viewContext.fetch(request).first
    }
    
    // MARK: - Delete Helpers
    
    func deleteCustomer(_ customer: Customer) {
        viewContext.delete(customer)
        save()
    }
    
    func deleteAllCustomers() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Customer.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try viewContext.execute(deleteRequest)
            save()
        } catch {
            print("Error deleting all customers: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Statistics
    
    func getCustomerCount() -> Int {
        let request: NSFetchRequest<Customer> = Customer.fetchRequest()
        return (try? viewContext.count(for: request)) ?? 0
    }
    
    func getCustomersAddedThisMonth() -> Int {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
        
        let request: NSFetchRequest<Customer> = Customer.fetchRequest()
        request.predicate = NSPredicate(format: "createdAt >= %@", startOfMonth as NSDate)
        
        return (try? viewContext.count(for: request)) ?? 0
    }
}

// MARK: - Sort Options

enum CustomerSortOption: String, CaseIterable {
    case lastNameAsc = "Last Name (A-Z)"
    case lastNameDesc = "Last Name (Z-A)"
    case firstNameAsc = "First Name (A-Z)"
    case dateAddedDesc = "Recently Added"
    case dateAddedAsc = "Oldest First"
    
    var sortDescriptors: [NSSortDescriptor] {
        switch self {
        case .lastNameAsc:
            return [NSSortDescriptor(keyPath: \Customer.lastName, ascending: true)]
        case .lastNameDesc:
            return [NSSortDescriptor(keyPath: \Customer.lastName, ascending: false)]
        case .firstNameAsc:
            return [NSSortDescriptor(keyPath: \Customer.firstName, ascending: true)]
        case .dateAddedDesc:
            return [NSSortDescriptor(keyPath: \Customer.createdAt, ascending: false)]
        case .dateAddedAsc:
            return [NSSortDescriptor(keyPath: \Customer.createdAt, ascending: true)]
        }
    }
}
