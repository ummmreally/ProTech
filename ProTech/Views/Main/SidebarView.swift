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
    
    // Fixed sidebar dimensions for consistency
    private let sidebarMinWidth: CGFloat = 220
    
    var body: some View {
        VStack(spacing: 0) {
            List(selection: $selectedTab) {
                Section {
                    Text("CORE")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 8)
                        .padding(.top, 8)
                } header: {
                    EmptyView()
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                
                Section {
                    ForEach([Tab.dashboard, Tab.queue, Tab.repairs, Tab.customers, Tab.calendar], id: \.self) { tab in
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
                
                Section {
                    Text("BUSINESS")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 8)
                        .padding(.top, AppTheme.Spacing.sm)
                } header: {
                    EmptyView()
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                
                Section {
                    NavigationLink(value: Tab.inventory) {
                        Label(Tab.inventory.rawValue, systemImage: Tab.inventory.icon)
                    }
                    
                    NavigationLink(value: Tab.pointOfSale) {
                        Label(Tab.pointOfSale.rawValue, systemImage: Tab.pointOfSale.icon)
                    }
                    
                    NavigationLink(value: Tab.loyalty) {
                        Label(Tab.loyalty.rawValue, systemImage: Tab.loyalty.icon)
                    }

                    NavigationLink(value: Tab.customerPortal) {
                        Label(Tab.customerPortal.rawValue, systemImage: Tab.customerPortal.icon)
                    }
                }
                
                Section {
                    Text("PRO FEATURES")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 8)
                        .padding(.top, AppTheme.Spacing.sm)
                } header: {
                    EmptyView()
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                
                Section {
                    ForEach([Tab.forms, Tab.sms, Tab.marketing, Tab.employees, Tab.attendance, Tab.reports], id: \.self) { tab in
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
            
            // User info and logout - fixed height footer
            Divider()
            
            HStack(spacing: AppTheme.Spacing.md) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(authService.currentEmployeeName)
                        .font(AppTheme.Typography.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    Text(authService.currentEmployeeRole.rawValue)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                
                Button(action: {
                    authService.logout()
                }) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.red)
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .help("Logout")
            }
            .padding(AppTheme.Spacing.lg)
            .frame(height: 60) // Fixed footer height
            .frame(minWidth: sidebarMinWidth)
            .background(.ultraThinMaterial)
        }
        .frame(minWidth: sidebarMinWidth)
    }
}
