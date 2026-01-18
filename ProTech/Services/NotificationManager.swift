//
//  NotificationManager.swift
//  ProTech
//
//  Manages in-app notifications (toasts) and persistent alerts.
//

import SwiftUI
import Combine

enum NotificationType {
    case info
    case success
    case warning
    case error
    
    var color: Color {
        switch self {
        case .info: return .blue
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .info: return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        }
    }
}

struct AppNotification: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String
    let type: NotificationType
    let date = Date()
    var isRead = false
}

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var notifications: [AppNotification] = []
    @Published var currentToast: AppNotification?
    
    private var toastTimer: Timer?
    
    private init() {}
    
    func post(title: String, message: String, type: NotificationType = .info) {
        let notification = AppNotification(title: title, message: message, type: type)
        
        // Add to persistent list
        notifications.insert(notification, at: 0)
        
        // Show as toast
        showToast(notification)
        
        // Keep list size manageable
        if notifications.count > 50 {
            notifications = Array(notifications.prefix(50))
        }
    }
    
    private func showToast(_ notification: AppNotification) {
        withAnimation {
            currentToast = notification
        }
        
        // Cancel existing timer
        toastTimer?.invalidate()
        
        // Auto-dismiss after 3 seconds
        toastTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                withAnimation {
                    self?.currentToast = nil
                }
            }
        }
    }
    
    func markAllAsRead() {
        var newNotifications: [AppNotification] = []
        for var n in notifications {
            n.isRead = true
            newNotifications.append(n)
        }
        notifications = newNotifications
    }
    
    func remove(_ id: UUID) {
        notifications.removeAll { $0.id == id }
    }
    
    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }
}
