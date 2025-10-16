//
//  CoreDataManager.swift
//  TechStorePro
//
//  Core Data persistence controller
//

import CoreData
import Foundation
import CloudKit

class CoreDataManager {
    static let shared = CoreDataManager()
    
    // Toggle this to enable/disable CloudKit sync
    private let useCloudKit = false // ⚠️ DISABLED - Enable after configuring CloudKit in Apple Developer
    
    let container: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    // Note: Using .xcdatamodeld file instead of programmatic model
    // The programmatic model code below is kept for reference but not used
    /*
    private static let managedObjectModel: NSManagedObjectModel = {
        let model = NSManagedObjectModel()
        model.entities = [
            Customer.entityDescription(),
            Ticket.entityDescription(),
            Employee.entityDescription(),
            // ... other entities
        ]
        return model
    }()
    */
    
    private init() {
        // Create appropriate container type based on CloudKit setting
        // Use the .xcdatamodeld file instead of programmatic model
        if useCloudKit {
            print("🔄 Initializing with CloudKit sync enabled")
            container = NSPersistentCloudKitContainer(name: "ProTech")
        } else {
            print("💾 Initializing with local storage only (CloudKit disabled)")
            container = NSPersistentContainer(name: "ProTech")
        }
        
        // Configure container
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve persistent store description")
        }
        
        // Enable automatic migrations
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        
        // Configure for CloudKit if enabled
        if useCloudKit {
            // Enable persistent history tracking (required for CloudKit)
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            
            // Enable remote change notifications
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            
            // Configure CloudKit container options
            let cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.nugentic.protech")
            description.cloudKitContainerOptions = cloudKitContainerOptions
        }
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                print("❌ Core Data Error: \(error)")
                print("📋 Error Details: \(error)")
                print("📁 Store URL: \(storeDescription.url?.path ?? "unknown")")
                
                // Check for specific error types
                let nsError = error as NSError
                print("⚠️ Error Domain: \(nsError.domain)")
                print("⚠️ Error Code: \(nsError.code)")
                print("⚠️ Error UserInfo: \(nsError.userInfo)")
                
                // Always try to reset the store on any error during development
                print("\n🔄 Attempting to reset Core Data store...")
                
                if let storeURL = storeDescription.url {
                    self.resetCoreDataStore(at: storeURL)
                    print("✅ Store reset complete")
                    print("⚠️  PLEASE RESTART THE APP - The database has been reset")
                    print("   Press Stop and Run again in Xcode")
                    fatalError("Core Data store was reset - Please restart the app")
                }
                
                if self.useCloudKit {
                    print("\n🔧 CloudKit Troubleshooting:")
                    print("   1. Sign into iCloud on this Mac (System Settings > Apple ID)")
                    print("   2. Verify bundle ID matches CloudKit container")
                    print("   3. Create CloudKit container at developer.apple.com")
                    print("   4. Container ID: iCloud.com.nugentic.protech")
                    print("   5. Enable iCloud + CloudKit capabilities in Xcode")
                    print("   6. Try running on a physical device if using simulator")
                }
                
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
            
            if self.useCloudKit {
                print("✅ Core Data with CloudKit loaded successfully")
            } else {
                print("✅ Core Data (local only) loaded successfully")
            }
            print("📁 Store URL: \(storeDescription.url?.path ?? "unknown")")
        }
        
        // Automatically merge changes from parent context
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Watch for remote changes if CloudKit is enabled
        if useCloudKit {
            setupCloudKitNotifications()
        }
    }
    
    // MARK: - Reset Store
    
    private func resetCoreDataStore(at storeURL: URL) {
        print("🗑️ Resetting Core Data store at: \(storeURL.path)")
        
        let fileManager = FileManager.default
        
        // Delete main store file
        try? fileManager.removeItem(at: storeURL)
        print("   ✓ Deleted main store file")
        
        // Delete write-ahead log
        let walURL = storeURL.deletingPathExtension().appendingPathExtension("sqlite-wal")
        try? fileManager.removeItem(at: walURL)
        print("   ✓ Deleted WAL file")
        
        // Delete shared memory file
        let shmURL = storeURL.deletingPathExtension().appendingPathExtension("sqlite-shm")
        try? fileManager.removeItem(at: shmURL)
        print("   ✓ Deleted SHM file")
        
        print("✅ Core Data store reset complete")
    }
    
    // MARK: - CloudKit Notifications
    
    private func setupCloudKitNotifications() {
        NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: container,
            queue: .main
        ) { notification in
            if let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey] as? NSPersistentCloudKitContainer.Event {
                print("CloudKit sync event: \(event.type) - \(event.endDate?.description ?? "in progress")")
                
                // Handle sync errors
                if event.error != nil {
                    print("CloudKit sync error: \(event.error!.localizedDescription)")
                }
            }
        }
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
