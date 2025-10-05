//
//  CheckoutSuccessOverlay.swift
//  ProTech
//
//  Payment success overlay with points earned display
//

import SwiftUI

struct CheckoutSuccessOverlay: View {
    let totalAmount: Double
    let pointsEarned: Int32
    let customer: Customer?
    
    var body: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            // Success card
            VStack(spacing: 24) {
                // Success icon
                Circle()
                    .fill(Color.green.gradient)
                    .frame(width: 80, height: 80)
                    .overlay {
                        Image(systemName: "checkmark")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .shadow(color: .green.opacity(0.3), radius: 20, y: 10)
                
                VStack(spacing: 8) {
                    Text("Payment Successful!")
                        .font(.title)
                        .bold()
                    
                    Text("$\(totalAmount, specifier: "%.2f")")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.green)
                }
                
                // Points earned section
                if let customer = customer, pointsEarned > 0 {
                    Divider()
                        .padding(.horizontal, 40)
                    
                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            Image(systemName: "star.fill")
                                .font(.title)
                                .foregroundColor(.yellow)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Loyalty Points Earned")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 6) {
                                    Text("+\(pointsEarned)")
                                        .font(.system(size: 36, weight: .bold))
                                        .foregroundColor(.primary)
                                    Text("points")
                                        .font(.title3)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        Text("for \(customer.firstName ?? "Customer")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(16)
                }
                
                // Thank you message
                VStack(spacing: 4) {
                    Text("Thank you for your purchase!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if customer != nil && pointsEarned > 0 {
                        Text("Check your loyalty rewards to redeem!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(40)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.2), radius: 30, y: 20)
            .frame(maxWidth: 500)
        }
        .transition(.opacity)
        .animation(.easeInOut, value: true)
    }
}
