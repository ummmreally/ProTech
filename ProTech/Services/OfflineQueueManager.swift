//
//  OfflineQueueManager.swift
//  ProTech
//
//  Manages offline sync operations and retry logic
//

import Foundation
import CoreData
import Network
import Combine

@MainActor
class OfflineQueueManager: ObservableObject {
    static let shared = OfflineQueueManager()
    
    // Network monitoring
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue.global(qos: .background)
    
    // Sync services
    private let customerSyncer = CustomerSyncer()
    private let ticketSyncer = TicketSyncer()
    private let inventorySyncer = InventorySyncer()
    private let employeeSyncer = EmployeeSyncer()
    private let appointmentSyncer = AppointmentSyncer()
    
    // Core Data
    private let coreData = CoreDataManager.shared
    
    // Published properties
    @Published var isOnline = true
    @Published var pendingOperations: [QueuedSyncOperation] = []
    @Published var isSyncing = false
    @Published var syncProgress: Double = 0.0
    @Published var lastSyncError: Error?
    
    // Retry configuration
    private let maxRetries = 3
    private let retryDelay: TimeInterval = 5.0
    private var retryTimer: Timer?
    
    init() {
        setupNetworkMonitoring()
        loadPendingOperations()
    }
    
    // MARK: - Network Monitoring
    
    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.handleNetworkChange(path)
            }
        }
        monitor.start(queue: queue)
    }
    
    private func handleNetworkChange(_ path: NWPath) {
        let wasOffline = !isOnline
        isOnline = path.status == .satisfied
        
        if wasOffline && isOnline {
            // Network restored - process queue
            Task {
                await processPendingQueue()
            }
        }
    }
    
    // MARK: - Queue Management
    
    /// Add operation to offline queue
    func addToQueue(_ operation: QueuedSyncOperation) {
        pendingOperations.append(operation)
        savePendingOperations()
        
        if isOnline {
            Task {
                await processOperation(operation)
            }
        }
    }
    
    /// Process all pending operations
    func processPendingQueue() async {
        guard isOnline && !pendingOperations.isEmpty && !isSyncing else { return }
        
        isSyncing = true
        defer { isSyncing = false }
        
        let totalOperations = pendingOperations.count
        var completedOperations = 0
        
        // Process operations in order
        while !pendingOperations.isEmpty {
            let operation = pendingOperations[0]
            
            do {
                try await executeOperation(operation)
                pendingOperations.removeFirst()
                completedOperations += 1
                syncProgress = Double(completedOperations) / Double(totalOperations)
            } catch {
                // Handle retry logic
                if operation.retryCount < maxRetries {
                    var updatedOperation = operation
                    updatedOperation.retryCount += 1
                    updatedOperation.lastError = error.localizedDescription
                    pendingOperations[0] = updatedOperation
                    
                    // Wait before retry
                    try? await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                } else {
                    // Max retries reached, move to failed queue
                    var failedOperation = operation
                    failedOperation.status = .failed
                    failedOperation.lastError = error.localizedDescription
                    pendingOperations.removeFirst()
                    
                    // Save to failed operations for manual retry
                    saveFailedOperation(failedOperation)
                }
                
                lastSyncError = error
            }
        }
        
        savePendingOperations()
        syncProgress = 0.0
    }
    
    /// Execute a single sync operation
    private func executeOperation(_ operation: QueuedSyncOperation) async throws {
        switch operation.type {
        case .uploadCustomer:
            if let customerId = operation.entityId,
               let customer = try fetchCustomer(id: customerId) {
                try await customerSyncer.upload(customer)
            }
            
        case .uploadTicket:
            if let ticketId = operation.entityId,
               let ticket = try fetchTicket(id: ticketId) {
                try await ticketSyncer.upload(ticket)
            }
            
        case .uploadInventory:
            if let itemId = operation.entityId,
               let item = try fetchInventoryItem(id: itemId) {
                try await inventorySyncer.upload(item)
            }
            
        case .downloadCustomers:
            try await customerSyncer.download()
            
        case .downloadTickets:
            try await ticketSyncer.download()
            
        case .downloadInventory:
            try await inventorySyncer.download()
            
        case .deleteCustomer:
            if let customerId = operation.entityId {
                try await deleteRemoteCustomer(id: customerId)
            }
            
        case .deleteTicket:
            if let ticketId = operation.entityId {
                try await deleteRemoteTicket(id: ticketId)
            }
            
        case .deleteInventory:
            if let itemId = operation.entityId {
                try await deleteRemoteInventoryItem(id: itemId)
            }
            
        case .uploadEmployee:
            if let employeeId = operation.entityId,
               let employee = try fetchEmployee(id: employeeId) {
                try await employeeSyncer.upload(employee)
            }
            
        case .uploadAppointment:
            if let appointmentId = operation.entityId,
               let appointment = try fetchAppointment(id: appointmentId) {
                try await appointmentSyncer.upload(appointment)
            }
            
        case .downloadEmployees:
            try await employeeSyncer.download()
            
        case .downloadAppointments:
            try await appointmentSyncer.download()
            
        case .deleteEmployee:
            if let employeeId = operation.entityId {
                try await deleteRemoteEmployee(id: employeeId)
            }
            
        case .deleteAppointment:
            if let appointmentId = operation.entityId {
                try await deleteRemoteAppointment(id: appointmentId)
            }
        }
    }
    
    private func processOperation(_ operation: QueuedSyncOperation) async {
        do {
            try await executeOperation(operation)
            
            // Remove from queue on success
            if let index = pendingOperations.firstIndex(where: { $0.id == operation.id }) {
                pendingOperations.remove(at: index)
                savePendingOperations()
            }
        } catch {
            print("Failed to process operation: \(error)")
            lastSyncError = error
        }
    }
    
    // MARK: - Core Data Fetchers
    
    private func fetchCustomer(id: UUID) throws -> Customer? {
        let request: NSFetchRequest<Customer> = Customer.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try coreData.viewContext.fetch(request).first
    }
    
    private func fetchTicket(id: UUID) throws -> Ticket? {
        let request: NSFetchRequest<Ticket> = Ticket.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try coreData.viewContext.fetch(request).first
    }
    
    private func fetchInventoryItem(id: UUID) throws -> InventoryItem? {
        let request: NSFetchRequest<InventoryItem> = InventoryItem.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try coreData.viewContext.fetch(request).first
    }
    
    private func fetchEmployee(id: UUID) throws -> Employee? {
        let request: NSFetchRequest<Employee> = Employee.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try coreData.viewContext.fetch(request).first
    }
    
    private func fetchAppointment(id: UUID) throws -> Appointment? {
        let request: NSFetchRequest<Appointment> = Appointment.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try coreData.viewContext.fetch(request).first
    }
    
    // MARK: - Remote Delete Operations
    
    private func deleteRemoteCustomer(id: UUID) async throws {
        let supabase = SupabaseService.shared
        
        try await supabase.client
            .from("customers")
            .update(["deleted_at": Date().iso8601String])
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    private func deleteRemoteTicket(id: UUID) async throws {
        let supabase = SupabaseService.shared
        
        try await supabase.client
            .from("tickets")
            .update(["deleted_at": Date().iso8601String])
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    private func deleteRemoteInventoryItem(id: UUID) async throws {
        let supabase = SupabaseService.shared
        
        try await supabase.client
            .from("inventory_items")
            .update(["deleted_at": Date().iso8601String])
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    private func deleteRemoteEmployee(id: UUID) async throws {
        let supabase = SupabaseService.shared
        
        try await supabase.client
            .from("employees")
            .update(["deleted_at": Date().iso8601String])
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    private func deleteRemoteAppointment(id: UUID) async throws {
        let supabase = SupabaseService.shared
        
        try await supabase.client
            .from("appointments")
            .update(["deleted_at": Date().iso8601String])
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    // MARK: - Persistence
    
    private func loadPendingOperations() {
        guard let data = UserDefaults.standard.data(forKey: "PendingSyncOperations"),
              let operations = try? JSONDecoder().decode([QueuedSyncOperation].self, from: data) else {
            return
        }
        pendingOperations = operations
    }
    
    private func savePendingOperations() {
        guard let data = try? JSONEncoder().encode(pendingOperations) else { return }
        UserDefaults.standard.set(data, forKey: "PendingSyncOperations")
    }
    
    private func saveFailedOperation(_ operation: QueuedSyncOperation) {
        var failedOperations = loadFailedOperations()
        failedOperations.append(operation)
        
        guard let data = try? JSONEncoder().encode(failedOperations) else { return }
        UserDefaults.standard.set(data, forKey: "FailedSyncOperations")
    }
    
    private func loadFailedOperations() -> [QueuedSyncOperation] {
        guard let data = UserDefaults.standard.data(forKey: "FailedSyncOperations"),
              let operations = try? JSONDecoder().decode([QueuedSyncOperation].self, from: data) else {
            return []
        }
        return operations
    }
    
    // MARK: - Public Methods
    
    /// Queue a customer upload
    func queueCustomerUpload(_ customer: Customer) {
        let operation = QueuedSyncOperation(
            type: .uploadCustomer,
            entityId: customer.id,
            entityType: "Customer",
            data: nil
        )
        addToQueue(operation)
    }
    
    /// Queue a ticket upload
    func queueTicketUpload(_ ticket: Ticket) {
        let operation = QueuedSyncOperation(
            type: .uploadTicket,
            entityId: ticket.id,
            entityType: "Ticket",
            data: nil
        )
        addToQueue(operation)
    }
    
    /// Queue an inventory item upload
    func queueInventoryUpload(_ item: InventoryItem) {
        let operation = QueuedSyncOperation(
            type: .uploadInventory,
            entityId: item.id,
            entityType: "InventoryItem",
            data: nil
        )
        addToQueue(operation)
    }
    
    /// Queue an employee upload
    func queueEmployeeUpload(_ employee: Employee) {
        let operation = QueuedSyncOperation(
            type: .uploadEmployee,
            entityId: employee.id,
            entityType: "Employee",
            data: nil
        )
        addToQueue(operation)
    }
    
    /// Queue an appointment upload
    func queueAppointmentUpload(_ appointment: Appointment) {
        let operation = QueuedSyncOperation(
            type: .uploadAppointment,
            entityId: appointment.id,
            entityType: "Appointment",
            data: nil
        )
        addToQueue(operation)
    }
    
    /// Queue a full sync
    func queueFullSync() {
        let operations = [
            QueuedSyncOperation(type: .downloadCustomers, entityType: "Customer"),
            QueuedSyncOperation(type: .downloadTickets, entityType: "Ticket"),
            QueuedSyncOperation(type: .downloadInventory, entityType: "InventoryItem"),
            QueuedSyncOperation(type: .downloadEmployees, entityType: "Employee"),
            QueuedSyncOperation(type: .downloadAppointments, entityType: "Appointment")
        ]
        
        for op in operations {
            addToQueue(op)
        }
    }
    
    /// Retry failed operations
    func retryFailedOperations() {
        let failedOps = loadFailedOperations()
        
        for var op in failedOps {
            op.retryCount = 0
            op.status = .pending
            addToQueue(op)
        }
        
        // Clear failed operations
        UserDefaults.standard.removeObject(forKey: "FailedSyncOperations")
    }
    
    /// Clear all pending operations
    func clearQueue() {
        pendingOperations.removeAll()
        savePendingOperations()
    }
}

// MARK: - Models

struct QueuedSyncOperation: Codable, Identifiable {
    var id: UUID
    let type: QueuedSyncOperationType
    let entityId: UUID?
    let entityType: String
    var data: Data?
    var retryCount: Int
    var status: QueuedSyncStatus
    var lastError: String?
    var createdAt: Date
    
    init(type: QueuedSyncOperationType, entityId: UUID? = nil, entityType: String, data: Data? = nil) {
        self.id = UUID()
        self.type = type
        self.entityId = entityId
        self.entityType = entityType
        self.data = data
        self.retryCount = 0
        self.status = .pending
        self.createdAt = Date()
    }
}

enum QueuedSyncOperationType: String, Codable {
    case uploadCustomer
    case uploadTicket
    case uploadInventory
    case uploadEmployee
    case uploadAppointment
    case downloadCustomers
    case downloadTickets
    case downloadInventory
    case downloadEmployees
    case downloadAppointments
    case deleteCustomer
    case deleteTicket
    case deleteInventory
    case deleteEmployee
    case deleteAppointment
}

enum QueuedSyncStatus: String, Codable {
    case pending
    case inProgress
    case completed
    case failed
}
