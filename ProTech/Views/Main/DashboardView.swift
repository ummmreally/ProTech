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
    @State private var refreshToggle = false
    @State private var lastRefresh = Date()
    
    struct PortalAlert: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }
    
    private let refreshTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with Refresh
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dashboard")
                            .font(.largeTitle)
                            .bold()
                        Text("Welcome to \(Configuration.appName)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Button(action: refreshDashboard) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.clockwise")
                                Text("Refresh")
                                    .font(.caption)
                            }
                        }
                        .buttonStyle(.borderless)
                        
                        Text("Updated \(lastRefresh, style: .relative) ago")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Subscription Status
                if !subscriptionManager.isProSubscriber {
                    upgradePromoBanner
                }
                
                // ENHANCED WIDGETS
                
                // Financial Overview Widget
                FinancialOverviewWidget()
                    .id(refreshToggle)
                    .padding(.horizontal)
                
                // Two Column Layout for Main Widgets
                HStack(alignment: .top, spacing: 16) {
                    // Left Column
                    VStack(spacing: 16) {
                        OperationalStatusWidget()
                            .id(refreshToggle)
                        
                        TodayScheduleWidget()
                            .id(refreshToggle)
                    }
                    
                    // Right Column
                    VStack(spacing: 16) {
                        AlertsWidget()
                            .id(refreshToggle)
                        
                        RecentActivityWidget()
                            .id(refreshToggle)
                    }
                }
                .padding(.horizontal)
                
                // Quick Stats Grid
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Stats")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
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
                }
                
                // Enhanced Quick Actions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Actions")
                        .font(.title2)
                        .bold()
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        QuickActionButton(
                            title: "Check In Repair",
                            icon: "wrench.and.screwdriver.fill",
                            color: .blue
                        ) {
                            NotificationCenter.default.post(name: .navigateToQueue, object: nil)
                        }
                        
                        QuickActionButton(
                            title: "Add New Customer",
                            icon: "person.badge.plus",
                            color: .green
                        ) {
                            NotificationCenter.default.post(name: .newCustomer, object: nil)
                        }
                        
                        QuickActionButton(
                            title: "Create Estimate",
                            icon: "doc.plaintext.fill",
                            color: .orange
                        ) {
                            NotificationCenter.default.post(name: .navigateToEstimates, object: nil)
                        }
                        
                        QuickActionButton(
                            title: "Record Payment",
                            icon: "dollarsign.circle.fill",
                            color: .green
                        ) {
                            NotificationCenter.default.post(name: .navigateToPayments, object: nil)
                        }
                        
                        if subscriptionManager.isProSubscriber {
                            QuickActionButton(
                                title: "Create Intake Form",
                                icon: "doc.text.fill",
                                color: .purple
                            ) {
                                NotificationCenter.default.post(name: .navigateToForms, object: nil)
                            }
                            
                            if TwilioService.shared.isConfigured {
                                QuickActionButton(
                                    title: "Send SMS",
                                    icon: "message.fill",
                                    color: .orange
                                ) {
                                    NotificationCenter.default.post(name: .navigateToSMS, object: nil)
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
                dismissButton: .default(Text("OK")) {
                    refreshDashboard()
                }
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .estimateApproved)) { notification in
            handleEstimateApproval(notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: .estimateDeclined)) { notification in
            handleEstimateDecline(notification)
        }
        .onReceive(refreshTimer) { _ in
            refreshDashboard()
        }
        .onAppear {
            loadStatistics()
            refreshDashboard()
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
    
    private func refreshDashboard() {
        lastRefresh = Date()
        refreshToggle.toggle()
        loadStatistics()
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
