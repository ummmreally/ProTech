//
//  RealtimeManager.swift
//  ProTech
//
//  Manages real-time subscriptions for all entities
//

import Foundation
import Supabase
import Combine

@MainActor
class RealtimeManager: ObservableObject {
    static let shared = RealtimeManager()
    
    private let supabase = SupabaseService.shared
    private let customerSyncer = CustomerSyncer()
    private let ticketSyncer = TicketSyncer()
    private let inventorySyncer = InventorySyncer()
    private let employeeSyncer = EmployeeSyncer()
    private let appointmentSyncer = AppointmentSyncer()
    
    @Published var isRealtimeActive = false
    @Published var lastRealtimeUpdate: Date?
    @Published var isUsingPollingFallback = false
    
    // Polling configuration (fallback for real-time)
    private var pollingTask: Task<Void, Never>?
    private let pollingInterval: TimeInterval = 30.0 // 30 seconds
    
    private enum RealtimeManagerError: Error {
        case missingShopId
    }
    
    private enum Entity: Hashable {
        case customers
        case tickets
        case inventory
        case employees
        case appointments
    }
    
    private var channel: RealtimeChannelV2?
    private var changeTasks: [Task<Void, Never>] = []
    private var scheduledSyncTasks: [Entity: Task<Void, Never>] = [:]
    
    private init() {}
    
    // MARK: - Start/Stop Real-time
    
    /// Start real-time sync for all entities
    func startRealtimeSync() async {
        guard !isRealtimeActive else { return }
        
        isRealtimeActive = true
        
        do {
            try await startRealtimeChannel()
            isUsingPollingFallback = false
            print("✅ Real-time sync started (realtime mode)")
        } catch {
            isUsingPollingFallback = true
            startPolling()
            print("⚠️ Real-time subscriptions failed, falling back to polling: \(error.localizedDescription)")
        }
    }
    
    /// Stop real-time sync
    func stopRealtimeSync() {
        pollingTask?.cancel()
        pollingTask = nil
        isUsingPollingFallback = false
        
        for task in changeTasks {
            task.cancel()
        }
        changeTasks.removeAll()
        
        for (_, task) in scheduledSyncTasks {
            task.cancel()
        }
        scheduledSyncTasks.removeAll()
        
        if let channel {
            Task {
                await channel.unsubscribe()
                await supabase.client.removeChannel(channel)
            }
        }
        channel = nil
        isRealtimeActive = false
        
        print("⏹️ Real-time sync stopped")
    }
    
    private func startRealtimeChannel() async throws {
        guard channel == nil else { return }
        
        guard let shopId = supabase.currentShopId, !shopId.isEmpty else {
            throw RealtimeManagerError.missingShopId
        }
        let channel = supabase.client.channel("realtime-v2-\(shopId)")
        self.channel = channel
        
        // Define typed changes
        let customerChanges = channel.postgresChange(AnyAction.self, schema: "public", table: "customers")
        let ticketChanges = channel.postgresChange(AnyAction.self, schema: "public", table: "tickets")
        let inventoryChanges = channel.postgresChange(AnyAction.self, schema: "public", table: "inventory_items")
        let employeeChanges = channel.postgresChange(AnyAction.self, schema: "public", table: "employees")
        let appointmentChanges = channel.postgresChange(AnyAction.self, schema: "public", table: "appointments")
        
        try await channel.subscribeWithError()
        
        changeTasks = [
            Task { [weak self] in
                for await action in customerChanges {
                    switch action {
                    case .insert(let change):
                        if let record = try? change.record.decode(as: SupabaseCustomer.self) {
                            await self?.customerSyncer.processRemoteUpsert(record)
                        }
                    case .update(let change):
                        if let record = try? change.record.decode(as: SupabaseCustomer.self) {
                            await self?.customerSyncer.processRemoteUpsert(record)
                        }
                    case .delete(let change):
                        let oldRecord = change.oldRecord
                        // Assuming AnyJSON can decode to a struct with ID if it matches shape, or we decode strictly
                        struct IDWrapper: Decodable { let id: UUID }
                        if let idData = try? oldRecord.decode(as: IDWrapper.self) {
                            await self?.customerSyncer.processRemoteDelete(idData.id)
                        }
                    default: break
                    }
                    await MainActor.run { self?.lastRealtimeUpdate = Date() }
                }
            },
            Task { [weak self] in
                for await action in ticketChanges {
                    switch action {
                    case .insert(let change):
                        if let record = try? change.record.decode(as: SupabaseTicket.self) {
                             await self?.ticketSyncer.processRemoteUpsert(record)
                        }
                    case .update(let change):
                         if let record = try? change.record.decode(as: SupabaseTicket.self) {
                             await self?.ticketSyncer.processRemoteUpsert(record)
                         }
                    case .delete(let change):
                        let oldRecord = change.oldRecord
                        struct IDWrapper: Decodable { let id: UUID }
                        if let idData = try? oldRecord.decode(as: IDWrapper.self) {
                             await self?.ticketSyncer.processRemoteDelete(idData.id)
                        }
                    default: break
                    }
                    await MainActor.run { self?.lastRealtimeUpdate = Date() }
                }
            },
            Task { [weak self] in
                for await action in inventoryChanges {
                    switch action {
                    case .insert(let change):
                        if let record = try? change.record.decode(as: SupabaseInventoryItem.self) {
                            await self?.inventorySyncer.processRemoteUpsert(record)
                        }
                    case .update(let change):
                        if let record = try? change.record.decode(as: SupabaseInventoryItem.self) {
                            await self?.inventorySyncer.processRemoteUpsert(record)
                        }
                    case .delete(let change):
                        let oldRecord = change.oldRecord
                        struct IDWrapper: Decodable { let id: UUID }
                        if let idData = try? oldRecord.decode(as: IDWrapper.self) {
                             await self?.inventorySyncer.processRemoteDelete(idData.id)
                        }
                    default: break
                    }
                    await MainActor.run { self?.lastRealtimeUpdate = Date() }
                }
            },
            Task { [weak self] in
                for await action in employeeChanges {
                     switch action {
                     case .insert(let change):
                         if let record = try? change.record.decode(as: SupabaseEmployee.self) {
                             await self?.employeeSyncer.processRemoteUpsert(record)
                         }
                     case .update(let change):
                         if let record = try? change.record.decode(as: SupabaseEmployee.self) {
                             await self?.employeeSyncer.processRemoteUpsert(record)
                         }
                     case .delete(let change):
                         let oldRecord = change.oldRecord
                         struct IDWrapper: Decodable { let id: UUID }
                         if let idData = try? oldRecord.decode(as: IDWrapper.self) {
                             await self?.employeeSyncer.processRemoteDelete(idData.id)
                         }
                     default: break
                     }
                    await MainActor.run { self?.lastRealtimeUpdate = Date() }
                }
            },
            Task { [weak self] in
                for await action in appointmentChanges {
                    switch action {
                    case .insert(let change):
                        if let record = try? change.record.decode(as: AppointmentSyncer.SupabaseAppointment.self) {
                            await self?.appointmentSyncer.processRemoteUpsert(record)
                        }
                    case .update(let change):
                        if let record = try? change.record.decode(as: AppointmentSyncer.SupabaseAppointment.self) {
                            await self?.appointmentSyncer.processRemoteUpsert(record)
                        }
                    case .delete(let change):
                        let oldRecord = change.oldRecord
                        struct IDWrapper: Decodable { let id: UUID }
                        if let idData = try? oldRecord.decode(as: IDWrapper.self) {
                            await self?.appointmentSyncer.processRemoteDelete(idData.id)
                        }
                    default: break
                    }
                    await MainActor.run { self?.lastRealtimeUpdate = Date() }
                }
            }
        ]
    }
    
    private func scheduleSync(_ entity: Entity) {
        scheduledSyncTasks[entity]?.cancel()
        scheduledSyncTasks[entity] = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 500_000_000)
            await self?.performEntitySync(entity)
        }
    }
    
    private func performEntitySync(_ entity: Entity) async {
        do {
            switch entity {
            case .customers:
                try await customerSyncer.download()
            case .tickets:
                try await ticketSyncer.download()
            case .inventory:
                try await inventorySyncer.download()
            case .employees:
                try await employeeSyncer.download()
            case .appointments:
                try await appointmentSyncer.download()
            }
            lastRealtimeUpdate = Date()
        } catch {
            print("⚠️ Realtime-triggered sync failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Polling Implementation
    
    private func startPolling() {
        pollingTask?.cancel()
        
        pollingTask = Task {
            while !Task.isCancelled && isRealtimeActive {
                await performSync()
                
                // Wait for next interval
                try? await Task.sleep(nanoseconds: UInt64(pollingInterval * 1_000_000_000))
            }
        }
    }
    
    private func performSync() async {
        do {
            // Download updates for all entities
            async let customers: Void = customerSyncer.download()
            async let tickets: Void = ticketSyncer.download()
            async let inventory: Void = inventorySyncer.download()
            async let employees: Void = employeeSyncer.download()
            async let appointments: Void = appointmentSyncer.download()
            
            // Wait for all to complete
            _ = try await (customers, tickets, inventory, employees, appointments)
            
            lastRealtimeUpdate = Date()
            print("✅ Real-time sync completed: \(lastRealtimeUpdate?.formatted() ?? "now")")
        } catch {
            print("⚠️ Real-time sync error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Manual Refresh
    
    /// Trigger immediate sync
    func refreshNow() async {
        await performSync()
    }
    
    // MARK: - Feature-Specific Sync
    
    func syncCustomers() async throws {
        try await customerSyncer.download()
        lastRealtimeUpdate = Date()
    }
    
    func syncTickets() async throws {
        try await ticketSyncer.download()
        lastRealtimeUpdate = Date()
    }
    
    func syncInventory() async throws {
        try await inventorySyncer.download()
        lastRealtimeUpdate = Date()
    }
    
    func syncEmployees() async throws {
        try await employeeSyncer.download()
        lastRealtimeUpdate = Date()
    }
    
    func syncAppointments() async throws {
        try await appointmentSyncer.download()
        lastRealtimeUpdate = Date()
    }
}
