//
//  LoyaltyMembersTab.swift
//  ProTech
//
//  View all loyalty members
//

import SwiftUI
import CoreData

struct LoyaltyMembersTab: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \LoyaltyMember.lifetimePoints, ascending: false)],
        predicate: NSPredicate(format: "isActive == true")
    ) var members: FetchedResults<LoyaltyMember>
    
    @State private var searchText = ""
    
    var filteredMembers: [LoyaltyMember] {
        if searchText.isEmpty {
            return Array(members)
        }
        // Filter by customer name - requires fetching customer data
        return Array(members)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search members...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .padding()
            
            // Members list
            if filteredMembers.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.3")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No members yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredMembers) { member in
                            NavigationLink(destination: MemberDetailView(member: member)) {
                                MemberRow(member: member)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

struct MemberRow: View {
    @ObservedObject var member: LoyaltyMember
    @FetchRequest var customer: FetchedResults<Customer>
    @FetchRequest var tier: FetchedResults<LoyaltyTier>
    
    init(member: LoyaltyMember) {
        self.member = member
        
        if let customerId = member.customerId {
            _customer = FetchRequest<Customer>(
                sortDescriptors: [],
                predicate: NSPredicate(format: "id == %@", customerId as CVarArg)
            )
        } else {
            _customer = FetchRequest<Customer>(
                sortDescriptors: [],
                predicate: NSPredicate(value: false)
            )
        }
        
        if let tierId = member.currentTierId {
            _tier = FetchRequest<LoyaltyTier>(
                sortDescriptors: [],
                predicate: NSPredicate(format: "id == %@", tierId as CVarArg)
            )
        } else {
            _tier = FetchRequest<LoyaltyTier>(
                sortDescriptors: [],
                predicate: NSPredicate(value: false)
            )
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            Circle()
                .fill(tierColor.gradient)
                .frame(width: 50, height: 50)
                .overlay {
                    if let customer = customer.first {
                        Text("\(customer.firstName?.prefix(1) ?? "")\(customer.lastName?.prefix(1) ?? "")")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                if let customer = customer.first {
                    Text("\(customer.firstName ?? "") \(customer.lastName ?? "")")
                        .font(.headline)
                } else {
                    Text("Unknown Customer")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 8) {
                    if let tier = tier.first {
                        Text(tier.name ?? "")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(tierColor.opacity(0.2))
                            .foregroundColor(tierColor)
                            .cornerRadius(4)
                    }
                    
                    Text("\(member.visitCount) visits")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Points
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Text("\(member.availablePoints)")
                        .font(.title3)
                        .bold()
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
                
                Text("$\(member.totalSpent, specifier: "%.0f") spent")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var tierColor: Color {
        if let tier = tier.first, let colorHex = tier.color {
            return Color(hex: colorHex)
        }
        return .blue
    }
}

struct MemberDetailView: View {
    @ObservedObject var member: LoyaltyMember
    @FetchRequest var customer: FetchedResults<Customer>
    @FetchRequest var tier: FetchedResults<LoyaltyTier>
    @State private var transactions: [LoyaltyTransaction] = []
    
    init(member: LoyaltyMember) {
        self.member = member
        
        if let customerId = member.customerId {
            _customer = FetchRequest<Customer>(
                sortDescriptors: [],
                predicate: NSPredicate(format: "id == %@", customerId as CVarArg)
            )
        } else {
            _customer = FetchRequest<Customer>(
                sortDescriptors: [],
                predicate: NSPredicate(value: false)
            )
        }
        
        if let tierId = member.currentTierId {
            _tier = FetchRequest<LoyaltyTier>(
                sortDescriptors: [],
                predicate: NSPredicate(format: "id == %@", tierId as CVarArg)
            )
        } else {
            _tier = FetchRequest<LoyaltyTier>(
                sortDescriptors: [],
                predicate: NSPredicate(value: false)
            )
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Member card
                GroupBox {
                    VStack(spacing: 16) {
                        Circle()
                            .fill(tierColor.gradient)
                            .frame(width: 80, height: 80)
                            .overlay {
                                if let customer = customer.first {
                                    Text("\(customer.firstName?.prefix(1) ?? "")\(customer.lastName?.prefix(1) ?? "")")
                                        .font(.largeTitle)
                                        .bold()
                                        .foregroundColor(.white)
                                }
                            }
                        
                        if let customer = customer.first {
                            Text("\(customer.firstName ?? "") \(customer.lastName ?? "")")
                                .font(.title2)
                                .bold()
                        }
                        
                        if let tier = tier.first {
                            Text(tier.name ?? "Member")
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(tierColor.opacity(0.2))
                                .foregroundColor(tierColor)
                                .cornerRadius(8)
                        }
                        
                        HStack(spacing: 40) {
                            VStack {
                                Text("\(member.availablePoints)")
                                    .font(.title)
                                    .bold()
                                Text("Available Points")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack {
                                Text("\(member.lifetimePoints)")
                                    .font(.title)
                                    .bold()
                                Text("Lifetime Points")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Stats
                HStack(spacing: 16) {
                    MemberStatCard(title: "Total Visits", value: "\(member.visitCount)", icon: "person.wave.2", color: .blue)
                    MemberStatCard(title: "Total Spent", value: String(format: "$%.0f", member.totalSpent), icon: "dollarsign.circle", color: .green)
                }
                
                // Transaction history
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Recent Activity", systemImage: "clock.fill")
                            .font(.headline)
                        
                        if transactions.isEmpty {
                            Text("No activity yet")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(transactions) { transaction in
                                MemberTransactionRow(transaction: transaction)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Member Details")
        .onAppear {
            loadTransactions()
        }
    }
    
    private var tierColor: Color {
        if let tier = tier.first, let colorHex = tier.color {
            return Color(hex: colorHex)
        }
        return .blue
    }
    
    private func loadTransactions() {
        if let memberId = member.id {
            transactions = LoyaltyService.shared.getTransactions(for: memberId, limit: 20)
        }
    }
}

struct MemberTransactionRow: View {
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

struct MemberStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title)
                .bold()
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}
