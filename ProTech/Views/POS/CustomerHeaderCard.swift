//
//  CustomerHeaderCard.swift
//  ProTech
//
//  Customer info header for right panel in POS
//

import SwiftUI

struct CustomerHeaderCard: View {
    let customer: Customer?
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(customer == nil ? Color.gray.opacity(0.1) : Color.blue.opacity(0.1))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(customer == nil ? .gray : .blue)
                        .font(.system(size: 20))
                )
            
            // Customer Info
            VStack(alignment: .leading, spacing: 3) {
                Text(customerName)
                    .font(.headline)
                    .foregroundColor(Color(hex: "212121"))
                
                HStack(spacing: 4) {
                    Image(systemName: "phone.fill")
                        .font(.caption2)
                        .foregroundColor(Color(hex: "757575"))
                    Text(customerPhone)
                        .font(.caption)
                        .foregroundColor(Color(hex: "757575"))
                }
            }
            
            Spacer()
            
            // Badge
            Text(badgeText)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(badgeColor)
                .cornerRadius(12)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var customerName: String {
        if let customer = customer {
            let firstName = customer.firstName ?? ""
            let lastName = customer.lastName ?? ""
            if !firstName.isEmpty || !lastName.isEmpty {
                return "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
            }
        }
        return "Walk-in Customer"
    }
    
    private var customerPhone: String {
        customer?.phone ?? "No phone number"
    }
    
    private var badgeText: String {
        // Could be enhanced with customer tiers based on purchase history
        customer == nil ? "Walk-in" : "Customer"
    }
    
    private var badgeColor: Color {
        customer == nil ? .gray : Color(hex: "00C853")
    }
}

#Preview("With Customer") {
    CustomerHeaderCard(customer: nil)
        .padding()
}

#Preview("Walk-in") {
    CustomerHeaderCard(customer: nil)
        .padding()
}
