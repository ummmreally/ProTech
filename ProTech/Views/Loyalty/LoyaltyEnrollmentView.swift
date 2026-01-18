//
//  LoyaltyEnrollmentView.swift
//  ProTech
//
//  Dedicated enrollment screen with benefits
//

import SwiftUI

struct LoyaltyEnrollmentView: View {
    @Environment(\.dismiss) private var dismiss
    let customer: Customer
    let onEnroll: () -> Void
    
    @State private var program: LoyaltyProgram?
    @State private var tiers: [LoyaltyTier] = []
    @State private var sampleRewards: [LoyaltyReward] = []
    
    var body: some View {
        NavigationStack {
            if program == nil {
                // No program exists
                VStack(spacing: 24) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    Text("Loyalty Program Not Set Up")
                        .font(.title)
                        .bold()
                    
                    Text("Your admin needs to create a loyalty program first. Go to Loyalty in the sidebar and click 'Create Loyalty Program'.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 400)
                    
                    Button("Close") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 32) {
                        // Hero section
                        heroSection
                        
                        // Benefits
                        benefitsSection
                        
                        // How it works
                        howItWorksSection
                        
                        // Sample rewards
                        if !sampleRewards.isEmpty {
                            rewardsPreviewSection
                        }
                        
                        // VIP tiers
                        if !tiers.isEmpty {
                            tiersSection
                        }
                        
                        // Enroll button
                        enrollButton
                    }
                    .padding(32)
                }
                .navigationTitle("Join Loyalty Program")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
        }
        .frame(width: 700, height: 800)
        .onAppear {
            loadProgramData()
        }
    }
    
    // MARK: - Sections
    
    private var heroSection: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: .purple.opacity(0.3), radius: 20, y: 10)
                
                Image(systemName: "star.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                Text(program?.name ?? "ProTech Rewards")
                    .font(.system(size: 36, weight: .bold))
                
                Text("Start earning rewards today!")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            if let program = program {
                HStack(spacing: 24) {
                    StatPill(
                        icon: "dollarsign.circle.fill",
                        text: String(format: "%.1f pt/$", program.pointsPerDollar)
                    )
                    StatPill(
                        icon: "person.wave.2.fill",
                        text: "+\(program.pointsPerVisit) per visit"
                    )
                }
            }
        }
    }
    
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Why Join?")
                .font(.title2)
                .bold()
            
            VStack(spacing: 12) {
                BenefitCard(
                    icon: "dollarsign.circle.fill",
                    color: .green,
                    title: "Earn on Every Purchase",
                    description: "Get points every time you spend money with us"
                )
                
                BenefitCard(
                    icon: "gift.fill",
                    color: .red,
                    title: "Exclusive Rewards",
                    description: "Redeem points for discounts and special offers"
                )
                
                BenefitCard(
                    icon: "rosette",
                    color: .purple,
                    title: "VIP Tier Benefits",
                    description: "Earn bonus multipliers as you level up"
                )
                
                BenefitCard(
                    icon: "bell.fill",
                    color: .blue,
                    title: "Instant Notifications",
                    description: "Get SMS alerts when rewards are unlocked"
                )
            }
        }
    }
    
    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How It Works")
                .font(.title2)
                .bold()
            
            VStack(spacing: 16) {
                HowItWorksStep(
                    number: 1,
                    title: "Make a Purchase",
                    description: "Shop or get service as usual"
                )
                
                HowItWorksStep(
                    number: 2,
                    title: "Earn Points",
                    description: "Automatically receive points on every transaction"
                )
                
                HowItWorksStep(
                    number: 3,
                    title: "Redeem Rewards",
                    description: "Use your points for discounts and special offers"
                )
            }
        }
    }
    
    private var rewardsPreviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sample Rewards")
                .font(.title2)
                .bold()
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(sampleRewards.prefix(5)) { reward in
                        RewardPreviewCard(reward: reward)
                    }
                }
            }
        }
    }
    
    private var tiersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("VIP Tiers")
                .font(.title2)
                .bold()
            
            Text("Level up to earn bonus points on every purchase")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                ForEach(tiers) { tier in
                    TierPreviewCard(tier: tier)
                }
            }
        }
    }
    
    private var enrollButton: some View {
        Button {
            enrollCustomer()
        } label: {
            HStack {
                Image(systemName: "star.fill")
                Text("Join \(program?.name ?? "Rewards Program") - It's Free!")
                Image(systemName: "arrow.right")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppTheme.Colors.buttonPrimary)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.15), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Actions
    
    private func loadProgramData() {
        program = LoyaltyService.shared.getActiveProgram()
        
        if let programId = program?.id {
            tiers = LoyaltyService.shared.getTiers(for: programId)
            sampleRewards = LoyaltyService.shared.getActiveRewards(for: programId)
        }
    }
    
    private func enrollCustomer() {
        guard let customerId = customer.id else { return }
        _ = LoyaltyService.shared.enrollCustomer(customerId)
        onEnroll()
        dismiss()
    }
}

// MARK: - Supporting Views

struct StatPill: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
                .fontWeight(.semibold)
        }
        .font(.subheadline)
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.purple.opacity(0.8))
        .cornerRadius(20)
    }
}

struct BenefitCard: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(color.gradient)
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: icon)
                        .foregroundColor(.white)
                        .font(.title3)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct HowItWorksStep: View {
    let number: Int
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.gradient)
                    .frame(width: 40, height: 40)
                
                Text("\(number)")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct RewardPreviewCard: View {
    let reward: LoyaltyReward
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: rewardIcon)
                    .font(.title2)
                    .foregroundColor(.green)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("\(reward.pointsCost)")
                        .font(.caption)
                        .bold()
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                }
            }
            
            Text(reward.name ?? "Reward")
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)
            
            if let description = reward.description_ {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .frame(width: 180)
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
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

struct TierPreviewCard: View {
    let tier: LoyaltyTier
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(tierColor.gradient)
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: "rosette")
                        .foregroundColor(.white)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(tier.name ?? "Tier")
                    .font(.headline)
                
                Text("\(tier.pointsMultiplier, specifier: "%.1f")x points multiplier")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(tier.pointsRequired)+ pts")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(tierColor.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var tierColor: Color {
        if let colorHex = tier.color {
            return Color(hex: colorHex)
        }
        return .blue
    }
}
