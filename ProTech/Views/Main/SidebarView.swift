//
//  SidebarView.swift
//  TechStorePro
//
//  App sidebar navigation
//

import SwiftUI

struct SidebarView: View {
    @Binding var selectedTab: Tab
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var authService: AuthenticationService
    
    var body: some View {
        VStack(spacing: 0) {
            List(selection: $selectedTab) {
                Section("Core") {
                    ForEach([Tab.dashboard, Tab.queue, Tab.customers, Tab.calendar], id: \.self) { tab in
                        NavigationLink(value: tab) {
                            Label(tab.rawValue, systemImage: tab.icon)
                        }
                    }
                }
                
                Section("Financial") {
                    ForEach([Tab.invoices, Tab.estimates, Tab.payments], id: \.self) { tab in
                        NavigationLink(value: tab) {
                            Label(tab.rawValue, systemImage: tab.icon)
                        }
                    }
                }
                
                Section("Business") {
                    NavigationLink(value: Tab.inventory) {
                        Label(Tab.inventory.rawValue, systemImage: Tab.inventory.icon)
                    }
                    
                    NavigationLink(value: Tab.pointOfSale) {
                        Label(Tab.pointOfSale.rawValue, systemImage: Tab.pointOfSale.icon)
                    }
                    
                    NavigationLink(value: Tab.loyalty) {
                        Label(Tab.loyalty.rawValue, systemImage: Tab.loyalty.icon)
                    }
                }
                
                Section("Pro Features") {
                    ForEach([Tab.forms, Tab.sms, Tab.marketing, Tab.timeTracking, Tab.employees, Tab.timeClock, Tab.reports], id: \.self) { tab in
                        NavigationLink(value: tab) {
                            HStack {
                                Label(tab.rawValue, systemImage: tab.icon)
                                Spacer()
                                if !subscriptionManager.isProSubscriber {
                                    Image(systemName: "lock.fill")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                    }
                }

                Section {
                    NavigationLink(value: Tab.settings) {
                        Label(Tab.settings.rawValue, systemImage: Tab.settings.icon)
                    }
                }
            }
            .navigationTitle(Configuration.appName)
            .listStyle(.sidebar)
            
            // User info and logout
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(authService.currentEmployeeName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(authService.currentEmployeeRole.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    authService.logout()
                }) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .help("Logout")
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
    }
}
