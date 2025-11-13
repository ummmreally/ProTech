//
//  UnifiedSyncManager.swift
//  ProTech
//
//  Orchestrates sync between CoreData, Supabase, and Square
//

import Foundation
import CoreData
import Supabase

@MainActor
class UnifiedSyncManager: ObservableObject {
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncStatus: String = "Ready"
    @Published var syncError: String?
    
    private let coreDataManager: CoreDataManager
    private let supabaseService: SupabaseService
    private let squareService: SquareProxyService
    
    init(coreDataManager: CoreDataManager, supabaseService: SupabaseService) {
        self.coreDataManager = coreDataManager
        self.supabaseService = supabaseService
        self.squareService = SquareProxyService(supabase: supabaseService.client)
    }
    
    // MARK: - Full Sync
    
    func performFullSync() async throws {
        guard !isSyncing else { return }
        
        isSyncing = true
        syncError = nil
        defer { isSyncing = false }
        
        do {
            syncStatus = "Syncing customers..."
            try await syncCustomers()
            
            syncStatus = "Syncing inventory..."
            try await syncInventory()
            
            syncStatus = "Syncing orders..."
            try await syncOrders()
            
            lastSyncDate = Date()
            syncStatus = "Sync complete"
        } catch {
            syncError = error.localizedDescription
            syncStatus = "Sync failed"
            throw error
        }
    }
    
    // MARK: - Customer Sync
    
    func syncCustomers() async throws {
        // 1. Fetch from all sources
        let squareCustomers = try await squareService.listCustomers().customers
        let supabaseCustomers = try await fetchSupabaseCustomers()
        _ = coreDataManager.fetchCustomers()
        
        // 2. Create lookup maps
        var squareMap: [String: SquareCustomer] = [:]
        for customer in squareCustomers {
            if let email = customer.emailAddress {
                squareMap[email] = customer
            }
        }
        
        var supabaseMap: [String: [String: Any]] = [:]
        for customer in supabaseCustomers {
            if let email = customer["email"] as? String {
                supabaseMap[email] = customer
            }
        }
        
        // 3. Sync Square → Supabase → CoreData
        for squareCustomer in squareCustomers {
            guard let email = squareCustomer.emailAddress else { continue }
            
            // Check if exists in Supabase
            if let supabaseCustomer = supabaseMap[email] {
                // Update if needed
                try await updateSupabaseCustomer(
                    id: supabaseCustomer["id"] as? String ?? "",
                    squareCustomer: squareCustomer
                )
            } else {
                // Create in Supabase
                try await createSupabaseCustomer(from: squareCustomer)
            }
            
            // Sync to CoreData
            syncCustomerToCoreData(squareCustomer: squareCustomer)
        }
        
        coreDataManager.save()
    }
    
    private func syncCustomerToCoreData(squareCustomer: SquareCustomer) {
        let fetchRequest: NSFetchRequest<Customer> = Customer.fetchRequest()
        if let email = squareCustomer.emailAddress {
            fetchRequest.predicate = NSPredicate(format: "email == %@", email)
        } else {
            return
        }
        
        let context = coreDataManager.viewContext
        
        do {
            let existing = try context.fetch(fetchRequest).first
            let customer = existing ?? Customer(context: context)
            
            customer.firstName = squareCustomer.givenName ?? ""
            customer.lastName = squareCustomer.familyName ?? ""
            customer.email = squareCustomer.emailAddress
            customer.phone = squareCustomer.phoneNumber
            customer.squareCustomerId = squareCustomer.id
            
            if customer.id == nil {
                customer.id = UUID()
            }
        } catch {
            print("Error syncing customer to CoreData: \(error)")
        }
    }
    
    // MARK: - Inventory Sync
    
    func syncInventory() async throws {
        // 1. Fetch Square catalog and inventory
        let squareItems = try await squareService.listCatalogItems()
        let squareInventory = try await squareService.listInventory()
        
        // Create inventory lookup
        var inventoryMap: [String: Int] = [:]
        for count in squareInventory {
            if let quantity = Int(count.quantity) {
                inventoryMap[count.catalogObjectId] = quantity
            }
        }
        
        // 2. Fetch Supabase items
        let supabaseItems = try await fetchSupabaseInventory()
        var supabaseMap: [String: [String: Any]] = [:]
        for item in supabaseItems {
            if let sku = item["sku"] as? String {
                supabaseMap[sku] = item
            }
        }
        
        // 3. Sync Square → Supabase → CoreData
        for squareItem in squareItems {
            guard let sku = squareItem.sku else { continue }
            
            let quantity = inventoryMap[squareItem.id] ?? 0
            
            // Check if exists in Supabase
            if let supabaseItem = supabaseMap[sku] {
                // Update
                try await updateSupabaseInventory(
                    id: supabaseItem["id"] as? String ?? "",
                    squareItem: squareItem,
                    quantity: quantity
                )
            } else {
                // Create
                try await createSupabaseInventory(from: squareItem, quantity: quantity)
            }
            
            // Sync to CoreData
            syncInventoryToCoreData(squareItem: squareItem, quantity: quantity)
        }
        
        coreDataManager.save()
    }
    
    private func syncInventoryToCoreData(squareItem: SquareCatalogItem, quantity: Int) {
        let fetchRequest: NSFetchRequest<InventoryItem> = InventoryItem.fetchRequest()
        if let sku = squareItem.sku {
            fetchRequest.predicate = NSPredicate(format: "sku == %@", sku)
        } else {
            return
        }
        
        let context = coreDataManager.viewContext
        
        do {
            let existing = try context.fetch(fetchRequest).first
            let item = existing ?? InventoryItem(context: context)
            
            item.name = squareItem.name
            item.sku = squareItem.sku
            item.quantity = Int32(quantity)
            // Note: squareItemId property not defined in InventoryItem model
            // Consider adding: @NSManaged public var squareItemId: String?
            
            if let price = squareItem.price {
                item.sellingPrice = Double(price) / 100.0
            }
            
            if item.id == nil {
                item.id = UUID()
            }
        } catch {
            print("Error syncing inventory to CoreData: \(error)")
        }
    }
    
    // MARK: - Order Sync
    
    func syncOrders() async throws {
        // Get orders from last 30 days
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())
        let orders = try await squareService.searchOrders(startDate: startDate, endDate: Date())
        
        // Sync each order to Supabase
        for order in orders {
            try await syncOrderToSupabase(order: order)
        }
    }
    
    private func syncOrderToSupabase(order: SquareOrder) async throws {
        // Check if order already exists
        let existing = try await supabaseService.client
            .from("orders")
            .select()
            .eq("square_order_id", value: order.id)
            .execute()
        
        if existing.data.isEmpty {
            // Create new order record
            struct OrderInsert: Encodable {
                let square_order_id: String
                let total_amount: Int
                let created_at: String
                let status: String
            }
            
            try await supabaseService.client
                .from("orders")
                .insert(OrderInsert(
                    square_order_id: order.id,
                    total_amount: order.totalMoney ?? 0,
                    created_at: order.createdAt,
                    status: "completed"
                ))
                .execute()
        }
    }
    
    // MARK: - Push to Square
    
    func pushCustomerToSquare(customer: Customer) async throws -> String {
        let squareCustomer = try await squareService.createCustomer(
            firstName: customer.firstName ?? "",
            lastName: customer.lastName ?? "",
            email: customer.email,
            phone: customer.phone
        )
        
        // Update CoreData with Square ID
        customer.squareCustomerId = squareCustomer.id
        coreDataManager.save()
        
        // Update Supabase
        if let email = customer.email {
            struct CustomerUpdate: Encodable {
                let square_customer_id: String
            }
            try await supabaseService.client
                .from("customers")
                .update(CustomerUpdate(square_customer_id: squareCustomer.id))
                .eq("email", value: email)
                .execute()
        }
        
        return squareCustomer.id
    }
    
    func pushInventoryToSquare(item: InventoryItem) async throws -> String {
        guard let name = item.name, let sku = item.sku else {
            throw SyncError.missingData
        }
        
        let priceInCents = Int(item.sellingPrice * 100)
        
        let squareItem = try await squareService.createCatalogItem(
            name: name,
            price: priceInCents,
            sku: sku
        )
        
        // Adjust inventory
        if item.quantity > 0 {
            try await squareService.adjustInventory(
                catalogObjectId: squareItem.id,
                quantity: Int(item.quantity)
            )
        }
        
        // Update CoreData
        // Note: squareItemId property not defined in InventoryItem model
        // item.squareItemId = squareItem.id
        coreDataManager.save()
        
        // Update Supabase
        struct InventoryUpdate: Encodable {
            let square_item_id: String
        }
        try await supabaseService.client
            .from("inventory")
            .update(InventoryUpdate(square_item_id: squareItem.id))
            .eq("sku", value: sku)
            .execute()
        
        return squareItem.id
    }
    
    // MARK: - Supabase Helpers
    
    private func fetchSupabaseCustomers() async throws -> [[String: Any]] {
        let response = try await supabaseService.client
            .from("customers")
            .select()
            .execute()
        
        if let data = try? JSONSerialization.jsonObject(with: response.data) as? [[String: Any]] {
            return data
        }
        return []
    }
    
    private func fetchSupabaseInventory() async throws -> [[String: Any]] {
        let response = try await supabaseService.client
            .from("inventory")
            .select()
            .execute()
        
        if let data = try? JSONSerialization.jsonObject(with: response.data) as? [[String: Any]] {
            return data
        }
        return []
    }
    
    private func createSupabaseCustomer(from squareCustomer: SquareCustomer) async throws {
        struct CustomerInsert: Encodable {
            let first_name: String
            let last_name: String
            let email: String
            let phone: String
            let square_customer_id: String
        }
        
        try await supabaseService.client
            .from("customers")
            .insert(CustomerInsert(
                first_name: squareCustomer.givenName ?? "",
                last_name: squareCustomer.familyName ?? "",
                email: squareCustomer.emailAddress ?? "",
                phone: squareCustomer.phoneNumber ?? "",
                square_customer_id: squareCustomer.id
            ))
            .execute()
    }
    
    private func updateSupabaseCustomer(id: String, squareCustomer: SquareCustomer) async throws {
        struct CustomerUpdateFull: Encodable {
            let first_name: String
            let last_name: String
            let phone: String
            let square_customer_id: String
        }
        
        try await supabaseService.client
            .from("customers")
            .update(CustomerUpdateFull(
                first_name: squareCustomer.givenName ?? "",
                last_name: squareCustomer.familyName ?? "",
                phone: squareCustomer.phoneNumber ?? "",
                square_customer_id: squareCustomer.id
            ))
            .eq("id", value: id)
            .execute()
    }
    
    private func createSupabaseInventory(from squareItem: SquareCatalogItem, quantity: Int) async throws {
        struct InventoryInsert: Encodable {
            let name: String
            let sku: String
            let price: Double
            let quantity: Int
            let square_item_id: String
        }
        
        try await supabaseService.client
            .from("inventory")
            .insert(InventoryInsert(
                name: squareItem.name,
                sku: squareItem.sku ?? "",
                price: Double(squareItem.price ?? 0) / 100.0,
                quantity: quantity,
                square_item_id: squareItem.id
            ))
            .execute()
    }
    
    private func updateSupabaseInventory(id: String, squareItem: SquareCatalogItem, quantity: Int) async throws {
        struct InventoryUpdateFull: Encodable {
            let name: String
            let price: Double
            let quantity: Int
            let square_item_id: String
        }
        
        try await supabaseService.client
            .from("inventory")
            .update(InventoryUpdateFull(
                name: squareItem.name,
                price: Double(squareItem.price ?? 0) / 100.0,
                quantity: quantity,
                square_item_id: squareItem.id
            ))
            .eq("id", value: id)
            .execute()
    }
}

// MARK: - Errors

// SyncError is defined in Models/SyncErrors.swift
