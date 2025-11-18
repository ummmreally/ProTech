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
    
    // Polling configuration (fallback for real-time)
    private var pollingTask: Task<Void, Never>?
    private let pollingInterval: TimeInterval = 30.0 // 30 seconds
    
    private init() {}
    
    // MARK: - Start/Stop Real-time
    
    /// Start real-time sync for all entities
    func startRealtimeSync() async {
        guard !isRealtimeActive else { return }
        
        isRealtimeActive = true
        
        // Use polling as reliable fallback
        startPolling()
        
        print("✅ Real-time sync started (polling mode)")
    }
    
    /// Stop real-time sync
    func stopRealtimeSync() {
        pollingTask?.cancel()
        pollingTask = nil
        isRealtimeActive = false
        
        print("⏹️ Real-time sync stopped")
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
            async let customers = customerSyncer.download()
            async let tickets = ticketSyncer.download()
            async let inventory = inventorySyncer.download()
            async let employees = employeeSyncer.download()
            async let appointments = appointmentSyncer.download()
            
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
