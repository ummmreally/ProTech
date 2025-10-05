//
//  LoyaltyWidget.swift
//  ProTech
//
//  Compact loyalty display widget for POS and customer views
//

import SwiftUI

struct LoyaltyWidget: View {
    let customer: Customer
    @State private var member: LoyaltyMember?
    @State private var tier: LoyaltyTier?
    @State private var showingEnrollment = false
    
    var body: some View {
        Group {
            if let member = member {
                memberView(member: member)
            } else {
                enrollmentPromptView
            }
        }
        .onAppear {
            loadMember()
        }
        .sheet(isPresented: $showingEnrollment) {
            LoyaltyEnrollmentView(customer: customer) {
                loadMember()
            }
        }
    }
    
    private func memberView(member: LoyaltyMember) -> some View {
        HStack(spacing: 12) {
                // Tier badge
                Circle()
                    .fill(tierColor.gradient)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: "star.fill")
                            .foregroundColor(.white)
                            .font(.caption)
                    }
                
                // Points info
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("\(member.availablePoints)")
                            .font(.headline)
                            .bold()
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text("points")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let tier = tier {
                        Text("\(tier.name ?? "") • \(tier.pointsMultiplier, specifier: "%.1f")x")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // View details button
                NavigationLink(destination: CustomerLoyaltyView(customer: customer)) {
                    Text("View Rewards")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding()
            .background(tierColor.opacity(0.1))
            .cornerRadius(10)
    }
    
    private var enrollmentPromptView: some View {
        HStack {
                Image(systemName: "star.circle")
                    .foregroundColor(.purple)
                
                Text("Not enrolled in loyalty program")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button {
                    showingEnrollment = true
                } label: {
                    Text("Join Now")
                        .font(.caption)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding()
            .background(Color.purple.opacity(0.05))
            .cornerRadius(10)
    }
    
    private var tierColor: Color {
        if let tier = tier, let colorHex = tier.color {
            return Color(hex: colorHex)
        }
        return .purple
    }
    
    private func loadMember() {
        guard let customerId = customer.id else { return }
        member = LoyaltyService.shared.getMember(for: customerId)
        
        if let tierId = member?.currentTierId {
            tier = LoyaltyService.shared.getTier(tierId)
        }
    }
}
