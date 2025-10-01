//
//  SubscriptionView.swift
//  ProTech
//
//  Subscription upgrade/purchase view
//

import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                    .symbolRenderingMode(.hierarchical)
                
                Text("Upgrade to Pro")
                    .font(.largeTitle)
                    .bold()
                
                Text("Unlock all premium features")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            .padding(.bottom, 30)
            
            // Features List
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(PremiumFeature.allCases, id: \.self) { feature in
                        HStack(spacing: 12) {
                            Image(systemName: feature.icon)
                                .font(.title3)
                                .foregroundColor(.orange)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(feature.rawValue)
                                    .font(.headline)
                                Text(feature.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 40)
            }
            
            Spacer()
            
            // Products
            if subscriptionManager.isLoading {
                ProgressView("Loading products...")
                    .padding()
            } else if subscriptionManager.errorMessage != nil {
                VStack(spacing: 12) {
                    Text("Unable to load products")
                        .foregroundColor(.secondary)
                    Button("Try Again") {
                        Task {
                            await subscriptionManager.loadProducts()
                        }
                    }
                }
                .padding()
            } else if !subscriptionManager.products.isEmpty {
                VStack(spacing: 12) {
                    ForEach(subscriptionManager.products, id: \.id) { product in
                        Button {
                            Task {
                                _ = try? await subscriptionManager.purchase(product)
                                if subscriptionManager.isProSubscriber {
                                    dismiss()
                                }
                            }
                        } label: {
                            ProductButton(product: product)
                        }
                        .buttonStyle(.plain)
                        .disabled(subscriptionManager.isLoading)
                    }
                }
                .padding(.horizontal, 40)
                
                Text("7-day free trial • Cancel anytime")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            } else {
                Text("No products available")
                    .foregroundColor(.secondary)
                    .padding()
            }
            
            // Footer buttons
            HStack(spacing: 20) {
                Button("Restore Purchases") {
                    Task {
                        await subscriptionManager.restorePurchases()
                        if subscriptionManager.isProSubscriber {
                            dismiss()
                        }
                    }
                }
                .font(.caption)
                
                Button("Close") {
                    dismiss()
                }
                .font(.caption)
            }
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
        .frame(width: 600, height: 700)
    }
}

// MARK: - Product Button

struct ProductButton: View {
    let product: Product
    
    var body: some View {
        VStack(spacing: 8) {
            Text(product.displayName)
                .font(.headline)
            
            Text(product.displayPrice)
                .font(.title2)
                .bold()
            
            if let subscription = product.subscription {
                Text("per \(subscription.subscriptionPeriod.unit.localizedDescription)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            if product.id == Configuration.monthlySubscriptionID {
                Text("Most Popular")
                    .font(.caption2)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.orange.gradient)
        .foregroundColor(.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, y: 2)
    }
}

// MARK: - Subscription Period Extension

extension Product.SubscriptionPeriod.Unit {
    var localizedDescription: String {
        switch self {
        case .day: return "day"
        case .week: return "week"
        case .month: return "month"
        case .year: return "year"
        @unknown default: return ""
        }
    }
}
