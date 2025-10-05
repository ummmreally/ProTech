//
//  RewardPickerView.swift
//  ProTech
//
//  Reward selection sheet for POS
//

import SwiftUI

struct RewardPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let customer: Customer
    let availableRewards: [LoyaltyReward]
    let onSelect: (LoyaltyReward) -> Void
    
    @State private var member: LoyaltyMember?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Member info header
                if member != nil {
                    memberHeader
                }
                
                // Available rewards
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(availableRewards) { reward in
                            RewardSelectionCard(reward: reward) {
                                onSelect(reward)
                                dismiss()
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Select Reward")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 500, height: 600)
        .onAppear {
            loadMember()
        }
    }
    
    private var memberHeader: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.purple.gradient)
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: "star.fill")
                        .foregroundColor(.white)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(customer.firstName ?? "") \(customer.lastName ?? "")")
                    .font(.headline)
                
                if let member = member {
                    HStack(spacing: 4) {
                        Text("\(member.availablePoints)")
                            .font(.subheadline)
                            .bold()
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text("available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func loadMember() {
        guard let customerId = customer.id else { return }
        member = LoyaltyService.shared.getMember(for: customerId)
    }
}

struct RewardSelectionCard: View {
    let reward: LoyaltyReward
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Icon
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 60, height: 60)
                    .overlay {
                        Image(systemName: rewardIcon)
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(reward.name ?? "Reward")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let description = reward.description_ {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Text(rewardValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                // Points cost
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Text("\(reward.pointsCost)")
                            .font(.headline)
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                    Text("points")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.green.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var rewardIcon: String {
        switch reward.rewardType {
        case "discount_percent": return "percent"
        case "discount_amount": return "dollarsign.circle.fill"
        case "free_item": return "gift.fill"
        default: return "star.fill"
        }
    }
    
    private var rewardValue: String {
        switch reward.rewardType {
        case "discount_percent":
            return "\(Int(reward.rewardValue))% Off"
        case "discount_amount":
            return "$\(Int(reward.rewardValue)) Off"
        case "free_item":
            return "Free Item"
        default:
            return "Special Offer"
        }
    }
}
