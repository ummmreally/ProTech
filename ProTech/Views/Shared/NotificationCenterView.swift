//
//  NotificationCenterView.swift
//  ProTech
//
//  List of past notifications.
//

import SwiftUI

struct NotificationCenterView: View {
    @ObservedObject var manager = NotificationManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Notifications")
                    .font(.headline)
                Spacer()
                if manager.unreadCount > 0 {
                    Button("Mark all read") {
                        manager.markAllAsRead()
                    }
                    .font(.caption)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            if manager.notifications.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "bell.slash")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    Text("No notifications")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                List {
                    ForEach(manager.notifications) { notification in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: notification.type.icon)
                                .foregroundColor(notification.type.color)
                                .padding(.top, 2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(notification.title)
                                    .font(.subheadline)
                                    .bold()
                                    .foregroundColor(notification.isRead ? .secondary : .primary)
                                
                                Text(notification.message)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(notification.date, style: .relative)
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(notification.isRead ? nil : Color.blue.opacity(0.05))
                    }
                    .onDelete { indexSet in
                        // Basic deletion support
                        // manager.remove(at: indexSet) // To be implemented if needed
                    }
                }
                .listStyle(.plain)
            }
        }
        .frame(width: 320, height: 400)
    }
}
