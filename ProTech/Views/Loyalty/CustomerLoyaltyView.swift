//
//  CustomerLoyaltyView.swift
//  ProTech
//
//  Customer-facing loyalty dashboard
//

import SwiftUI
import CoreData

struct CustomerLoyaltyView: View {
    let customer: Customer
    @State private var member: LoyaltyMember?
    @State private var tier: LoyaltyTier?
    @State private var availableRewards: [LoyaltyReward] = []
    @State private var allRewards: [LoyaltyReward] = []
    @State private var transactions: [LoyaltyTransaction] = []
    @State private var showingEnrollment = false
    
    var body: some View {
        ScrollView {
            if member != nil {
                VStack(spacing: 24) {
                    // Loyalty card
                    loyaltyCard
                    
                    // Available rewards
                    rewardsSection
                    
                    // Activity
                    activitySection
                }
                .padding()
            } else {
                // Not enrolled
                enrollmentPrompt
            }
        }
        .navigationTitle("Loyalty Rewards")
        .onAppear {
            loadLoyaltyData()
        }
        .sheet(isPresented: $showingEnrollment) {
            EnrollmentView(customer: customer) {
                loadLoyaltyData()
            }
        }
    }
    
    // MARK: - Loyalty Card
    
    private var loyaltyCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [tierColor, tierColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 220)
                .shadow(color: tierColor.opacity(0.5), radius: 15, y: 10)
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ProTech Rewards")
                            .font(.title3)
                            .bold()
                            .foregroundColor(.white)
                        
                        if let tier = tier {
                            Text("\(tier.name ?? "") Member")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white.opacity(0.3))
                }
                
                Spacer()
                
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(member?.availablePoints ?? 0)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Available Points")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        if let tier = tier, tier.pointsMultiplier > 1.0 {
                            Text("\(tier.pointsMultiplier, specifier: "%.1f")x")
                                .font(.title)
                                .bold()
                                .foregroundColor(.white)
                            
                            Text("Points Multiplier")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                }
            }
            .padding(24)
        }
        .frame(height: 220)
    }
    
    // MARK: - Rewards Section
    
    private var rewardsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Available Rewards")
                .font(.title2)
                .bold()
            
            if availableRewards.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "gift")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("Keep earning points to unlock rewards!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 280))], spacing: 16) {
                    ForEach(availableRewards) { reward in
                        CustomerRewardCard(reward: reward, member: member)
                    }
                }
            }
            
            // Show locked rewards
            if !allRewards.isEmpty {
                Divider()
                    .padding(.vertical)
                
                Text("All Rewards")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 280))], spacing: 16) {
                    ForEach(allRewards) { reward in
                        LockedRewardCard(reward: reward, currentPoints: member?.availablePoints ?? 0)
                    }
                }
            }
        }
    }
    
    // MARK: - Activity Section
    
    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Activity")
                    .font(.title2)
                    .bold()
                
                Spacer()
                
                if let member = member {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(member.visitCount) visits")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("$\(member.totalSpent, specifier: "%.2f") total")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if transactions.isEmpty {
                Text("No activity yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(transactions.prefix(10)) { transaction in
                        CustomerTransactionRow(transaction: transaction)
                    }
                }
            }
        }
    }
    
    // MARK: - Enrollment Prompt
    
    private var enrollmentPrompt: some View {
        VStack(spacing: 24) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.linearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
            
            VStack(spacing: 8) {
                Text("Join ProTech Rewards!")
                    .font(.title)
                    .bold()
                
                Text("Earn points on every purchase and unlock exclusive rewards")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                BenefitRow(icon: "dollarsign.circle.fill", text: "Earn points on every dollar spent")
                BenefitRow(icon: "gift.fill", text: "Redeem points for exclusive rewards")
                BenefitRow(icon: "rosette", text: "Unlock VIP tiers for bonus points")
                BenefitRow(icon: "bell.fill", text: "Get notified when rewards are available")
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            
            Button {
                enrollCustomer()
            } label: {
                Label("Join Now - It's Free!", systemImage: "star.fill")
                    .font(.headline)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Helpers
    
    private var tierColor: Color {
        if let tier = tier, let colorHex = tier.color {
            return Color(hex: colorHex)
        }
        return .purple
    }
    
    private func loadLoyaltyData() {
        guard let customerId = customer.id else { return }
        
        member = LoyaltyService.shared.getMember(for: customerId)
        
        if let member = member {
            // Load tier
            if let tierId = member.currentTierId {
                tier = LoyaltyService.shared.getTier(tierId)
            }
            
            // Load rewards
            availableRewards = LoyaltyService.shared.getAvailableRewards(for: member)
            
            if let programId = member.programId {
                allRewards = LoyaltyService.shared.getActiveRewards(for: programId).filter { reward in
                    !availableRewards.contains(where: { $0.id == reward.id })
                }
            }
            
            // Load transactions
            if let memberId = member.id {
                transactions = LoyaltyService.shared.getTransactions(for: memberId, limit: 20)
            }
        }
    }
    
    private func enrollCustomer() {
        guard let customerId = customer.id else { return }
        member = LoyaltyService.shared.enrollCustomer(customerId)
        loadLoyaltyData()
    }
}

struct CustomerRewardCard: View {
    let reward: LoyaltyReward
    let member: LoyaltyMember?
    @State private var showingRedeemConfirmation = false
    @State private var showingRedemptionResult = false
    @State private var redemptionSuccess = false
    @State private var redemptionMessage = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: rewardIcon)
                    .font(.title2)
                    .foregroundColor(.green)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("\(reward.pointsCost)")
                        .font(.headline)
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
            }
            
            Text(reward.name ?? "Reward")
                .font(.headline)
            
            if let description = reward.description_ {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Button {
                showingRedeemConfirmation = true
            } label: {
                Text("Redeem Now")
                    .font(.subheadline)
                    .bold()
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green, lineWidth: 2)
        )
        .alert("Redeem Reward?", isPresented: $showingRedeemConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Redeem") {
                redeemReward()
            }
        } message: {
            Text("Redeem \(reward.name ?? "this reward") for \(reward.pointsCost) points?")
        }
        .alert(redemptionSuccess ? "Success!" : "Redemption Failed", isPresented: $showingRedemptionResult) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(redemptionMessage)
        }
    }
    
    private var rewardIcon: String {
        switch reward.rewardType {
        case "discount_percent": return "percent"
        case "discount_amount": return "dollarsign.circle.fill"
        case "free_item": return "gift.fill"
        default: return "star.fill"
        }
    }
    
    private func redeemReward() {
        guard let memberId = member?.id, let rewardId = reward.id else {
            redemptionSuccess = false
            redemptionMessage = "Unable to process redemption. Please try again."
            showingRedemptionResult = true
            return
        }
        
        if LoyaltyService.shared.redeemReward(memberId: memberId, rewardId: rewardId) {
            redemptionSuccess = true
            redemptionMessage = "✨ You've redeemed \(reward.name ?? "this reward")!\n\n-\(reward.pointsCost) points deducted\nNew balance: \(member?.availablePoints ?? 0 - reward.pointsCost) points"
            showingRedemptionResult = true
        } else {
            redemptionSuccess = false
            redemptionMessage = "Insufficient points or redemption failed. Please check your balance."
            showingRedemptionResult = true
        }
    }
}

struct LockedRewardCard: View {
    let reward: LoyaltyReward
    let currentPoints: Int32
    
    var pointsNeeded: Int32 {
        max(0, reward.pointsCost - currentPoints)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: rewardIcon)
                    .font(.title2)
                    .foregroundColor(.gray)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("\(reward.pointsCost)")
                        .font(.headline)
                    Image(systemName: "star.fill")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
            
            Text(reward.name ?? "Reward")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if let description = reward.description_ {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(.orange)
                Text("Need \(pointsNeeded) more points")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var rewardIcon: String {
        switch reward.rewardType {
        case "discount_percent": return "percent"
        case "discount_amount": return "dollarsign.circle.fill"
        case "free_item": return "gift.fill"
        default: return "star.fill"
        }
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
        }
    }
}

struct EnrollmentView: View {
    @Environment(\.dismiss) private var dismiss
    let customer: Customer
    let onEnroll: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.purple)
                
                Text("Welcome to ProTech Rewards!")
                    .font(.title)
                    .bold()
                
                Text("Start earning points today")
                    .foregroundColor(.secondary)
                
                Button {
                    enrollAndDismiss()
                } label: {
                    Text("Enroll Now")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
            .navigationTitle("Join Rewards")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 400, height: 350)
    }
    
    private func enrollAndDismiss() {
        if let customerId = customer.id {
            _ = LoyaltyService.shared.enrollCustomer(customerId)
        }
        onEnroll()
        dismiss()
    }
}

struct CustomerTransactionRow: View {
    let transaction: LoyaltyTransaction
    
    var body: some View {
        HStack {
            Image(systemName: transaction.type == "earned" ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .foregroundColor(transaction.type == "earned" ? .green : .orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.description_ ?? "Transaction")
                    .font(.subheadline)
                
                if let date = transaction.createdAt {
                    Text(date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text("\(transaction.type == "earned" ? "+" : "")\(transaction.points)")
                .font(.headline)
                .foregroundColor(transaction.type == "earned" ? .green : .orange)
        }
        .padding(.vertical, 4)
    }
}
