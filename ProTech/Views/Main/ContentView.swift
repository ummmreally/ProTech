//
//  ContentView.swift
//  TechStorePro
//
//  Main app content view with navigation
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var selectedTab: Tab = .customers
    @State private var showingUpgrade = false
    @State private var showingTwilioTutorial = false
    
    var body: some View {
        NavigationSplitView {
            SidebarView(selectedTab: $selectedTab)
                .frame(minWidth: 200)
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        if !subscriptionManager.isProSubscriber {
                            Button {
                                showingUpgrade = true
                            } label: {
                                Label("Upgrade to Pro", systemImage: "star.fill")
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
        } detail: {
            DetailView(selectedTab: selectedTab)
        }
        .sheet(isPresented: $showingUpgrade) {
            SubscriptionView()
                .frame(width: 600, height: 700)
        }
        .sheet(isPresented: $showingTwilioTutorial) {
            TwilioTutorialView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openTwilioTutorial)) { _ in
            showingTwilioTutorial = true
        }
    }
}

// MARK: - Tab Enum

enum Tab: String, CaseIterable {
    case dashboard = "Dashboard"
    case queue = "Queue"
    case customers = "Customers"
    case calendar = "Calendar"
    case invoices = "Invoices"
    case estimates = "Estimates"
    case payments = "Payments"
    case inventory = "Inventory"
    case pointOfSale = "Point of Sale"
    case forms = "Forms"
    case sms = "SMS"
    case marketing = "Marketing"
    case timeTracking = "Time"
    case employees = "Employees"
    case timeClock = "Time Clock"
    case reports = "Reports"
    case settings = "Settings"
    
    var icon: String {
        switch self {
        case .dashboard: return "chart.bar.fill"
        case .queue: return "line.3.horizontal.decrease.circle.fill"
        case .customers: return "person.3.fill"
        case .calendar: return "calendar"
        case .invoices: return "doc.text.fill"
        case .estimates: return "doc.plaintext.fill"
        case .payments: return "dollarsign.circle.fill"
        case .inventory: return "shippingbox.fill"
        case .pointOfSale: return "cart.fill"
        case .forms: return "doc.fill"
        case .sms: return "message.fill"
        case .marketing: return "megaphone.fill"
        case .timeTracking: return "clock.fill"
        case .employees: return "person.3.sequence.fill"
        case .timeClock: return "clock.badge.checkmark.fill"
        case .reports: return "chart.line.uptrend.xyaxis"
        case .settings: return "gearshape.fill"
        }
    }
    
    var isPremium: Bool {
        switch self {
        case .dashboard, .queue, .customers, .calendar, .invoices, .estimates, .payments, .inventory, .pointOfSale, .settings:
            return false
        case .forms, .sms, .marketing, .timeTracking, .employees, .timeClock, .reports:
            return true
        }
    }
}

// MARK: - Detail View

struct DetailView: View {
    let selectedTab: Tab
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var showingUpgrade = false
    
    var body: some View {
        Group {
            if selectedTab.isPremium && !subscriptionManager.isProSubscriber {
                PremiumFeatureLockedView(feature: selectedTab)
            } else {
                switch selectedTab {
                case .dashboard:
                    DashboardView()
                case .queue:
                    QueueView()
                case .customers:
                    CustomerListView()
                case .calendar:
                    AppointmentSchedulerView()
                case .invoices:
                    InvoiceListView()
                case .estimates:
                    EstimateListView()
                case .payments:
                    PaymentHistoryView()
                case .inventory:
                    ModernInventoryDashboardView()
                case .pointOfSale:
                    PointOfSaleView()
                case .forms:
                    FormsListView()
                case .sms:
                    SMSHistoryView()
                case .marketing:
                    MarketingCampaignsView()
                case .reports:
                    ReportsView()
                case .timeTracking:
                    TimeEntriesView()
                case .employees:
                    EmployeeManagementView()
                case .timeClock:
                    TimeClockView()
                case .settings:
                    SettingsView()
                }
            }
        }
    }
}

// MARK: - Premium Feature Locked View

struct PremiumFeatureLockedView: View {
    let feature: Tab
    @State private var showingUpgrade = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("\(feature.rawValue) is a Pro Feature")
                .font(.title)
                .bold()
            
            Text("Upgrade to Pro to unlock \(feature.rawValue.lowercased()) and all premium features.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                showingUpgrade = true
            } label: {
                Label("Upgrade to Pro", systemImage: "star.fill")
                    .font(.headline)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            Text("$19.99/month • 7-day free trial")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showingUpgrade) {
            SubscriptionView()
                .frame(width: 600, height: 700)
        }
    }
}
