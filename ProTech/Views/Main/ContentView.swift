//
//  ContentView.swift
//  TechStorePro
//
//  Main app content view with navigation
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @StateObject var kioskManager = KioskModeManager.shared
    @State private var selectedTab: Tab = .customers
    @State private var showingUpgrade = false
    @State private var showingTwilioTutorial = false
    @State private var showingGlobalSearch = false
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var showingNotifications = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showingOnboarding = false
    
    var body: some View {
        ZStack {
            if kioskManager.isKioskModeEnabled {
                // Kiosk Mode - Full Screen Customer Portal Only
                CustomerPortalLoginView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.windowBackgroundColor))
            } else {
                // Normal Mode - Full App Access
                NavigationSplitView(columnVisibility: .constant(.all)) {
                    SidebarView(selectedTab: $selectedTab)
                        .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 280)
                        .toolbar {
                            ToolbarItem(placement: .automatic) {
                                HStack(spacing: 16) {
                                    // Notification Bell
                                    Button {
                                        showingNotifications.toggle()
                                    } label: {
                                        ZStack(alignment: .topTrailing) {
                                            Image(systemName: "bell")
                                            if notificationManager.unreadCount > 0 {
                                                Circle()
                                                    .fill(Color.red)
                                                    .frame(width: 8, height: 8)
                                                    .offset(x: 2, y: -2)
                                            }
                                        }
                                    }
                                    .popover(isPresented: $showingNotifications) {
                                        NotificationCenterView()
                                    }
                                    
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
                        }
                } detail: {
                    DetailView(selectedTab: selectedTab)
                        .frame(minWidth: 600)
                }
                .navigationSplitViewStyle(.balanced)
                .overlay(alignment: .top) {
                    if let toast = notificationManager.currentToast {
                        ToastView(notification: toast) {
                            withAnimation {
                                notificationManager.currentToast = nil
                            }
                        }
                        .padding(.top, 20)
                    }
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
                .onReceive(NotificationCenter.default.publisher(for: .navigateToQueue)) { _ in
                    selectedTab = .queue
                }
                .onReceive(NotificationCenter.default.publisher(for: .navigateToEstimates)) { _ in
                    selectedTab = .estimates
                }
                .onReceive(NotificationCenter.default.publisher(for: .navigateToPayments)) { _ in
                    selectedTab = .payments
                }
                .onReceive(NotificationCenter.default.publisher(for: .navigateToForms)) { _ in
                    selectedTab = .forms
                }
                .onReceive(NotificationCenter.default.publisher(for: .navigateToSMS)) { _ in
                    selectedTab = .sms
                }
                .onReceive(NotificationCenter.default.publisher(for: .navigateToInventory)) { _ in
                    selectedTab = .inventory
                }
                .sheet(isPresented: $showingGlobalSearch) {
                    GlobalSearchView(isPresented: $showingGlobalSearch)
                }
                .onReceive(NotificationCenter.default.publisher(for: .openGlobalSearch)) { _ in
                    showingGlobalSearch = true
                }
                .sheet(isPresented: $showingOnboarding) {
                    OnboardingView(isPresented: $showingOnboarding)
                }
                .onAppear {
                    if !hasCompletedOnboarding {
                        showingOnboarding = true
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .navigateToDashboard)) { _ in selectedTab = .dashboard }
                .onReceive(NotificationCenter.default.publisher(for: .navigateToRepairs)) { _ in selectedTab = .repairs }
                .onReceive(NotificationCenter.default.publisher(for: .navigateToCustomers)) { _ in selectedTab = .customers }
                .onReceive(NotificationCenter.default.publisher(for: .navigateToInvoices)) { _ in selectedTab = .invoices }
                .onReceive(NotificationCenter.default.publisher(for: .navigateToPOS)) { _ in selectedTab = .pointOfSale }
            }
        }
    }
}



// MARK: - Tab Enum

enum Tab: String, CaseIterable {
    case dashboard = "Dashboard"
    case queue = "Queue"
    case repairs = "Repairs"
    case customers = "Customers"
    case calendar = "Calendar"
    case invoices = "Invoices"
    case estimates = "Estimates"
    case payments = "Payments"
    case inventory = "Inventory"
    case pointOfSale = "Point of Sale"
    case loyalty = "Loyalty"
    case customerPortal = "Customer Portal"
    case forms = "Forms"
    case sms = "SMS"
    case marketing = "Marketing"
    case employees = "Employees"
    case attendance = "Attendance"
    case reports = "Reports"
    case settings = "Settings"
    
    var icon: String {
        switch self {
        case .dashboard: return "chart.bar.fill"
        case .queue: return "person.2.wave.2.fill"
        case .repairs: return "wrench.and.screwdriver.fill"
        case .customers: return "person.3.fill"
        case .calendar: return "calendar"
        case .invoices: return "doc.text.fill"
        case .estimates: return "doc.plaintext.fill"
        case .payments: return "dollarsign.circle.fill"
        case .inventory: return "shippingbox.fill"
        case .pointOfSale: return "cart.fill"
        case .loyalty: return "star.circle.fill"
        case .customerPortal: return "person.crop.circle.badge.checkmark"
        case .forms: return "doc.fill"
        case .sms: return "message.fill"
        case .marketing: return "megaphone.fill"
        case .employees: return "person.3.sequence.fill"
        case .attendance: return "clock.badge.checkmark.fill"
        case .reports: return "chart.line.uptrend.xyaxis"
        case .settings: return "gearshape.fill"
        }
    }
    
    var isPremium: Bool {
        switch self {
        case .dashboard, .queue, .repairs, .customers, .calendar, .invoices, .estimates, .payments, .inventory, .pointOfSale, .loyalty, .customerPortal, .settings:
            return false
        case .forms, .sms, .marketing, .employees, .attendance, .reports:
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
                    CheckInQueueView()
                case .repairs:
                    RepairsView()
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
                case .loyalty:
                    LoyaltyManagementView()
                case .customerPortal:
                    CustomerPortalLoginView()
                case .forms:
                    FormsListView()
                case .sms:
                    SMSHistoryView()
                case .marketing:
                    MarketingCampaignsView()
                case .reports:
                    ReportsView()
                case .employees:
                    EmployeeManagementView()
                case .attendance:
                    AttendanceView()
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
