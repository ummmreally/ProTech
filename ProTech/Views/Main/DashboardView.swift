//
//  DashboardView.swift
//  TechStorePro
//
//  Dashboard with statistics
//

import SwiftUI

struct DashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    
    @State private var totalCustomers: Int = 0
    @State private var customersThisMonth: Int = 0
    @State private var showingUpgrade = false
    
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
