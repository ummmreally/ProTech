//
//  AppointmentSyncer.swift
//  ProTech
//
//  Handles bidirectional sync between Core Data and Supabase for appointments
//

import Foundation
import CoreData
import Supabase

@MainActor
class AppointmentSyncer: ObservableObject {
    private let supabase = SupabaseService.shared
    private let coreData = CoreDataManager.shared
    
    @Published var isSyncing = false
    @Published var syncError: Error?
    @Published var lastSyncDate: Date?
    
    // MARK: - Supabase Model
    
    struct SupabaseAppointment: Codable {
        let id: UUID
        let shopId: UUID
        let customerId: UUID
        let ticketId: UUID?
        let appointmentType: String
        let scheduledDate: Date
        let duration: Int
        let status: String
        let notes: String?
        let reminderSent: Bool
        let confirmationSent: Bool
        let completedAt: Date?
        let cancelledAt: Date?
        let cancellationReason: String?
        let createdAt: Date
        let updatedAt: Date
        let deletedAt: Date?
        let syncVersion: Int
        
        enum CodingKeys: String, CodingKey {
            case id, notes
            case shopId = "shop_id"
            case customerId = "customer_id"
            case ticketId = "ticket_id"
            case appointmentType = "appointment_type"
            case scheduledDate = "scheduled_date"
            case duration, status
            case reminderSent = "reminder_sent"
            case confirmationSent = "confirmation_sent"
            case completedAt = "completed_at"
            case cancelledAt = "cancelled_at"
            case cancellationReason = "cancellation_reason"
            case createdAt = "created_at"
            case updatedAt = "updated_at"
            case deletedAt = "deleted_at"
            case syncVersion = "sync_version"
        }
    }
    
    // MARK: - Upload
    
    /// Upload a local appointment to Supabase
    func upload(_ appointment: Appointment) async throws {
        guard let shopId = getShopId() else {
            throw SyncError.notAuthenticated
        }
        
        guard let appointmentId = appointment.id,
              let customerId = appointment.customerId,
              let scheduledDate = appointment.scheduledDate else {
            throw SyncError.conflict(details: "Appointment missing required fields")
        }
        
        let supabaseAppointment = SupabaseAppointment(
            id: appointmentId,
            shopId: shopId,
            customerId: customerId,
            ticketId: appointment.ticketId,
            appointmentType: appointment.appointmentType ?? "consultation",
            scheduledDate: scheduledDate,
            duration: Int(appointment.duration),
            status: appointment.status ?? "scheduled",
            notes: appointment.notes,
            reminderSent: appointment.reminderSent,
            confirmationSent: appointment.confirmationSent,
            completedAt: appointment.completedAt,
            cancelledAt: appointment.cancelledAt,
            cancellationReason: appointment.cancellationReason,
            createdAt: appointment.createdAt ?? Date(),
            updatedAt: appointment.updatedAt ?? Date(),
            deletedAt: nil,
            syncVersion: 1
        )
        
        try await supabase.client
            .from("appointments")
            .upsert(supabaseAppointment)
            .execute()
        
        // Mark as synced
        appointment.cloudSyncStatus = "synced"
        appointment.updatedAt = Date()
        try coreData.viewContext.save()
    }
    
    /// Upload all pending local changes
    func uploadPendingChanges() async throws {
        let request: NSFetchRequest<Appointment> = Appointment.fetchRequest()
        request.predicate = NSPredicate(format: "cloudSyncStatus == %@ OR cloudSyncStatus == nil", "pending")
        let pendingAppointments = try coreData.viewContext.fetch(request)
        
        for appointment in pendingAppointments {
            try await upload(appointment)
        }
    }
    
    // MARK: - Download
    
    /// Download all appointments from Supabase and merge with local
    func download() async throws {
        guard let shopId = getShopId() else {
            throw SyncError.notAuthenticated
        }
        
        isSyncing = true
        defer { isSyncing = false }
        
        let remoteAppointments: [SupabaseAppointment] = try await supabase.client
            .from("appointments")
            .select()
            .eq("shop_id", value: shopId.uuidString)
            .is("deleted_at", value: nil)
            .order("scheduled_date", ascending: false)
            .execute()
            .value
        
        for remote in remoteAppointments {
            try await mergeOrCreate(remote)
        }
        
        lastSyncDate = Date()
    }
    
    /// Download appointments for a specific date range
    func downloadForDateRange(from startDate: Date, to endDate: Date) async throws {
        guard let shopId = getShopId() else {
            throw SyncError.notAuthenticated
        }
        
        isSyncing = true
        defer { isSyncing = false }
        
        let remoteAppointments: [SupabaseAppointment] = try await supabase.client
            .from("appointments")
            .select()
            .eq("shop_id", value: shopId.uuidString)
            .gte("scheduled_date", value: startDate.ISO8601Format())
            .lte("scheduled_date", value: endDate.ISO8601Format())
            .is("deleted_at", value: nil)
            .order("scheduled_date", ascending: true)
            .execute()
            .value
        
        for remote in remoteAppointments {
            try await mergeOrCreate(remote)
        }
        
        lastSyncDate = Date()
    }
    
    // MARK: - Merge
    
    private func mergeOrCreate(_ remote: SupabaseAppointment) async throws {
        let request: NSFetchRequest<Appointment> = Appointment.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", remote.id as CVarArg)
        
        let results = try coreData.viewContext.fetch(request)
        
        if let local = results.first {
            // Merge existing: use newest version
            if shouldUpdateLocal(local, from: remote) {
                try updateLocal(local, from: remote)
            }
        } else {
            // Create new local record
            try createLocal(from: remote)
        }
        
        try coreData.viewContext.save()
    }
    
    private func shouldUpdateLocal(_ local: Appointment, from remote: SupabaseAppointment) -> Bool {
        let localDate = local.updatedAt ?? Date.distantPast
        return remote.updatedAt > localDate
    }
    
    private func updateLocal(_ local: Appointment, from remote: SupabaseAppointment) throws {
        local.customerId = remote.customerId
        local.ticketId = remote.ticketId
        local.appointmentType = remote.appointmentType
        local.scheduledDate = remote.scheduledDate
        local.duration = Int16(remote.duration)
        local.status = remote.status
        local.notes = remote.notes
        local.reminderSent = remote.reminderSent
        local.confirmationSent = remote.confirmationSent
        local.completedAt = remote.completedAt
        local.cancelledAt = remote.cancelledAt
        local.cancellationReason = remote.cancellationReason
        local.createdAt = remote.createdAt
        local.updatedAt = remote.updatedAt
        local.cloudSyncStatus = "synced"
    }
    
    private func createLocal(from remote: SupabaseAppointment) throws {
        let appointment = Appointment(context: coreData.viewContext)
        appointment.id = remote.id
        appointment.customerId = remote.customerId
        appointment.ticketId = remote.ticketId
        appointment.appointmentType = remote.appointmentType
        appointment.scheduledDate = remote.scheduledDate
        appointment.duration = Int16(remote.duration)
        appointment.status = remote.status
        appointment.notes = remote.notes
        appointment.reminderSent = remote.reminderSent
        appointment.confirmationSent = remote.confirmationSent
        appointment.completedAt = remote.completedAt
        appointment.cancelledAt = remote.cancelledAt
        appointment.cancellationReason = remote.cancellationReason
        appointment.createdAt = remote.createdAt
        appointment.updatedAt = remote.updatedAt
        appointment.cloudSyncStatus = "synced"
    }
    
    // MARK: - Real-time Subscriptions
    
    private var appointmentChannel: RealtimeChannelV2?
    
    /// Start listening to real-time appointment changes
    func startRealtimeSync() async throws {
        guard getShopId() != nil else {
            throw SyncError.notAuthenticated
        }
        
        // TODO: Implement proper Realtime V2 subscriptions when stable
        // For now, use periodic polling as a fallback
        print("Real-time subscriptions for appointments will be implemented with stable Realtime V2 API")
        
        // Start periodic sync every 30 seconds
        Task {
            while appointmentChannel != nil {
                try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
                try? await download()
            }
        }
    }
    
    /// Stop real-time sync
    func stopRealtimeSync() async {
        appointmentChannel = nil
    }
    
    private func deleteLocal(id: UUID) async throws {
        let request: NSFetchRequest<Appointment> = Appointment.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        if let appointment = try coreData.viewContext.fetch(request).first {
            coreData.viewContext.delete(appointment)
            try coreData.viewContext.save()
        }
    }
    
    // MARK: - Soft Delete
    
    /// Soft delete appointment (mark as deleted in Supabase)
    func softDelete(_ appointment: Appointment) async throws {
        guard let appointmentId = appointment.id else {
            throw SyncError.conflict(details: "Appointment missing ID")
        }
        
        // Update Supabase record to mark as deleted
        try await supabase.client
            .from("appointments")
            .update(["deleted_at": Date().ISO8601Format()])
            .eq("id", value: appointmentId.uuidString)
            .execute()
        
        // Delete locally
        coreData.viewContext.delete(appointment)
        try coreData.viewContext.save()
    }
    
    // MARK: - Helper Methods
    
    private func getShopId() -> UUID? {
        guard let shopIdString = SupabaseService.shared.currentShopId else {
            return nil
        }
        return UUID(uuidString: shopIdString)
    }
    
    // MARK: - Batch Operations
    
    /// Upload multiple appointments efficiently
    func uploadBatch(_ appointments: [Appointment]) async throws {
        let supabaseAppointments = appointments.compactMap { appointment -> SupabaseAppointment? in
            guard let shopId = getShopId(),
                  let appointmentId = appointment.id,
                  let customerId = appointment.customerId,
                  let scheduledDate = appointment.scheduledDate else {
                return nil
            }
            
            return SupabaseAppointment(
                id: appointmentId,
                shopId: shopId,
                customerId: customerId,
                ticketId: appointment.ticketId,
                appointmentType: appointment.appointmentType ?? "consultation",
                scheduledDate: scheduledDate,
                duration: Int(appointment.duration),
                status: appointment.status ?? "scheduled",
                notes: appointment.notes,
                reminderSent: appointment.reminderSent,
                confirmationSent: appointment.confirmationSent,
                completedAt: appointment.completedAt,
                cancelledAt: appointment.cancelledAt,
                cancellationReason: appointment.cancellationReason,
                createdAt: appointment.createdAt ?? Date(),
                updatedAt: appointment.updatedAt ?? Date(),
                deletedAt: nil,
                syncVersion: 1
            )
        }
        
        if !supabaseAppointments.isEmpty {
            try await supabase.client
                .from("appointments")
                .upsert(supabaseAppointments)
                .execute()
        }
    }
    
    // MARK: - Statistics
    
    /// Get appointment statistics from Supabase
    func getStats() async throws -> AppointmentStats {
        guard let shopId = getShopId() else {
            throw SyncError.notAuthenticated
        }
        
        struct StatsResponse: Decodable {
            let upcomingCount: Int?
            let todayCount: Int?
            let completedCount: Int?
            let cancelledCount: Int?
            let noShowCount: Int?
            
            enum CodingKeys: String, CodingKey {
                case upcomingCount = "upcoming_count"
                case todayCount = "today_count"
                case completedCount = "completed_count"
                case cancelledCount = "cancelled_count"
                case noShowCount = "no_show_count"
            }
        }
        
        let response: [StatsResponse] = try await supabase.client
            .from("appointment_stats")
            .select()
            .eq("shop_id", value: shopId.uuidString)
            .execute()
            .value
        
        guard let stats = response.first else {
            return AppointmentStats(upcoming: 0, today: 0, completed: 0, cancelled: 0, noShow: 0)
        }
        
        return AppointmentStats(
            upcoming: stats.upcomingCount ?? 0,
            today: stats.todayCount ?? 0,
            completed: stats.completedCount ?? 0,
            cancelled: stats.cancelledCount ?? 0,
            noShow: stats.noShowCount ?? 0
        )
    }
}

// MARK: - Supporting Types

struct AppointmentStats {
    let upcoming: Int
    let today: Int
    let completed: Int
    let cancelled: Int
    let noShow: Int
}
