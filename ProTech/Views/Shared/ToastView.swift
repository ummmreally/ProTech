//
//  ToastView.swift
//  ProTech
//
//  Visual component for in-app toasts.
//

import SwiftUI

struct ToastView: View {
    let notification: AppNotification
    var onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: notification.type.icon)
                .font(.title2)
                .foregroundColor(notification.type.color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(notification.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(notification.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .frame(width: 350)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
