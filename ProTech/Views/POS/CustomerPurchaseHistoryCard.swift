//
//  CustomerPurchaseHistoryCard.swift
//  ProTech
//
//  Displays customer's previous purchase history in POS
//

import SwiftUI

struct CustomerPurchaseHistoryCard: View {
    let purchases: [PurchaseHistory]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "bag.fill")
                    .foregroundColor(Color(hex: "00C853"))
                Text("Previous Purchases")
                    .font(.headline)
                    .foregroundColor(Color(hex: "212121"))
                Spacer()
                Text("(\(purchases.count))")
                    .font(.caption)
                    .foregroundColor(Color(hex: "757575"))
            }
            
            if purchases.isEmpty {
                // Empty state
                VStack(spacing: 8) {
                    Image(systemName: "bag.badge.questionmark")
                        .font(.system(size: 32))
                        .foregroundColor(Color(hex: "757575").opacity(0.4))
                    Text("No purchase history")
                        .font(.caption)
                        .foregroundColor(Color(hex: "757575"))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                // Purchase list
                VStack(spacing: 8) {
                    ForEach(purchases.prefix(5)) { purchase in
                        PurchaseHistoryRow(purchase: purchase)
                    }
                    
                    if purchases.count > 5 {
                        Text("+ \(purchases.count - 5) more purchases")
                            .font(.caption2)
                            .foregroundColor(Color(hex: "757575"))
                            .padding(.top, 4)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct PurchaseHistoryRow: View {
    let purchase: PurchaseHistory
    
    var body: some View {
        HStack(spacing: 10) {
            // Payment method icon
            Image(systemName: purchase.paymentMethodIcon)
                .foregroundColor(Color(hex: "00C853"))
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(purchase.itemCount) item\(purchase.itemCount == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "212121"))
                
                if let date = purchase.purchaseDate {
                    Text(formatDate(date))
                        .font(.caption2)
                        .foregroundColor(Color(hex: "757575"))
                }
            }
            
            Spacer()
            
            Text(purchase.formattedTotal)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color(hex: "212121"))
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(Color(hex: "F5F5F5"))
        .cornerRadius(8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

#Preview {
    CustomerPurchaseHistoryCard(purchases: [])
        .padding()
}
