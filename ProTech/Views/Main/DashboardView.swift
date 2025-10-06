//
//  DashboardView.swift
//  TechStorePro
//
//  Dashboard with statistics
//

import SwiftUI
import CoreData

struct DashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    
    @State private var totalCustomers: Int = 0
    @State private var customersThisMonth: Int = 0
    @State private var showingUpgrade = false
    @State private var portalAlert: PortalAlert?
    
    struct PortalAlert: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dashboard")
                        .font(.largeTitle)
                        .bold()
                    Text("Welcome to \(Configuration.appName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Subscription Status
                if !subscriptionManager.isProSubscriber {
                    upgradePromoBanner
                }
                
                // Stats Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    DashboardStatCard(
                        title: "Total Customers",
                        value: "\(totalCustomers)",
                        icon: "person.3.fill",
                        color: .blue
                    )
                    
                    DashboardStatCard(
                        title: "Added This Month",
                        value: "\(customersThisMonth)",
                        icon: "person.badge.plus",
                        color: .green
                    )
                    
                    if subscriptionManager.isProSubscriber {
                        DashboardStatCard(
                            title: "Forms Created",
                            value: "0",
                            icon: "doc.text.fill",
                            color: .purple
                        )
                        
                        DashboardStatCard(
                            title: "SMS Sent",
                            value: "0",
                            icon: "message.fill",
                            color: .orange
                        )
                    }
                }
                .padding(.horizontal)
                
                // Quick Actions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Actions")
                        .font(.title2)
                        .bold()
                    
                    VStack(spacing: 8) {
                        QuickActionButton(
                            title: "Add New Customer",
                            icon: "person.badge.plus",
                            color: .blue
                        ) {
                            NotificationCenter.default.post(name: .newCustomer, object: nil)
                        }
                        
                        if subscriptionManager.isProSubscriber {
                            QuickActionButton(
                                title: "Create Intake Form",
                                icon: "doc.text.fill",
                                color: .purple
                            ) {
                                // Navigate to forms
                            }
                            
                            if TwilioService.shared.isConfigured {
                                QuickActionButton(
                                    title: "Send SMS",
                                    icon: "message.fill",
                                    color: .orange
                                ) {
                                    // Navigate to SMS
                                }
                            } else {
                                QuickActionButton(
                                    title: "Setup Twilio SMS",
                                    icon: "message.badge.fill",
                                    color: .orange
                                ) {
                                    NotificationCenter.default.post(name: .openTwilioTutorial, object: nil)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .alert(item: $portalAlert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .estimateApproved)) { notification in
            handleEstimateApproval(notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: .estimateDeclined)) { notification in
            handleEstimateDecline(notification)
        }
        .onAppear {
            loadStatistics()
        }
    }
    
    private var upgradePromoBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                Text("Unlock Pro Features")
                    .font(.headline)
                Spacer()
            }
            
            Text("Get SMS messaging, custom forms, cloud sync, and more for just $19.99/month")
                .font(.body)
                .foregroundColor(.secondary)
            
            Button {
                showingUpgrade = true
            } label: {
                Text("Try Free for 7 Days")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
        .sheet(isPresented: $showingUpgrade) {
            SubscriptionView()
                .frame(width: 600, height: 700)
        }
    }
    
    private func loadStatistics() {
        totalCustomers = CoreDataManager.shared.getCustomerCount()
        customersThisMonth = CoreDataManager.shared.getCustomersAddedThisMonth()
    }
    
    // MARK: - Portal Notification Handlers
    
    private func handleEstimateApproval(_ notification: Notification) {
        guard let estimateId = notification.userInfo?["estimateId"] as? UUID,
              let estimate = fetchEstimate(by: estimateId) else {
            return
        }
        
        let customerName = fetchCustomerName(for: estimate.customerId)
        portalAlert = PortalAlert(
            title: "✅ Estimate Approved",
            message: "\(estimate.formattedEstimateNumber) was approved by \(customerName) via the Customer Portal."
        )
    }
    
    private func handleEstimateDecline(_ notification: Notification) {
        guard let estimateId = notification.userInfo?["estimateId"] as? UUID,
              let estimate = fetchEstimate(by: estimateId) else {
            return
        }
        
        let customerName = fetchCustomerName(for: estimate.customerId)
        let reason = notification.userInfo?["reason"] as? String
        
        var message = "\(estimate.formattedEstimateNumber) was declined by \(customerName) via the Customer Portal."
        if let reason = reason, !reason.isEmpty {
            message += "\n\nReason: \(reason)"
        }
        
        portalAlert = PortalAlert(
            title: "❌ Estimate Declined",
            message: message
        )
    }
    
    private func fetchEstimate(by id: UUID) -> Estimate? {
        let request: NSFetchRequest<Estimate> = Estimate.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try? viewContext.fetch(request).first
    }
    
    private func fetchCustomerName(for customerId: UUID?) -> String {
        guard let customerId = customerId else { return "Customer" }
        
        let request: NSFetchRequest<Customer> = Customer.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", customerId as CVarArg)
        request.fetchLimit = 1
        
        if let customer = try? viewContext.fetch(request).first {
            return customer.displayName
        }
        return "Customer"
    }
}

// MARK: - Stat Card

struct DashboardStatCard: View {
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
                .font(.system(size: 32, weight: .bold))
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 30)
                
                Text(title)
                    .font(.body)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}
