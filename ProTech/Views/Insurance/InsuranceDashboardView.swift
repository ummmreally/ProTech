//
//  InsuranceDashboardView.swift
//  ProTech
//
//  Manage insurance claims and providers.
//

import SwiftUI
import CoreData

struct InsuranceDashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \InsuranceClaim.updatedAt, ascending: false)],
        animation: .default
    ) private var claims: FetchedResults<InsuranceClaim>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \InsuranceProvider.name, ascending: true)]
    ) private var providers: FetchedResults<InsuranceProvider>
    
    @State private var showingAddProvider = false
    @State private var selectedClaim: InsuranceClaim?
    
    var body: some View {
        NavigationStack {
            VStack {
                // KPIs
                HStack(spacing: 20) {
                    StatusCard(title: "Open Claims", count: claims.filter { $0.status == "submitted" }.count, color: .orange)
                    StatusCard(title: "Approved", count: claims.filter { $0.status == "approved" }.count, color: .green)
                    StatusCard(title: "Rejected", count: claims.filter { $0.status == "rejected" }.count, color: .red)
                }
                .padding()
                
                // Claims List
                List {
                    Section("Recent Claims") {
                        if claims.isEmpty {
                            Text("No claims filed.")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(claims) { claim in
                                NavigationLink(destination: ClaimDetailView(claim: claim)) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(claim.claimNumber ?? "Draft")
                                                .font(.headline)
                                            Text(claim.status?.capitalized ?? "Unknown")
                                                .font(.caption)
                                                .padding(4)
                                                .background(statusColor(for: claim.status).opacity(0.1))
                                                .foregroundColor(statusColor(for: claim.status))
                                                .cornerRadius(4)
                                        }
                                        
                                        Spacer()
                                        
                                        if let updated = claim.updatedAt {
                                            Text(updated, style: .date)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    Section("Providers") {
                        ForEach(providers) { provider in
                            HStack {
                                Text(provider.name ?? "Unknown Provider")
                                Spacer()
                                if let email = provider.claimsEmail {
                                    Text(email)
                                        .foregroundStyle(.secondary)
                                        .font(.caption)
                                }
                            }
                        }
                        
                        Button("Add Provider") {
                            showingAddProvider = true
                        }
                    }
                }
            }
            .navigationTitle("Insurance Claims")
            .sheet(isPresented: $showingAddProvider) {
                AddProviderView()
            }
        }
    }
    
    func statusColor(for status: String?) -> Color {
        switch status {
        case "approved": return .green
        case "rejected": return .red
        case "submitted": return .blue
        case "paid": return .purple
        default: return .gray
        }
    }
}

// MARK: - Subviews

struct StatusCard: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack {
            Text("\(count)")
                .font(.largeTitle)
                .bold()
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
        .shadow(radius: 1)
    }
}

struct AddProviderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var name = ""
    @State private var email = ""
    @State private var portal = ""
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Provider Name", text: $name)
                TextField("Claims Email", text: $email)
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
                TextField("Portal URL", text: $portal)
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
            }
            .navigationTitle("New Provider")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let provider = InsuranceProvider(context: viewContext)
                        provider.id = UUID()
                        provider.name = name
                        provider.claimsEmail = email
                        provider.portalUrl = portal
                        try? viewContext.save()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

struct ClaimDetailView: View {
    @ObservedObject var claim: InsuranceClaim
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        Form {
            Section("Status") {
                Picker("Current Status", selection: Binding(
                    get: { claim.status ?? "draft" },
                    set: {
                        claim.status = $0
                        claim.updatedAt = Date()
                        try? viewContext.save()
                    }
                )) {
                    Text("Draft").tag("draft")
                    Text("Submitted").tag("submitted")
                    Text("Approved").tag("approved")
                    Text("Rejected").tag("rejected")
                    Text("Paid").tag("paid")
                }
            }
            
            Section("Info") {
                TextField("Claim Number", text: Binding(
                    get: { claim.claimNumber ?? "" },
                    set: { claim.claimNumber = $0 }
                ))
                
                TextField("Notes", text: Binding(
                    get: { claim.notes ?? "" },
                    set: { claim.notes = $0 }
                ))
            }
        }
        .navigationTitle(claim.claimNumber ?? "Claim Details")
    }
}
