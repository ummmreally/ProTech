//
//  SharedSettingsComponents.swift
//  ProTech
//
//  Shared UI components for settings views
//

import SwiftUI

// MARK: - Info Row

struct InfoRow: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.blue)
                .frame(width: 24, height: 24)
                .overlay {
                    Text(number)
                        .font(.caption)
                        .bold()
                        .foregroundColor(.white)
                }
            Text(text)
                .font(.body)
        }
    }
}
