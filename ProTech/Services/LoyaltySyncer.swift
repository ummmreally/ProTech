//
//  LoyaltySyncer.swift
//  ProTech
//
//  Handles bidirectional sync between Core Data and Supabase for loyalty program
//

import Foundation
import CoreData
import Supabase

// MARK: - Supabase Models

struct SupabaseLoyaltyProgram: Codable {
    let id: UUID
    let shopId: UUID
    let name: String
    let isActive: Bool
    let pointsPerDollar: Double
    let pointsPerVisit: Int
    let enableTiers: Bool
    let enableAutoNotifications: Bool
    let pointsExpirationDays: Int
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case shopId = "shop_id"
        case isActive = "is_active"
        case pointsPerDollar = "points_per_dollar"
        case pointsPerVisit = "points_per_visit"
        case enableTiers = "enable_tiers"
        case enableAutoNotifications = "enable_auto_notifications"
        case pointsExpirationDays = "points_expiration_days"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct SupabaseLoyaltyTier: Codable {
    let id: UUID
    let programId: UUID
    let shopId: UUID
    let name: String
    let pointsRequired: Int
    let pointsMultiplier: Double
    let color: String?
    let sortOrder: Int
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, name, color
        case programId = "program_id"
        case shopId = "shop_id"
        case pointsRequired = "points_required"
        case pointsMultiplier = "points_multiplier"
        case sortOrder = "sort_order"
        case createdAt = "created_at"
    }
}

struct SupabaseLoyaltyMember: Codable {
    let id: UUID
    let customerId: UUID
    let programId: UUID
    let shopId: UUID
    let currentTierId: UUID?
    let totalPoints: Int
    let availablePoints: Int
    let lifetimePoints: Int
    let visitCount: Int
    let totalSpent: Double
    let isActive: Bool
    let enrolledAt: Date
    let lastActivityAt: Date?
    let createdAt: Date
    let updatedAt: Date
    let syncVersion: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case customerId = "customer_id"
        case programId = "program_id"
        case shopId = "shop_id"
        case currentTierId = "current_tier_id"
        case totalPoints = "total_points"
        case availablePoints = "available_points"
        case lifetimePoints = "lifetime_points"
        case visitCount = "visit_count"
        case totalSpent = "total_spent"
        case isActive = "is_active"
        case enrolledAt = "enrolled_at"
        case lastActivityAt = "last_activity_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case syncVersion = "sync_version"
    }
}

struct SupabaseLoyaltyReward: Codable {
    let id: UUID
    let programId: UUID
    let shopId: UUID
    let name: String
    let description: String?
    let pointsCost: Int
    let rewardType: String
    let rewardValue: Double
    let isActive: Bool
    let maxRedemptionsPerCustomer: Int?
    let validFrom: Date?
    let validUntil: Date?
    let sortOrder: Int
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, name, description
        case programId = "program_id"
        case shopId = "shop_id"
        case pointsCost = "points_cost"
        case rewardType = "reward_type"
        case rewardValue = "reward_value"
        case isActive = "is_active"
        case maxRedemptionsPerCustomer = "max_redemptions_per_customer"
        case validFrom = "valid_from"
        case validUntil = "valid_until"
        case sortOrder = "sort_order"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct SupabaseLoyaltyTransaction: Codable {
    let id: UUID
    let memberId: UUID
    let shopId: UUID
    let type: String
    let points: Int
    let description: String?
    let relatedInvoiceId: UUID?
    let relatedRewardId: UUID?
    let expiresAt: Date?
    let createdAt: Date
    let createdBy: UUID?
    
    enum CodingKeys: String, CodingKey {
        case id, type, points, description
        case memberId = "member_id"
        case shopId = "shop_id"
        case relatedInvoiceId = "related_invoice_id"
        case relatedRewardId = "related_reward_id"
        case expiresAt = "expires_at"
        case createdAt = "created_at"
        case createdBy = "created_by"
    }
}

// MARK: - Syncer

@MainActor
class LoyaltySyncer: ObservableObject {
    private let supabase = SupabaseService.shared
    private let coreData = CoreDataManager.shared
    
    @Published var isSyncing = false
    @Published var syncError: Error?
    @Published var lastSyncDate: Date?
    
    // MARK: - Full Sync
    
    /// Sync all loyalty entities bidirectionally
    func syncAll() async throws {
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            try await syncPrograms()
            try await syncTiers()
            try await syncRewards()
            try await syncMembers()
            try await syncTransactions()
            
            lastSyncDate = Date()
        } catch {
            syncError = error
            throw error
        }
    }
    
    // MARK: - Program Sync
    
    private func syncPrograms() async throws {
        guard let shopId = getShopId() else {
            throw SyncError.notAuthenticated
        }
        
        // Download from Supabase
        let remotePrograms: [SupabaseLoyaltyProgram] = try await supabase.client
            .from("loyalty_programs")
            .select()
            .eq("shop_id", value: shopId.uuidString)
            .execute()
            .value
        
        // Merge with local
        for remote in remotePrograms {
            try await mergeOrCreateProgram(remote)
        }
        
        // Upload local changes
        let request: NSFetchRequest<LoyaltyProgram> = LoyaltyProgram.fetchRequest()
        let localPrograms = try coreData.viewContext.fetch(request)
        
        for local in localPrograms {
            try await uploadProgram(local)
        }
    }
    
    private func uploadProgram(_ program: LoyaltyProgram) async throws {
        guard let shopId = getShopId(),
              let programId = program.id else {
            throw SyncError.conflict(details: "Missing program ID")
        }
        
        let supabaseProgram = SupabaseLoyaltyProgram(
            id: programId,
            shopId: shopId,
            name: program.name ?? "Rewards Program",
            isActive: program.isActive,
            pointsPerDollar: program.pointsPerDollar,
            pointsPerVisit: Int(program.pointsPerVisit),
            enableTiers: program.enableTiers,
            enableAutoNotifications: program.enableAutoNotifications,
            pointsExpirationDays: Int(program.pointsExpirationDays),
            createdAt: program.createdAt ?? Date(),
            updatedAt: program.updatedAt ?? Date()
        )
        
        try await supabase.client
            .from("loyalty_programs")
            .upsert(supabaseProgram)
            .execute()
    }
    
    private func mergeOrCreateProgram(_ remote: SupabaseLoyaltyProgram) async throws {
        let request: NSFetchRequest<LoyaltyProgram> = LoyaltyProgram.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", remote.id as CVarArg)
        request.fetchLimit = 1
        
        let local = try coreData.viewContext.fetch(request).first
        
        let program = local ?? LoyaltyProgram(context: coreData.viewContext)
        program.id = remote.id
        program.name = remote.name
        program.isActive = remote.isActive
        program.pointsPerDollar = remote.pointsPerDollar
        program.pointsPerVisit = Int32(remote.pointsPerVisit)
        program.enableTiers = remote.enableTiers
        program.enableAutoNotifications = remote.enableAutoNotifications
        program.pointsExpirationDays = Int32(remote.pointsExpirationDays)
        program.createdAt = remote.createdAt
        program.updatedAt = remote.updatedAt
        
        try coreData.viewContext.save()
    }
    
    // MARK: - Tier Sync
    
    private func syncTiers() async throws {
        guard let shopId = getShopId() else {
            throw SyncError.notAuthenticated
        }
        
        let remoteTiers: [SupabaseLoyaltyTier] = try await supabase.client
            .from("loyalty_tiers")
            .select()
            .eq("shop_id", value: shopId.uuidString)
            .execute()
            .value
        
        for remote in remoteTiers {
            try await mergeOrCreateTier(remote)
        }
        
        // Upload local tiers
        let request: NSFetchRequest<LoyaltyTier> = LoyaltyTier.fetchRequest()
        let localTiers = try coreData.viewContext.fetch(request)
        
        for local in localTiers {
            try await uploadTier(local)
        }
    }
    
    private func uploadTier(_ tier: LoyaltyTier) async throws {
        guard let shopId = getShopId(),
              let tierId = tier.id,
              let programId = tier.programId else {
            throw SyncError.conflict(details: "Missing tier data")
        }
        
        let supabaseTier = SupabaseLoyaltyTier(
            id: tierId,
            programId: programId,
            shopId: shopId,
            name: tier.name ?? "Tier",
            pointsRequired: Int(tier.pointsRequired),
            pointsMultiplier: tier.pointsMultiplier,
            color: tier.color,
            sortOrder: Int(tier.sortOrder),
            createdAt: tier.createdAt ?? Date()
        )
        
        try await supabase.client
            .from("loyalty_tiers")
            .upsert(supabaseTier)
            .execute()
    }
    
    private func mergeOrCreateTier(_ remote: SupabaseLoyaltyTier) async throws {
        let request: NSFetchRequest<LoyaltyTier> = LoyaltyTier.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", remote.id as CVarArg)
        request.fetchLimit = 1
        
        let local = try coreData.viewContext.fetch(request).first
        
        let tier = local ?? LoyaltyTier(context: coreData.viewContext)
        tier.id = remote.id
        tier.programId = remote.programId
        tier.name = remote.name
        tier.pointsRequired = Int32(remote.pointsRequired)
        tier.pointsMultiplier = remote.pointsMultiplier
        tier.color = remote.color
        tier.sortOrder = Int16(remote.sortOrder)
        tier.createdAt = remote.createdAt
        
        try coreData.viewContext.save()
    }
    
    // MARK: - Member Sync
    
    private func syncMembers() async throws {
        guard let shopId = getShopId() else {
            throw SyncError.notAuthenticated
        }
        
        let remoteMembers: [SupabaseLoyaltyMember] = try await supabase.client
            .from("loyalty_members")
            .select()
            .eq("shop_id", value: shopId.uuidString)
            .execute()
            .value
        
        for remote in remoteMembers {
            try await mergeOrCreateMember(remote)
        }
        
        // Upload local members
        let request: NSFetchRequest<LoyaltyMember> = LoyaltyMember.fetchRequest()
        let localMembers = try coreData.viewContext.fetch(request)
        
        for local in localMembers {
            try await uploadMember(local)
        }
    }
    
    private func uploadMember(_ member: LoyaltyMember) async throws {
        guard let shopId = getShopId(),
              let memberId = member.id,
              let customerId = member.customerId,
              let programId = member.programId else {
            throw SyncError.conflict(details: "Missing member data")
        }
        
        let supabaseMember = SupabaseLoyaltyMember(
            id: memberId,
            customerId: customerId,
            programId: programId,
            shopId: shopId,
            currentTierId: member.currentTierId,
            totalPoints: Int(member.totalPoints),
            availablePoints: Int(member.availablePoints),
            lifetimePoints: Int(member.lifetimePoints),
            visitCount: Int(member.visitCount),
            totalSpent: member.totalSpent,
            isActive: member.isActive,
            enrolledAt: member.enrolledAt ?? Date(),
            lastActivityAt: member.lastActivityAt,
            createdAt: Date(),
            updatedAt: Date(),
            syncVersion: 1
        )
        
        try await supabase.client
            .from("loyalty_members")
            .upsert(supabaseMember)
            .execute()
    }
    
    private func mergeOrCreateMember(_ remote: SupabaseLoyaltyMember) async throws {
        let request: NSFetchRequest<LoyaltyMember> = LoyaltyMember.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", remote.id as CVarArg)
        request.fetchLimit = 1
        
        let local = try coreData.viewContext.fetch(request).first
        
        let member = local ?? LoyaltyMember(context: coreData.viewContext)
        member.id = remote.id
        member.customerId = remote.customerId
        member.programId = remote.programId
        member.currentTierId = remote.currentTierId
        member.totalPoints = Int32(remote.totalPoints)
        member.availablePoints = Int32(remote.availablePoints)
        member.lifetimePoints = Int32(remote.lifetimePoints)
        member.visitCount = Int32(remote.visitCount)
        member.totalSpent = remote.totalSpent
        member.isActive = remote.isActive
        member.enrolledAt = remote.enrolledAt
        member.lastActivityAt = remote.lastActivityAt
        
        try coreData.viewContext.save()
    }
    
    // MARK: - Reward Sync
    
    private func syncRewards() async throws {
        guard let shopId = getShopId() else {
            throw SyncError.notAuthenticated
        }
        
        let remoteRewards: [SupabaseLoyaltyReward] = try await supabase.client
            .from("loyalty_rewards")
            .select()
            .eq("shop_id", value: shopId.uuidString)
            .execute()
            .value
        
        for remote in remoteRewards {
            try await mergeOrCreateReward(remote)
        }
        
        // Upload local rewards
        let request: NSFetchRequest<LoyaltyReward> = LoyaltyReward.fetchRequest()
        let localRewards = try coreData.viewContext.fetch(request)
        
        for local in localRewards {
            try await uploadReward(local)
        }
    }
    
    private func uploadReward(_ reward: LoyaltyReward) async throws {
        guard let shopId = getShopId(),
              let rewardId = reward.id,
              let programId = reward.programId else {
            throw SyncError.conflict(details: "Missing reward data")
        }
        
        let supabaseReward = SupabaseLoyaltyReward(
            id: rewardId,
            programId: programId,
            shopId: shopId,
            name: reward.name ?? "Reward",
            description: reward.description_,
            pointsCost: Int(reward.pointsCost),
            rewardType: reward.rewardType ?? "custom",
            rewardValue: reward.rewardValue,
            isActive: reward.isActive,
            maxRedemptionsPerCustomer: nil,
            validFrom: nil,
            validUntil: nil,
            sortOrder: Int(reward.sortOrder),
            createdAt: reward.createdAt ?? Date(),
            updatedAt: reward.updatedAt ?? Date()
        )
        
        try await supabase.client
            .from("loyalty_rewards")
            .upsert(supabaseReward)
            .execute()
    }
    
    private func mergeOrCreateReward(_ remote: SupabaseLoyaltyReward) async throws {
        let request: NSFetchRequest<LoyaltyReward> = LoyaltyReward.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", remote.id as CVarArg)
        request.fetchLimit = 1
        
        let local = try coreData.viewContext.fetch(request).first
        
        let reward = local ?? LoyaltyReward(context: coreData.viewContext)
        reward.id = remote.id
        reward.programId = remote.programId
        reward.name = remote.name
        reward.description_ = remote.description
        reward.pointsCost = Int32(remote.pointsCost)
        reward.rewardType = remote.rewardType
        reward.rewardValue = remote.rewardValue
        reward.isActive = remote.isActive
        reward.sortOrder = Int16(remote.sortOrder)
        reward.createdAt = remote.createdAt
        reward.updatedAt = remote.updatedAt
        
        try coreData.viewContext.save()
    }
    
    // MARK: - Transaction Sync
    
    private func syncTransactions() async throws {
        guard let shopId = getShopId() else {
            throw SyncError.notAuthenticated
        }
        
        // Only download recent transactions (last 90 days)
        let ninetyDaysAgo = Calendar.current.date(byAdding: .day, value: -90, to: Date())!
        
        let remoteTransactions: [SupabaseLoyaltyTransaction] = try await supabase.client
            .from("loyalty_transactions")
            .select()
            .eq("shop_id", value: shopId.uuidString)
            .gte("created_at", value: ninetyDaysAgo.ISO8601Format())
            .execute()
            .value
        
        for remote in remoteTransactions {
            try await mergeOrCreateTransaction(remote)
        }
        
        // Upload local transactions
        let request: NSFetchRequest<LoyaltyTransaction> = LoyaltyTransaction.fetchRequest()
        request.predicate = NSPredicate(format: "createdAt >= %@", ninetyDaysAgo as NSDate)
        let localTransactions = try coreData.viewContext.fetch(request)
        
        for local in localTransactions {
            try await uploadTransaction(local)
        }
    }
    
    private func uploadTransaction(_ transaction: LoyaltyTransaction) async throws {
        guard let shopId = getShopId(),
              let transactionId = transaction.id,
              let memberId = transaction.memberId else {
            throw SyncError.conflict(details: "Missing transaction data")
        }
        
        let supabaseTransaction = SupabaseLoyaltyTransaction(
            id: transactionId,
            memberId: memberId,
            shopId: shopId,
            type: transaction.type ?? "earned",
            points: Int(transaction.points),
            description: transaction.description_,
            relatedInvoiceId: transaction.relatedInvoiceId,
            relatedRewardId: transaction.relatedRewardId,
            expiresAt: transaction.expiresAt,
            createdAt: transaction.createdAt ?? Date(),
            createdBy: nil
        )
        
        try await supabase.client
            .from("loyalty_transactions")
            .upsert(supabaseTransaction)
            .execute()
    }
    
    private func mergeOrCreateTransaction(_ remote: SupabaseLoyaltyTransaction) async throws {
        let request: NSFetchRequest<LoyaltyTransaction> = LoyaltyTransaction.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", remote.id as CVarArg)
        request.fetchLimit = 1
        
        let local = try coreData.viewContext.fetch(request).first
        
        // Don't overwrite existing transactions
        guard local == nil else { return }
        
        let transaction = LoyaltyTransaction(context: coreData.viewContext)
        transaction.id = remote.id
        transaction.memberId = remote.memberId
        transaction.type = remote.type
        transaction.points = Int32(remote.points)
        transaction.description_ = remote.description
        transaction.relatedInvoiceId = remote.relatedInvoiceId
        transaction.relatedRewardId = remote.relatedRewardId
        transaction.expiresAt = remote.expiresAt
        transaction.createdAt = remote.createdAt
        
        try coreData.viewContext.save()
    }
    
    // MARK: - Helpers
    
    private func getShopId() -> UUID? {
        guard let shopIdString = SupabaseService.shared.currentShopId else {
            return nil
        }
        return UUID(uuidString: shopIdString)
    }
}

// MARK: - Sync Error
// Note: SyncError is now defined in Models/SyncErrors.swift
