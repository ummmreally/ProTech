//
//  ConfigurationErrorView.swift
//  ProTech
//
//  Blocking view shown when critical configuration is missing
//

import SwiftUI

struct ConfigurationErrorView: View {
    let issues: [ConfigurationIssue]
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.red)
            
            Text("Configuration Error")
                .font(.largeTitle)
                .bold()
            
            Text("The application cannot start due to the following configuration issues:")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 10) {
                ForEach(issues, id: \.description) { issue in
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                        Text(issue.description)
                            .font(.body)
                    }
                }
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(8)
            
            Button("Retry") {
                // In a real app, this might re-trigger validation
                // For now, we just rely on app restart or state change
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: 500)
    }
}
