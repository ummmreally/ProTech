//
//  ReportsView.swift
//  ProTech
//
//  Analytics and reports view (Pro feature)
//

import SwiftUI

struct ReportsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Reports & Analytics")
                    .font(.largeTitle)
                    .bold()
                    .padding(.horizontal)
                    .padding(.top)
                
                Text("Coming Soon")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 12) {
                    ReportCard(
                        title: "Customer Growth",
                        description: "Track new customers over time",
                        icon: "chart.line.uptrend.xyaxis"
                    )
                    
                    ReportCard(
                        title: "Revenue Analytics",
                        description: "View revenue trends and projections",
                        icon: "dollarsign.circle"
                    )
                    
                    ReportCard(
                        title: "SMS Statistics",
                        description: "Monitor SMS delivery and engagement",
                        icon: "message.badge"
                    )
                    
                    ReportCard(
                        title: "Form Submissions",
                        description: "Analyze form completion rates",
                        icon: "doc.text.magnifyingglass"
                    )
                }
                .padding(.horizontal)
            }
        }
    }
}

struct ReportCard: View {
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.blue)
                .frame(width: 60, height: 60)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "lock.fill")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}
