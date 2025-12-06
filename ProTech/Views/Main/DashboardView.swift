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
                    
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Spacing.md) {
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
                    
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Spacing.sm) {
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
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Image(systemName: "star.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                Text("Unlock Pro Features")
                    .font(AppTheme.Typography.headline)
                Spacer()
            }
            
            Text("Get SMS messaging, custom forms, cloud sync, and more for just $19.99/month")
                .font(AppTheme.Typography.body)
                .foregroundColor(.secondary)
            
            Button {
                showingUpgrade = true
            } label: {
                Text("Try Free for 7 Days")
                    .font(AppTheme.Typography.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(PremiumButtonStyle(variant: .primary))
        }
        .padding(AppTheme.Spacing.xl)
        .background(
            AppTheme.Colors.warningGradient.opacity(0.2)
        )
        .cornerRadius(AppTheme.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
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
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                }
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
            
            Text(title)
                .font(AppTheme.Typography.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(AppTheme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.cardCornerRadius)
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(color.opacity(isHovered ? 0.2 : 0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(AppTheme.Typography.body)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(.secondary)
                    .opacity(isHovered ? 1.0 : 0.6)
            }
            .padding(AppTheme.Spacing.md)
            .background(
                AppTheme.Colors.cardBackground
            )
            .cornerRadius(AppTheme.cardCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                    .stroke(isHovered ? color.opacity(0.3) : Color.primary.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: .black.opacity(isHovered ? 0.08 : 0.04), radius: isHovered ? 6 : 3, x: 0, y: 2)
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(AppTheme.Animation.quick, value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
