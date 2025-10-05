//
//  LoyaltyService.swift
//  ProTech
//
//  Service for managing loyalty program operations
//

import Foundation
import CoreData

class LoyaltyService {
    static let shared = LoyaltyService()
    private let context = CoreDataManager.shared.viewContext
    
    private init() {}
    
    // MARK: - Program Management
    
    func getActiveProgram() -> LoyaltyProgram? {
        let request: NSFetchRequest<LoyaltyProgram> = LoyaltyProgram.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == true")
        request.fetchLimit = 1
        
        return try? context.fetch(request).first
    }
    
    func createDefaultProgram() -> LoyaltyProgram {
        let program = LoyaltyProgram(context: context)
        program.id = UUID()
        program.name = "ProTech Rewards"
        program.isActive = true
        program.pointsPerDollar = 1.0
        program.pointsPerVisit = 10
        program.enableTiers = true
        program.enableAutoNotifications = true
        program.pointsExpirationDays = 0
        program.createdAt = Date()
        program.updatedAt = Date()
        
        CoreDataManager.shared.save()
        
        // Create default tiers
        createDefaultTiers(for: program)
        
        // Create default rewards
        createDefaultRewards(for: program)
        
        return program
    }
    
    private func createDefaultTiers(for program: LoyaltyProgram) {
        guard let programId = program.id else { return }
        
        let tiers = [
            ("Bronze", 0, 1.0, "CD7F32"),
            ("Silver", 500, 1.5, "C0C0C0"),
            ("Gold", 1500, 2.0, "FFD700"),
            ("Platinum", 3000, 3.0, "E5E4E2")
        ]
        
        for (index, tierData) in tiers.enumerated() {
            let tier = LoyaltyTier(context: context)
            tier.id = UUID()
            tier.programId = programId
            tier.name = tierData.0
            tier.pointsRequired = Int32(tierData.1)
            tier.pointsMultiplier = tierData.2
            tier.color = tierData.3
            tier.sortOrder = Int16(index)
            tier.createdAt = Date()
        }
        
        CoreDataManager.shared.save()
    }
    
    private func createDefaultRewards(for program: LoyaltyProgram) {
        guard let programId = program.id else { return }
        
        let rewards = [
            ("$5 Off Service", "Get $5 off your next repair", 100, "discount_amount", 5.0),
            ("10% Off Parts", "Save 10% on parts for your next repair", 250, "discount_percent", 10.0),
            ("$15 Off Service", "Get $15 off your next repair", 500, "discount_amount", 15.0),
            ("20% Off Entire Service", "Save 20% on your entire service", 1000, "discount_percent", 20.0),
            ("Free Screen Protector", "Get a free screen protector with service", 300, "free_item", 0.0)
        ]
        
        for (index, rewardData) in rewards.enumerated() {
            let reward = LoyaltyReward(context: context)
            reward.id = UUID()
            reward.programId = programId
            reward.name = rewardData.0
            reward.description_ = rewardData.1
            reward.pointsCost = Int32(rewardData.2)
            reward.rewardType = rewardData.3
            reward.rewardValue = rewardData.4
            reward.isActive = true
            reward.sortOrder = Int16(index)
            reward.createdAt = Date()
            reward.updatedAt = Date()
        }
        
        CoreDataManager.shared.save()
    }
    
    // MARK: - Member Management
    
    func enrollCustomer(_ customerId: UUID) -> LoyaltyMember? {
        // Check if already enrolled
        if let existing = getMember(for: customerId) {
            return existing
        }
        
        guard let program = getActiveProgram(),
              let programId = program.id else {
            return nil
        }
        
        let member = LoyaltyMember(context: context)
        member.id = UUID()
        member.customerId = customerId
        member.programId = programId
        member.totalPoints = 0
        member.availablePoints = 0
        member.lifetimePoints = 0
        member.visitCount = 0
        member.totalSpent = 0.0
        member.enrolledAt = Date()
        member.isActive = true
        
        // Assign to first tier
        if let firstTier = getTiers(for: programId).first {
            member.currentTierId = firstTier.id
        }
        
        CoreDataManager.shared.save()
        
        return member
    }
    
    func getMember(for customerId: UUID) -> LoyaltyMember? {
        let request: NSFetchRequest<LoyaltyMember> = LoyaltyMember.fetchRequest()
        request.predicate = NSPredicate(format: "customerId == %@ AND isActive == true", customerId as CVarArg)
        request.fetchLimit = 1
        
        return try? context.fetch(request).first
    }
    
    // MARK: - Points Management
    
    func awardPointsForPurchase(customerId: UUID, amount: Double, invoiceId: UUID? = nil) {
        guard let member = getMember(for: customerId) ?? enrollCustomer(customerId),
              let program = getActiveProgram() else {
            return
        }
        
        // Calculate base points
        var pointsToAward = Int32(amount * program.pointsPerDollar)
        
        // Apply tier multiplier
        if let tierId = member.currentTierId,
           let tier = getTier(tierId) {
            pointsToAward = Int32(Double(pointsToAward) * tier.pointsMultiplier)
        }
        
        // Add visit bonus
        pointsToAward += program.pointsPerVisit
        
        // Create transaction
        let transaction = LoyaltyTransaction(context: context)
        transaction.id = UUID()
        transaction.memberId = member.id
        transaction.type = "earned"
        transaction.points = pointsToAward
        transaction.description_ = "Purchase of $\(String(format: "%.2f", amount))"
        transaction.relatedInvoiceId = invoiceId
        transaction.createdAt = Date()
        
        // Set expiration if configured
        if program.pointsExpirationDays > 0 {
            transaction.expiresAt = Calendar.current.date(byAdding: .day, value: Int(program.pointsExpirationDays), to: Date())
        }
        
        // Update member
        member.totalPoints += pointsToAward
        member.availablePoints += pointsToAward
        member.lifetimePoints += pointsToAward
        member.visitCount += 1
        member.totalSpent += amount
        member.lastActivityAt = Date()
        
        CoreDataManager.shared.save()
        
        // Check for tier upgrade
        checkAndUpdateTier(for: member)
        
        // Send notification if enabled
        if program.enableAutoNotifications {
            sendPointsEarnedNotification(member: member, points: pointsToAward)
        }
    }
    
    func redeemReward(memberId: UUID, rewardId: UUID) -> Bool {
        guard let member = getMember(memberId: memberId),
              let reward = getReward(rewardId) else {
            return false
        }
        
        // Check if member has enough points
        guard member.availablePoints >= reward.pointsCost else {
            return false
        }
        
        // Create redemption transaction
        let transaction = LoyaltyTransaction(context: context)
        transaction.id = UUID()
        transaction.memberId = memberId
        transaction.type = "redeemed"
        transaction.points = -reward.pointsCost // Negative for redemption
        transaction.description_ = "Redeemed: \(reward.name ?? "Reward")"
        transaction.relatedRewardId = rewardId
        transaction.createdAt = Date()
        
        // Update member points
        member.availablePoints -= reward.pointsCost
        member.lastActivityAt = Date()
        
        CoreDataManager.shared.save()
        
        // Send notification
        if let program = getActiveProgram(), program.enableAutoNotifications {
            sendRewardRedeemedNotification(member: member, reward: reward)
        }
        
        return true
    }
    
    private func getMember(memberId: UUID) -> LoyaltyMember? {
        let request: NSFetchRequest<LoyaltyMember> = LoyaltyMember.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", memberId as CVarArg)
        request.fetchLimit = 1
        
        return try? context.fetch(request).first
    }
    
    // MARK: - Tier Management
    
    func getTiers(for programId: UUID) -> [LoyaltyTier] {
        let request: NSFetchRequest<LoyaltyTier> = LoyaltyTier.fetchRequest()
        request.predicate = NSPredicate(format: "programId == %@", programId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \LoyaltyTier.sortOrder, ascending: true)]
        
        return (try? context.fetch(request)) ?? []
    }
    
    func getTier(_ tierId: UUID) -> LoyaltyTier? {
        let request: NSFetchRequest<LoyaltyTier> = LoyaltyTier.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", tierId as CVarArg)
        request.fetchLimit = 1
        
        return try? context.fetch(request).first
    }
    
    func checkAndUpdateTier(for member: LoyaltyMember) {
        guard let programId = member.programId else { return }
        
        let tiers = getTiers(for: programId).sorted { $0.pointsRequired > $1.pointsRequired }
        
        for tier in tiers {
            if member.lifetimePoints >= tier.pointsRequired {
                if member.currentTierId != tier.id {
                    member.currentTierId = tier.id
                    CoreDataManager.shared.save()
                    
                    // Send tier upgrade notification
                    if let program = getActiveProgram(), program.enableAutoNotifications {
                        sendTierUpgradeNotification(member: member, tier: tier)
                    }
                }
                break
            }
        }
    }
    
    // MARK: - Rewards Management
    
    func getActiveRewards(for programId: UUID) -> [LoyaltyReward] {
        let request: NSFetchRequest<LoyaltyReward> = LoyaltyReward.fetchRequest()
        request.predicate = NSPredicate(format: "programId == %@ AND isActive == true", programId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \LoyaltyReward.sortOrder, ascending: true)]
        
        return (try? context.fetch(request)) ?? []
    }
    
    func getReward(_ rewardId: UUID) -> LoyaltyReward? {
        let request: NSFetchRequest<LoyaltyReward> = LoyaltyReward.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", rewardId as CVarArg)
        request.fetchLimit = 1
        
        return try? context.fetch(request).first
    }
    
    func getAvailableRewards(for member: LoyaltyMember) -> [LoyaltyReward] {
        guard let programId = member.programId else { return [] }
        
        return getActiveRewards(for: programId).filter { reward in
            member.availablePoints >= reward.pointsCost
        }
    }
    
    // MARK: - Transaction History
    
    func getTransactions(for memberId: UUID, limit: Int = 50) -> [LoyaltyTransaction] {
        let request: NSFetchRequest<LoyaltyTransaction> = LoyaltyTransaction.fetchRequest()
        request.predicate = NSPredicate(format: "memberId == %@", memberId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \LoyaltyTransaction.createdAt, ascending: false)]
        request.fetchLimit = limit
        
        return (try? context.fetch(request)) ?? []
    }
    
    // MARK: - Analytics
    
    func getTopMembers(limit: Int = 10) -> [LoyaltyMember] {
        let request: NSFetchRequest<LoyaltyMember> = LoyaltyMember.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == true")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \LoyaltyMember.lifetimePoints, ascending: false)]
        request.fetchLimit = limit
        
        return (try? context.fetch(request)) ?? []
    }
    
    func getLoyaltyStats() -> (memberCount: Int, totalPoints: Int, avgPointsPerMember: Double) {
        let request: NSFetchRequest<LoyaltyMember> = LoyaltyMember.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == true")
        
        let members = (try? context.fetch(request)) ?? []
        let memberCount = members.count
        let totalPoints = members.reduce(0) { $0 + Int($1.lifetimePoints) }
        let avgPoints = memberCount > 0 ? Double(totalPoints) / Double(memberCount) : 0.0
        
        return (memberCount, totalPoints, avgPoints)
    }
    
    // MARK: - Notifications
    
    private func sendPointsEarnedNotification(member: LoyaltyMember, points: Int32) {
        // Get customer to send notification
        guard let customer = getCustomer(member.customerId) else { return }
        
        let message = "You earned \(points) points! Your balance: \(member.availablePoints) points"
        
        if TwilioService.shared.isConfigured, let phone = customer.phone {
            Task {
                try? await TwilioService.shared.sendSMS(to: phone, body: message)
            }
        }
    }
    
    private func sendRewardRedeemedNotification(member: LoyaltyMember, reward: LoyaltyReward) {
        guard let customer = getCustomer(member.customerId) else { return }
        
        let message = "You redeemed: \(reward.name ?? "Reward")! Remaining points: \(member.availablePoints)"
        
        if TwilioService.shared.isConfigured, let phone = customer.phone {
            Task {
                try? await TwilioService.shared.sendSMS(to: phone, body: message)
            }
        }
    }
    
    private func sendTierUpgradeNotification(member: LoyaltyMember, tier: LoyaltyTier) {
        guard let customer = getCustomer(member.customerId) else { return }
        
        let multiplierText = tier.pointsMultiplier > 1.0 ? "\(tier.pointsMultiplier)x" : ""
        let message = "Congratulations! You've reached \(tier.name ?? "new") tier! \(multiplierText) points on future visits!"
        
        if TwilioService.shared.isConfigured, let phone = customer.phone {
            Task {
                try? await TwilioService.shared.sendSMS(to: phone, body: message)
            }
        }
    }
    
    private func getCustomer(_ customerId: UUID?) -> Customer? {
        guard let customerId = customerId else { return nil }
        
        let request: NSFetchRequest<Customer> = Customer.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", customerId as CVarArg)
        request.fetchLimit = 1
        
        return try? context.fetch(request).first
    }
}
