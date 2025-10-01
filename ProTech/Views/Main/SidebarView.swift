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
    
    var body: some View {
        List(selection: $selectedTab) {
            Section("Overview") {
                ForEach([Tab.dashboard, Tab.queue, Tab.customers], id: \.self) { tab in
                    NavigationLink(value: tab) {
                        Label(tab.rawValue, systemImage: tab.icon)
                    }
                }
            }
            
            Section("Pro Features") {
                ForEach([Tab.forms, Tab.sms, Tab.reports], id: \.self) { tab in
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
    }
}
