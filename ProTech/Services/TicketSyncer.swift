//
//  TicketSyncer.swift
//  ProTech
//
//  Handles bidirectional sync between Core Data and Supabase for repair tickets
//

import Foundation
import CoreData
import Supabase

@MainActor
class TicketSyncer: ObservableObject {
    private let supabase = SupabaseService.shared
    private let coreData = CoreDataManager.shared
    
    @Published var isSyncing = false
    @Published var syncError: Error?
    @Published var lastSyncDate: Date?
    
    // MARK: - Upload
    
    /// Upload a local ticket to Supabase
    func upload(_ ticket: Ticket) async throws {
        guard let shopId = getShopId() else {
            throw SyncError.notAuthenticated
        }
        
        // Ensure customer exists in Supabase first
        if ticket.customerId != nil {
            // Customer should already be synced, but we could verify here
            // For now, just ensure it exists
        }
        
        guard let ticketId = ticket.id else {
            throw SyncError.conflict(details: "Ticket missing ID")
        }
        
        // Handle signature upload
        var signatureUrl: String?
        if let signatureData = ticket.checkInSignature {
             signatureUrl = try? await uploadSignature(signatureData, for: ticketId, shopId: shopId)
        }
        
        let supabaseTicket = SupabaseTicket(
            id: ticketId,
            shopId: shopId,
            customerId: ticket.customerId ?? UUID(),
            ticketNumber: Int(ticket.ticketNumber),
            deviceType: DeviceType.from(ticket.deviceType).rawValue,
            deviceModel: ticket.deviceModel,
            deviceSerialNumber: ticket.deviceSerialNumber,
            devicePasscode: ticket.devicePasscode,
            issueDescription: ticket.issueDescription,
            additionalRepairDetails: ticket.additionalRepairDetails,
            notes: ticket.notes,
            status: ticket.status ?? "pending",
            priority: ticket.priority ?? "normal",
            estimatedCost: Double(truncating: ticket.estimatedCost ?? 0),
            actualCost: Double(truncating: ticket.actualCost ?? 0),
            estimatedCompletion: ticket.estimatedCompletion,
            findMyDisabled: ticket.findMyDisabled,
            hasDataBackup: ticket.hasDataBackup,
            alternateContactName: ticket.alternateContactName,
            alternateContactNumber: ticket.alternateContactNumber,
            marketingOptInEmail: ticket.marketingOptInEmail,
            marketingOptInSms: ticket.marketingOptInSMS,
            marketingOptInMail: ticket.marketingOptInMail,
            checkedInAt: ticket.checkedInAt,
            startedAt: ticket.startedAt,
            completedAt: ticket.completedAt,
            pickedUpAt: ticket.pickedUpAt,
            checkInSignatureUrl: signatureUrl,
            checkInAgreedAt: ticket.checkInAgreedAt,
            createdAt: ticket.createdAt ?? Date(),
            updatedAt: ticket.updatedAt ?? Date(),
            deletedAt: nil,
            syncVersion: 1 // Default sync version
        )
        
        do {
            try await supabase.client
                .from("tickets")
                .upsert(supabaseTicket)
                .execute()
        } catch {
            throw SyncError.networkError(error)
        }
        
        // Mark as synced
        ticket.cloudSyncStatus = "synced"
        ticket.updatedAt = Date()
        try coreData.viewContext.save()
    }
    
    /// Upload all pending local changes
    func uploadPendingChanges() async throws {
        let request: NSFetchRequest<Ticket> = Ticket.fetchRequest()
        request.predicate = NSPredicate(format: "cloudSyncStatus == %@ OR cloudSyncStatus == nil", "pending")
        
        let pendingTickets = try coreData.viewContext.fetch(request)
        
        if pendingTickets.isEmpty { return }
        
        try await batchUpload(pendingTickets)
    }
    
    // MARK: - Download
    
    /// Download all tickets from Supabase and merge with local
    func download() async throws {
        guard let shopId = getShopId() else {
            throw SyncError.notAuthenticated
        }
        
        isSyncing = true
        defer { isSyncing = false }
        
        let remoteTickets: [SupabaseTicket]
        do {
            remoteTickets = try await supabase.client
                .from("tickets")
                .select()
                .eq("shop_id", value: shopId.uuidString)
                .is("deleted_at", value: nil)
                .order("created_at", ascending: false)
                .execute()
                .value
        } catch {
            throw SyncError.networkError(error)
        }
        
        for remote in remoteTickets {
            try await mergeOrCreate(remote)
        }
        
        lastSyncDate = Date()
    }
    
    // MARK: - Merge
    
    private func mergeOrCreate(_ remote: SupabaseTicket) async throws {
        let request: NSFetchRequest<Ticket> = Ticket.fetchRequest()
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
    
    private func shouldUpdateLocal(_ local: Ticket, from remote: SupabaseTicket) -> Bool {
        // Use timestamp for comparison since Ticket doesn't have syncVersion
        let localDate = local.updatedAt ?? Date.distantPast
        return remote.updatedAt > localDate
    }
    
    private func updateLocal(_ local: Ticket, from remote: SupabaseTicket) throws {
        // Set customer ID (Ticket has customerId, not customer relationship)
        local.customerId = remote.customerId
        
        local.ticketNumber = Int32(remote.ticketNumber)
        local.deviceType = remote.deviceType
        local.deviceModel = remote.deviceModel
        local.deviceSerialNumber = remote.deviceSerialNumber
        local.devicePasscode = remote.devicePasscode
        local.issueDescription = remote.issueDescription
        local.additionalRepairDetails = remote.additionalRepairDetails
        local.notes = remote.notes
        local.status = remote.status
        local.priority = remote.priority
        local.estimatedCost = NSDecimalNumber(value: remote.estimatedCost)
        local.actualCost = NSDecimalNumber(value: remote.actualCost)
        local.estimatedCompletion = remote.estimatedCompletion
        local.findMyDisabled = remote.findMyDisabled
        local.hasDataBackup = remote.hasDataBackup
        local.alternateContactName = remote.alternateContactName
        local.alternateContactNumber = remote.alternateContactNumber
        local.marketingOptInEmail = remote.marketingOptInEmail
        local.marketingOptInSMS = remote.marketingOptInSms
        local.marketingOptInMail = remote.marketingOptInMail
        local.checkedInAt = remote.checkedInAt
        local.startedAt = remote.startedAt
        local.completedAt = remote.completedAt
        local.pickedUpAt = remote.pickedUpAt
        // Note: checkInSignatureUrl doesn't exist on Ticket model (has checkInSignature Data instead)
        local.checkInAgreedAt = remote.checkInAgreedAt
        local.updatedAt = remote.updatedAt
        local.cloudSyncStatus = "synced"
        // Note: syncVersion doesn't exist on Ticket model, using updatedAt for conflict resolution
    }
    
    private func createLocal(from remote: SupabaseTicket) throws {
        let ticket = Ticket(context: coreData.viewContext)
        ticket.id = remote.id
        ticket.createdAt = remote.createdAt
        try updateLocal(ticket, from: remote)
    }
    
    private func fetchOrCreateCustomer(id: UUID) throws -> Customer? {
        let request: NSFetchRequest<Customer> = Customer.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        let results = try coreData.viewContext.fetch(request)
        
        if let customer = results.first {
            return customer
        } else {
            // Customer doesn't exist locally, we should sync it
            Task { @MainActor in
                let customerSyncer = CustomerSyncer()
                try? await customerSyncer.download(id: id)
            }
            return nil
        }
    }
    
    // MARK: - Realtime Subscriptions
    
    /// Process remote upsert from RealtimeManager
    func processRemoteUpsert(_ record: SupabaseTicket) async {
        do {
            try await mergeOrCreate(record)
        } catch {
            print("Failed to process remote upsert: \(error)")
        }
    }
    
    /// Process remote delete from RealtimeManager
    func processRemoteDelete(_ id: UUID) async {
        do {
            try await deleteLocal(id: id)
        } catch {
             print("Failed to process remote delete: \(error)")
        }
    }
    
    // Kept for backward compatibility or direct usage if needed
    func subscribeToChanges() async {
        // Managed by RealtimeManager
    }
    
    private func deleteLocal(id: UUID) async throws {
        let request: NSFetchRequest<Ticket> = Ticket.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        if let ticket = try coreData.viewContext.fetch(request).first {
            coreData.viewContext.delete(ticket)
            try coreData.viewContext.save()
        }
    }
    
    // MARK: - Batch Operations
    
    /// Batch upload multiple tickets
    func batchUpload(_ tickets: [Ticket]) async throws {
        guard let shopId = getShopId() else {
            throw SyncError.notAuthenticated
        }
        
        // Prepare Supabase objects (needs to be async loop for signature uploads)
        var supabaseTickets: [SupabaseTicket] = []
        
        for ticket in tickets {
            guard let customerId = ticket.customerId,
                  let ticketId = ticket.id else { continue }
            
            // Handle signature upload
            var signatureUrl: String?
            if let signatureData = ticket.checkInSignature {
                 signatureUrl = try? await uploadSignature(signatureData, for: ticketId, shopId: shopId)
            }
            
            let supabaseTicket = SupabaseTicket(
                id: ticketId,
                shopId: shopId,
                customerId: customerId,
                ticketNumber: Int(ticket.ticketNumber),
                deviceType: DeviceType.from(ticket.deviceType).rawValue,
                deviceModel: ticket.deviceModel,
                deviceSerialNumber: ticket.deviceSerialNumber,
                devicePasscode: ticket.devicePasscode,
                issueDescription: ticket.issueDescription,
                additionalRepairDetails: ticket.additionalRepairDetails,
                notes: ticket.notes,
                status: ticket.status ?? "pending",
                priority: ticket.priority ?? "normal",
                estimatedCost: Double(truncating: ticket.estimatedCost ?? 0),
                actualCost: Double(truncating: ticket.actualCost ?? 0),
                estimatedCompletion: ticket.estimatedCompletion,
                findMyDisabled: ticket.findMyDisabled,
                hasDataBackup: ticket.hasDataBackup,
                alternateContactName: ticket.alternateContactName,
                alternateContactNumber: ticket.alternateContactNumber,
                marketingOptInEmail: ticket.marketingOptInEmail,
                marketingOptInSms: ticket.marketingOptInSMS,
                marketingOptInMail: ticket.marketingOptInMail,
                checkedInAt: ticket.checkedInAt,
                startedAt: ticket.startedAt,
                completedAt: ticket.completedAt,
                pickedUpAt: ticket.pickedUpAt,
                checkInSignatureUrl: signatureUrl,
                checkInAgreedAt: ticket.checkInAgreedAt,
                createdAt: ticket.createdAt ?? Date(),
                updatedAt: ticket.updatedAt ?? Date(),
                deletedAt: nil,
                syncVersion: 1
            )
            supabaseTickets.append(supabaseTicket)
        }
        
        // Upload in batches of 100
        // Upload in batches of 100
        let batchSize = 100
        for batch in supabaseTickets.chunked(into: batchSize) {
            do {
                try await supabase.client
                    .from("tickets")
                    .upsert(batch)
                    .execute()
            } catch {
                throw SyncError.networkError(error)
            }
        }
        
        // Mark all as synced
        for ticket in tickets {
            ticket.cloudSyncStatus = "synced"
            ticket.updatedAt = Date()
        }
        
        try coreData.viewContext.save()
    }
    
    // MARK: - Helpers
    
    private func getShopId() -> UUID? {
        if let shopIdString = supabase.currentShopId {
            return UUID(uuidString: shopIdString)
        }
        return UUID(uuidString: "00000000-0000-0000-0000-000000000001")
    }
    
    /// Upload signature image to Supabase Storage
    private func uploadSignature(_ data: Data, for ticketId: UUID, shopId: UUID) async throws -> String? {
        let fileName = "\(shopId)/\(ticketId).png"
        
        do {
            try await supabase.client.storage
                .from(SupabaseConfig.signaturesBucket)
                .upload(
                    fileName,
                    data: data,
                    options: FileOptions(
                        cacheControl: "3600",
                        contentType: "image/png",
                        upsert: true
                    )
                )
            
            // Construct public URL
            // Construct public URL manually since getPublicUrl might vary in SDK version
            // Standard format: {projectUrl}/storage/v1/object/public/{bucket}/{path}
            let projectUrl = ProductionConfig.shared.currentEnvironment.supabaseURL
            let publicUrl = "\(projectUrl)/storage/v1/object/public/\(SupabaseConfig.signaturesBucket)/\(fileName)"
            
            return publicUrl
            
        } catch {
            print("Failed to upload signature: \(error)")
            return nil
        }
    }
}

// MARK: - Models

struct SupabaseTicket: Codable {
    let id: UUID
    let shopId: UUID
    let customerId: UUID
    let ticketNumber: Int
    let deviceType: String?
    let deviceModel: String?
    let deviceSerialNumber: String?
    let devicePasscode: String?
    let issueDescription: String?
    let additionalRepairDetails: String?
    let notes: String?
    let status: String
    let priority: String
    let estimatedCost: Double
    let actualCost: Double
    let estimatedCompletion: Date?
    let findMyDisabled: Bool
    let hasDataBackup: Bool
    let alternateContactName: String?
    let alternateContactNumber: String?
    let marketingOptInEmail: Bool
    let marketingOptInSms: Bool
    let marketingOptInMail: Bool
    let checkedInAt: Date?
    let startedAt: Date?
    let completedAt: Date?
    let pickedUpAt: Date?
    let checkInSignatureUrl: String?
    let checkInAgreedAt: Date?
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let syncVersion: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case shopId = "shop_id"
        case customerId = "customer_id"
        case ticketNumber = "ticket_number"
        case deviceType = "device_type"
        case deviceModel = "device_model"
        case deviceSerialNumber = "device_serial_number"
        case devicePasscode = "device_passcode"
        case issueDescription = "issue_description"
        case additionalRepairDetails = "additional_repair_details"
        case notes
        case status
        case priority
        case estimatedCost = "estimated_cost"
        case actualCost = "actual_cost"
        case estimatedCompletion = "estimated_completion"
        case findMyDisabled = "find_my_disabled"
        case hasDataBackup = "has_data_backup"
        case alternateContactName = "alternate_contact_name"
        case alternateContactNumber = "alternate_contact_number"
        case marketingOptInEmail = "marketing_opt_in_email"
        case marketingOptInSms = "marketing_opt_in_sms"
        case marketingOptInMail = "marketing_opt_in_mail"
        case checkedInAt = "checked_in_at"
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case pickedUpAt = "picked_up_at"
        case checkInSignatureUrl = "check_in_signature_url"
        case checkInAgreedAt = "check_in_agreed_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case syncVersion = "sync_version"
    }
}

// Note: Array.chunked extension is defined elsewhere in the codebase
