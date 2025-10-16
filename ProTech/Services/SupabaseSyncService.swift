//
//  SupabaseSyncService.swift
//  ProTech
//
//  Syncs Core Data with Supabase backend
//

import Foundation
import CoreData
import Supabase

@MainActor
class SupabaseSyncService: ObservableObject {
    static let shared = SupabaseSyncService()
    
    private let supabase = SupabaseService.shared
    private let coreData = CoreDataManager.shared
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    
    private var syncTimer: Timer?
    
    private init() {
        // Start automatic sync if enabled
        if SyncConfig.autoSyncEnabled {
            startAutomaticSync()
        }
    }
    
    // MARK: - Auto Sync
    
    func startAutomaticSync() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: SyncConfig.syncInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.performFullSync()
            }
        }
    }
    
    func stopAutomaticSync() {
        syncTimer?.invalidate()
        syncTimer = nil
    }
    
    // MARK: - Full Sync
    
    func performFullSync() async {
        guard !isSyncing else { return }
        
        isSyncing = true
        syncError = nil
        
        do {
            // Sync customers
            try await syncCustomers()
            
            // Sync repair tickets
            try await syncRepairTickets()
            
            // Sync employees
            try await syncEmployees()
            
            lastSyncDate = Date()
            print("✅ Full sync completed successfully")
            
        } catch {
            syncError = error.localizedDescription
            print("❌ Sync error: \(error)")
        }
        
        isSyncing = false
    }
    
    // MARK: - Customer Sync
    
    func syncCustomers() async throws {
        print("🔄 Syncing customers...")
        
        // Fetch from Supabase
        let supabaseCustomers: [SupabaseCustomer] = try await supabase.client
            .from("customers")
            .select()
            .execute()
            .value
        
        // Fetch from Core Data
        let localCustomers = coreData.fetchCustomers()
        
        // Create maps for efficient lookup
        var supabaseMap: [UUID: SupabaseCustomer] = [:]
        for customer in supabaseCustomers {
            supabaseMap[customer.id] = customer
        }
        
        var localMap: [UUID: Customer] = [:]
        for customer in localCustomers {
            localMap[customer.id!] = customer
        }
        
        // Sync logic
        for (id, supabaseCustomer) in supabaseMap {
            if let localCustomer = localMap[id] {
                // Customer exists locally - check if update needed
                if supabaseCustomer.updatedAt > (localCustomer.updatedAt ?? Date.distantPast) {
                    // Server is newer - update local
                    updateLocalCustomer(localCustomer, from: supabaseCustomer)
                }
            } else {
                // Customer doesn't exist locally - create it
                createLocalCustomer(from: supabaseCustomer)
            }
        }
        
        // Upload local customers not in Supabase
        for (id, localCustomer) in localMap {
            if supabaseMap[id] == nil {
                try await uploadCustomer(localCustomer)
            }
        }
        
        coreData.save()
        print("✅ Customers synced")
    }
    
    // MARK: - Repair Ticket Sync
    
    func syncRepairTickets() async throws {
        print("🔄 Syncing repair tickets...")
        
        // Fetch from Supabase
        let supabaseTickets: [SupabaseRepairTicket] = try await supabase.client
            .from("repair_tickets")
            .select()
            .execute()
            .value
        
        // Fetch local tickets
        let request = Ticket.fetchRequest()
        let localTickets = try coreData.viewContext.fetch(request)
        
        // Create maps
        var supabaseMap: [UUID: SupabaseRepairTicket] = [:]
        for ticket in supabaseTickets {
            supabaseMap[ticket.id] = ticket
        }
        
        var localMap: [UUID: Ticket] = [:]
        for ticket in localTickets {
            if let id = ticket.id {
                localMap[id] = ticket
            }
        }
        
        // Sync tickets
        for (id, supabaseTicket) in supabaseMap {
            if let localTicket = localMap[id] {
                // Update if server is newer
                if supabaseTicket.updatedAt > (localTicket.updatedAt ?? Date.distantPast) {
                    updateLocalTicket(localTicket, from: supabaseTicket)
                }
            } else {
                // Create new local ticket
                createLocalTicket(from: supabaseTicket)
            }
        }
        
        // Upload local tickets not in Supabase
        for (id, localTicket) in localMap {
            if supabaseMap[id] == nil {
                try await uploadTicket(localTicket)
            }
        }
        
        coreData.save()
        print("✅ Repair tickets synced")
    }
    
    // MARK: - Employee Sync
    
    func syncEmployees() async throws {
        print("🔄 Syncing employees...")
        
        let supabaseEmployees: [SupabaseEmployee] = try await supabase.client
            .from("employees")
            .select()
            .execute()
            .value
        
        let request = Employee.fetchRequest()
        let localEmployees = try coreData.viewContext.fetch(request)
        
        var supabaseMap: [UUID: SupabaseEmployee] = [:]
        for employee in supabaseEmployees {
            supabaseMap[employee.id] = employee
        }
        
        var localMap: [UUID: Employee] = [:]
        for employee in localEmployees {
            if let id = employee.id {
                localMap[id] = employee
            }
        }
        
        // Sync employees
        for (id, supabaseEmployee) in supabaseMap {
            if let localEmployee = localMap[id] {
                // Update if needed
                if supabaseEmployee.updatedAt > (localEmployee.updatedAt ?? Date.distantPast) {
                    updateLocalEmployee(localEmployee, from: supabaseEmployee)
                }
            } else {
                // Create new local employee
                createLocalEmployee(from: supabaseEmployee)
            }
        }
        
        coreData.save()
        print("✅ Employees synced")
    }
    
    // MARK: - Helper Methods - Customer
    
    private func updateLocalCustomer(_ local: Customer, from remote: SupabaseCustomer) {
        local.firstName = remote.firstName
        local.lastName = remote.lastName
        local.email = remote.email
        local.phone = remote.phone
        local.notes = remote.address
        local.updatedAt = remote.updatedAt
    }
    
    private func createLocalCustomer(from remote: SupabaseCustomer) {
        let customer = Customer(context: coreData.viewContext)
        customer.id = remote.id
        customer.firstName = remote.firstName
        customer.lastName = remote.lastName
        customer.email = remote.email
        customer.phone = remote.phone
        customer.notes = remote.address
        customer.createdAt = remote.createdAt
        customer.updatedAt = remote.updatedAt
    }
    
    private func uploadCustomer(_ customer: Customer) async throws {
        guard let id = customer.id else { return }
        
        struct CustomerUpload: Encodable {
            let id: String
            let first_name: String
            let last_name: String
            let email: String
            let phone: String?
            let address: String?
            let created_at: String
            let updated_at: String
        }
        
        let data = CustomerUpload(
            id: id.uuidString,
            first_name: customer.firstName ?? "",
            last_name: customer.lastName ?? "",
            email: customer.email ?? "",
            phone: customer.phone,
            address: customer.notes,
            created_at: (customer.createdAt ?? Date()).ISO8601Format(),
            updated_at: (customer.updatedAt ?? Date()).ISO8601Format()
        )
        
        try await supabase.client
            .from("customers")
            .upsert(data)
            .execute()
    }
    
    // MARK: - Helper Methods - Ticket
    
    private func updateLocalTicket(_ local: Ticket, from remote: SupabaseRepairTicket) {
        if let ticketNum = Int32(remote.ticketNumber.replacingOccurrences(of: "TKT-", with: "")) {
            local.ticketNumber = ticketNum
        }
        local.deviceType = remote.deviceType
        local.deviceModel = remote.deviceModel
        local.issueDescription = remote.issueDescription
        local.status = remote.status.rawValue
        if let cost = remote.estimatedCost {
            local.estimatedCost = NSDecimalNumber(decimal: cost)
        }
        if let cost = remote.actualCost {
            local.actualCost = NSDecimalNumber(decimal: cost)
        }
        local.updatedAt = remote.updatedAt
    }
    
    private func createLocalTicket(from remote: SupabaseRepairTicket) {
        let ticket = Ticket(context: coreData.viewContext)
        ticket.id = remote.id
        if let ticketNum = Int32(remote.ticketNumber.replacingOccurrences(of: "TKT-", with: "")) {
            ticket.ticketNumber = ticketNum
        }
        ticket.deviceType = remote.deviceType
        ticket.deviceModel = remote.deviceModel
        ticket.issueDescription = remote.issueDescription
        ticket.status = remote.status.rawValue
        if let cost = remote.estimatedCost {
            ticket.estimatedCost = NSDecimalNumber(decimal: cost)
        }
        if let cost = remote.actualCost {
            ticket.actualCost = NSDecimalNumber(decimal: cost)
        }
        ticket.createdAt = remote.createdAt
        ticket.updatedAt = remote.updatedAt
    }
    
    private func uploadTicket(_ ticket: Ticket) async throws {
        guard let id = ticket.id else { return }
        
        struct TicketUpload: Encodable {
            let id: String
            let ticket_number: String
            let device_type: String
            let device_model: String?
            let issue_description: String
            let status: String
            let estimated_cost: Double?
            let actual_cost: Double?
            let created_at: String
            let updated_at: String
        }
        
        let data = TicketUpload(
            id: id.uuidString,
            ticket_number: "TKT-\(String(format: "%06d", ticket.ticketNumber))",
            device_type: ticket.deviceType ?? "",
            device_model: ticket.deviceModel,
            issue_description: ticket.issueDescription ?? "",
            status: ticket.status ?? "checked_in",
            estimated_cost: ticket.estimatedCost?.doubleValue,
            actual_cost: ticket.actualCost?.doubleValue,
            created_at: (ticket.createdAt ?? Date()).ISO8601Format(),
            updated_at: (ticket.updatedAt ?? Date()).ISO8601Format()
        )
        
        try await supabase.client
            .from("repair_tickets")
            .upsert(data)
            .execute()
    }
    
    // MARK: - Helper Methods - Employee
    
    private func updateLocalEmployee(_ local: Employee, from remote: SupabaseEmployee) {
        local.firstName = remote.firstName
        local.lastName = remote.lastName
        local.email = remote.email
        local.role = remote.role
        local.isActive = remote.isActive
        local.updatedAt = remote.updatedAt
    }
    
    private func createLocalEmployee(from remote: SupabaseEmployee) {
        let employee = Employee(context: coreData.viewContext)
        employee.id = remote.id
        employee.firstName = remote.firstName
        employee.lastName = remote.lastName
        employee.email = remote.email
        employee.role = remote.role
        employee.isActive = remote.isActive
        employee.createdAt = remote.createdAt
        employee.updatedAt = remote.updatedAt
    }
}

// MARK: - Supabase Model Structs

struct SupabaseCustomer: Codable {
    let id: UUID
    let firstName: String
    let lastName: String
    let email: String
    let phone: String?
    let address: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case phone
        case address
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct SupabaseRepairTicket: Codable {
    let id: UUID
    let ticketNumber: String
    let deviceType: String
    let deviceModel: String?
    let issueDescription: String
    let status: SupabaseRepairStatus
    let estimatedCost: Decimal?
    let actualCost: Decimal?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case ticketNumber = "ticket_number"
        case deviceType = "device_type"
        case deviceModel = "device_model"
        case issueDescription = "issue_description"
        case status
        case estimatedCost = "estimated_cost"
        case actualCost = "actual_cost"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct SupabaseEmployee: Codable {
    let id: UUID
    let firstName: String
    let lastName: String
    let email: String
    let role: String
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case role
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum SupabaseRepairStatus: String, Codable {
    case checkedIn = "checked_in"
    case diagnosing = "diagnosing"
    case awaitingParts = "awaiting_parts"
    case inProgress = "in_progress"
    case qualityCheck = "quality_check"
    case completed = "completed"
    case readyForPickup = "ready_for_pickup"
    case pickedUp = "picked_up"
    case cancelled = "cancelled"
}
