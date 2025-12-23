//
//  GoogleAdsSyncManager.swift
//  ProTech
//
//  Orchestrates synchronization between Square and Google Ads
//

import Foundation
import Combine

class GoogleAdsSyncManager: ObservableObject {
    static let shared = GoogleAdsSyncManager()
    
    @Published var isSyncing = false
    @Published var lastSyncTime: Date?
    @Published var syncStatus: String = "Idle"
    
    private let googleAdsService = GoogleAdsService.shared
    private let squareService = SquareAPIService.shared
    
    private init() {}
    
    // MARK: - Real-time Payment Sync
    
    func handleNewPayment(paymentId: String) async {
        guard GoogleAdsConfig.isConfigured else { return }
        
        do {
            print("Processing payment for Google Ads: \(paymentId)")
            
            // 1. Fetch Payment Details from Square
            let payment = try await squareService.getPayment(paymentId: paymentId)
            
            // Only process completed payments
            guard payment.status == "COMPLETED" else {
                print("Payment \(paymentId) is not completed (Status: \(payment.status ?? "nil"))")
                return
            }
            
            let amount = Double(payment.amountMoney.amount) / 100.0
            let currency = payment.amountMoney.currency
            
            let formatter = ISO8601DateFormatter()
            let date = formatter.date(from: payment.createdAt) ?? Date()
             
            // Extract customer info (from Customer ID or Order)
            var email: String?
            var phone: String?
            
            if let customerId = payment.customerId {
                // Fetch customer details
                if let customer = try? await squareService.getCustomer(customerId: customerId) {
                    email = customer.emailAddress
                    phone = customer.phoneNumber
                }
            }
            
            // If we don't have email/phone, we can't do Enhanced Conversion for Leads
            // Note: In a real POS scenario, customer might not be attached to payment directly
            // but might be in the Order. For now, we rely on Customer ID.
            
            guard email != nil || phone != nil else {
                print("⚠️ Skipping Google Ads sync: No customer email/phone found for payment \(paymentId)")
                return
            }
            
            print("📤 Uploading conversion to Google Ads: \(amount) \(currency)")
            
            // 2. Upload to Google Ads
            // Note: 'conversionActionId' should be configurable or fetched.
            // For now using a placeholder "DEFAULT_CONVERSION_ACTION" which user might need to set in code or config.
            // Ideally, we'd list conversion actions and let user pick one in settings.
            
            try await googleAdsService.uploadOfflineConversion(
                conversionActionId: "DEFAULT_CONVERSION_ACTION",
                amount: amount,
                currencyCode: currency,
                email: email,
                phoneNumber: phone,
                conversionTime: date
            )
            
            print("✅ Google Ads Sync: Successfully uploaded conversion")
            
        } catch {
            print("❌ Failed to sync payment to Google Ads: \(error)")
        }
    }
    
    // MARK: - Customer Match Sync
    
    func syncCustomersToUserList() async {
        guard GoogleAdsConfig.isConfigured else {
            syncStatus = "Configuration missing"
            return
        }
        
        await MainActor.run {
            isSyncing = true
            syncStatus = "Syncing customers..."
        }
        
        do {
            // 1. Fetch all customers from Square (or local DB)
            // Using local Core Data is better as we already sync Square -> Core Data
            
            let context = CoreDataManager.shared.viewContext
            let request = Customer.fetchRequest()
            let customers = try context.fetch(request)
            
            syncStatus = "Found \(customers.count) customers. Uploading..."
            
            // 2. Upload in batches (simulated for now)
            for customer in customers {
                try await googleAdsService.uploadCustomerMatch(
                    userListId: "DEFAULT_USER_LIST", // Needs config
                    email: customer.email,
                    phoneNumber: customer.phone
                )
            }
            
            await MainActor.run {
                lastSyncTime = Date()
                syncStatus = "Sync Completed"
                isSyncing = false
            }
            
        } catch {
            await MainActor.run {
                syncStatus = "Error: \(error.localizedDescription)"
                isSyncing = false
            }
        }
    }
}
