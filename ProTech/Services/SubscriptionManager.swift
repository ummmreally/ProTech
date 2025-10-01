//
//  SubscriptionManager.swift
//  TechStorePro
//
//  StoreKit 2 subscription management
//

import Foundation
import StoreKit

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var updateListenerTask: Task<Void, Error>?
    
    var isProSubscriber: Bool {
        // Check developer override first
        if UserDefaults.standard.bool(forKey: "developerProModeEnabled") {
            return true
        }
        return !purchasedProductIDs.isEmpty
    }
    
    var hasActiveSubscription: Bool {
        !purchasedProductIDs.isEmpty
    }
    
    private init() {
        guard Configuration.enableStoreKit else {
            updateListenerTask = nil
            return
        }
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()
        
        Task {
            await loadProducts()
            await checkSubscriptionStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Load Products
    
    func loadProducts() async {
        guard Configuration.enableStoreKit else {
            isLoading = false
            errorMessage = nil
            products = []
            return
        }
        isLoading = true
        errorMessage = nil
        
        do {
            let productIDs = [
                Configuration.monthlySubscriptionID,
                Configuration.annualSubscriptionID
            ]
            
            let loadedProducts = try await Product.products(for: productIDs)
            
            // Sort by price (lowest first)
            products = loadedProducts.sorted { $0.price < $1.price }
            
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            print("Error loading products: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Purchase
    
    func purchase(_ product: Product) async throws -> Bool {
        guard Configuration.enableStoreKit else { return false }
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                
                // Update purchased products
                await updatePurchasedProducts()
                
                // Finish the transaction
                await transaction.finish()
                
                isLoading = false
                return true
                
            case .userCancelled:
                isLoading = false
                return false
                
            case .pending:
                isLoading = false
                errorMessage = "Purchase is pending approval"
                return false
                
            @unknown default:
                isLoading = false
                return false
            }
        } catch {
            isLoading = false
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async {
        guard Configuration.enableStoreKit else { return }
        isLoading = true
        errorMessage = nil
        
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
            isLoading = false
        } catch {
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    // MARK: - Check Subscription Status
    
    func checkSubscriptionStatus() async {
        await updatePurchasedProducts()
    }
    
    private func updatePurchasedProducts() async {
        guard Configuration.enableStoreKit else {
            purchasedProductIDs = []
            return
        }
        let purchased = await loadPurchasedProductIDs()
        purchasedProductIDs = purchased
    }

    nonisolated private func loadPurchasedProductIDs() async -> Set<String> {
        guard Configuration.enableStoreKit else { return [] }
        var purchased: Set<String> = []
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.productType == .autoRenewable {
                    if let expirationDate = transaction.expirationDate,
                       expirationDate > Date() {
                        purchased.insert(transaction.productID)
                    }
                } else {
                    purchased.insert(transaction.productID)
                }
            } catch {
                print("Transaction verification failed: \(error)")
            }
        }
        return purchased
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Error> {
        guard Configuration.enableStoreKit else { return Task { } }
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updatePurchasedProducts()
                    await transaction.finish()
                } catch {
                    print("Transaction update failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Verification
    
    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Feature Access
    
    func hasAccess(to feature: PremiumFeature) -> Bool {
        return isProSubscriber
    }
    
    func requireProAccess(for feature: PremiumFeature, onUpgrade: @escaping () -> Void) -> Bool {
        if isProSubscriber {
            return true
        } else {
            // Show upgrade prompt
            onUpgrade()
            return false
        }
    }
    
    // MARK: - Subscription Info
    
    func getSubscriptionInfo() async -> SubscriptionInfo? {
        guard Configuration.enableStoreKit else { return nil }
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if let product = products.first(where: { $0.id == transaction.productID }),
                   let expirationDate = transaction.expirationDate {
                    let isActive = expirationDate > Date()
                    let willRenew = transaction.revocationDate == nil
                    return SubscriptionInfo(
                        productName: product.displayName,
                        productID: product.id,
                        price: product.displayPrice,
                        expirationDate: expirationDate,
                        isActive: isActive,
                        willRenew: willRenew
                    )
                }
            } catch {
                continue
            }
        }
        return nil
    }
}

// MARK: - Models

struct SubscriptionInfo {
    let productName: String
    let productID: String
    let price: String
    let expirationDate: Date
    let isActive: Bool
    let willRenew: Bool
    
    var formattedExpirationDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: expirationDate)
    }
    
    var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day ?? 0
    }
}

// MARK: - Errors

enum SubscriptionError: LocalizedError {
    case failedVerification
    case productNotFound
    
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaction verification failed"
        case .productNotFound:
            return "Product not found"
        }
    }
}
