//
//  StripeService.swift
//  ProTech
//
//  Stripe payment processing integration
//

import Foundation
import CoreData

class StripeService {
    static let shared = StripeService()
    
    private let coreDataManager = CoreDataManager.shared
    private var apiKey: String?
    private let baseURL = "https://api.stripe.com/v1"
    
    private init() {
        // Load API key from UserDefaults or Keychain
        loadAPIKey()
    }
    
    // MARK: - Configuration
    
    func configure(apiKey: String) {
        self.apiKey = apiKey
        saveAPIKey(apiKey)
    }
    
    func isConfigured() -> Bool {
        return apiKey != nil && !apiKey!.isEmpty
    }
    
    private func loadAPIKey() {
        // In production, use Keychain for secure storage
        apiKey = UserDefaults.standard.string(forKey: "StripeAPIKey")
    }
    
    private func saveAPIKey(_ key: String) {
        // In production, use Keychain for secure storage
        UserDefaults.standard.set(key, forKey: "StripeAPIKey")
    }
    
    // MARK: - Payment Intent
    
    func createPaymentIntent(amount: Decimal, currency: String = "usd", customerId: UUID?, invoiceId: UUID?, metadata: [String: String] = [:]) async throws -> String {
        guard let apiKey = apiKey else {
            throw StripeError.notConfigured
        }
        
        let amountInCents = Int((amount as NSDecimalNumber).doubleValue * 100)
        
        var parameters = [
            "amount": String(amountInCents),
            "currency": currency
        ]
        
        // Add metadata
        if let invoiceId = invoiceId {
            parameters["metadata[invoice_id]"] = invoiceId.uuidString
        }
        if let customerId = customerId {
            parameters["metadata[customer_id]"] = customerId.uuidString
        }
        for (key, value) in metadata {
            parameters["metadata[\(key)]"] = value
        }
        
        let url = URL(string: "\(baseURL)/payment_intents")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StripeError.networkError
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = try? JSONDecoder().decode(StripeErrorResponse.self, from: data)
            throw StripeError.apiError(errorMessage?.error.message ?? "Unknown error")
        }
        
        let paymentIntent = try JSONDecoder().decode(StripePaymentIntent.self, from: data)
        return paymentIntent.clientSecret
    }
    
    // MARK: - Process Payment
    
    func processPayment(amount: Decimal, currency: String = "USD", customerId: UUID, invoiceId: UUID?, paymentMethodId: String) async throws -> Transaction {
        guard isConfigured() else {
            throw StripeError.notConfigured
        }
        
        // Create payment intent
        let clientSecret = try await createPaymentIntent(
            amount: amount,
            currency: currency.lowercased(),
            customerId: customerId,
            invoiceId: invoiceId
        )
        
        // In a real app, you would use Stripe's SDK to confirm the payment
        // For now, we'll simulate a successful payment
        
        // Extract payment intent ID from client secret
        let paymentIntentId = clientSecret.components(separatedBy: "_secret_").first ?? UUID().uuidString
        
        // Create transaction record
        let context = coreDataManager.viewContext
        let transaction = Transaction(
            context: context,
            transactionId: paymentIntentId,
            invoiceId: invoiceId,
            customerId: customerId,
            amount: amount,
            currency: currency,
            processor: "stripe",
            paymentMethod: "card"
        )
        
        // Simulate successful payment
        transaction.status = "succeeded"
        transaction.processedAt = Date()
        
        // Save payment method details if available
        if let paymentMethod = try? await fetchPaymentMethodDetails(paymentMethodId) {
            transaction.cardBrand = paymentMethod.card?.brand
            transaction.cardLast4 = paymentMethod.card?.last4
        }
        
        try? context.save()
        
        // Create corresponding payment record
        _ = PaymentService.shared.recordPayment(
            invoiceId: invoiceId,
            customerId: customerId,
            amount: amount,
            paymentMethod: "card",
            paymentDate: Date(),
            referenceNumber: paymentIntentId,
            notes: "Processed via Stripe"
        )
        
        return transaction
    }
    
    // MARK: - Payment Methods
    
    func savePaymentMethod(customerId: UUID, paymentMethodId: String) async throws -> PaymentMethod {
        guard isConfigured() else {
            throw StripeError.notConfigured
        }
        
        // Fetch payment method details from Stripe
        let stripePaymentMethod = try await fetchPaymentMethodDetails(paymentMethodId)
        
        // Create local payment method record
        let context = coreDataManager.viewContext
        let paymentMethod = PaymentMethod(
            context: context,
            customerId: customerId,
            paymentMethodId: paymentMethodId,
            type: stripePaymentMethod.type,
            cardBrand: stripePaymentMethod.card?.brand,
            cardLast4: stripePaymentMethod.card?.last4,
            cardExpMonth: stripePaymentMethod.card?.expMonth ?? 0,
            cardExpYear: stripePaymentMethod.card?.expYear ?? 0
        )
        
        // Set as default if it's the first payment method
        let existingMethods = PaymentMethod.fetchPaymentMethods(for: customerId, context: context)
        if existingMethods.isEmpty {
            paymentMethod.isDefault = true
        }
        
        try? context.save()
        
        return paymentMethod
    }
    
    func fetchPaymentMethodDetails(_ paymentMethodId: String) async throws -> StripePaymentMethodDetails {
        guard let apiKey = apiKey else {
            throw StripeError.notConfigured
        }
        
        let url = URL(string: "\(baseURL)/payment_methods/\(paymentMethodId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw StripeError.apiError("Failed to fetch payment method")
        }
        
        return try JSONDecoder().decode(StripePaymentMethodDetails.self, from: data)
    }
    
    func deletePaymentMethod(_ paymentMethod: PaymentMethod) {
        let context = coreDataManager.viewContext
        paymentMethod.isActive = false
        try? context.save()
        
        // Optionally detach from Stripe
        Task {
            try? await detachPaymentMethod(paymentMethod.paymentMethodId ?? "")
        }
    }
    
    private func detachPaymentMethod(_ paymentMethodId: String) async throws {
        guard let apiKey = apiKey else { return }
        
        let url = URL(string: "\(baseURL)/payment_methods/\(paymentMethodId)/detach")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        _ = try await URLSession.shared.data(for: request)
    }
    
    // MARK: - Refunds
    
    func refundTransaction(_ transaction: Transaction, amount: Decimal? = nil) async throws -> Transaction {
        guard isConfigured() else {
            throw StripeError.notConfigured
        }
        
        guard let transactionId = transaction.transactionId else {
            throw StripeError.invalidTransaction
        }
        
        let refundAmount = amount ?? transaction.amount
        let amountInCents = Int((refundAmount as NSDecimalNumber).doubleValue * 100)
        
        let parameters = [
            "payment_intent": transactionId,
            "amount": String(amountInCents)
        ]
        
        let url = URL(string: "\(baseURL)/refunds")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey!)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = body.data(using: .utf8)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw StripeError.apiError("Refund failed")
        }
        
        // Update transaction record
        transaction.refundAmount = refundAmount
        transaction.status = refundAmount == transaction.amount ? "refunded" : "partially_refunded"
        transaction.refundedAt = Date()
        
        try? coreDataManager.viewContext.save()
        
        return transaction
    }
    
    // MARK: - Customer Management
    
    func createStripeCustomer(customerId: UUID, email: String, name: String) async throws -> String {
        guard let apiKey = apiKey else {
            throw StripeError.notConfigured
        }
        
        let parameters = [
            "email": email,
            "name": name,
            "metadata[app_customer_id]": customerId.uuidString
        ]
        
        let url = URL(string: "\(baseURL)/customers")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw StripeError.apiError("Failed to create customer")
        }
        
        let customer = try JSONDecoder().decode(StripeCustomer.self, from: data)
        return customer.id
    }
}

// MARK: - Error Types

enum StripeError: LocalizedError {
    case notConfigured
    case networkError
    case apiError(String)
    case invalidTransaction
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Stripe is not configured. Please add your API key in settings."
        case .networkError:
            return "Network error occurred. Please check your connection."
        case .apiError(let message):
            return "Stripe error: \(message)"
        case .invalidTransaction:
            return "Invalid transaction"
        }
    }
}

// MARK: - Stripe Response Models

struct StripePaymentIntent: Codable {
    let id: String
    let clientSecret: String
    let amount: Int
    let currency: String
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case clientSecret = "client_secret"
        case amount
        case currency
        case status
    }
}

struct StripePaymentMethodDetails: Codable {
    let id: String
    let type: String
    let card: CardDetails?
    
    struct CardDetails: Codable {
        let brand: String
        let last4: String
        let expMonth: Int
        let expYear: Int
        
        enum CodingKeys: String, CodingKey {
            case brand
            case last4
            case expMonth = "exp_month"
            case expYear = "exp_year"
        }
    }
}

struct StripeCustomer: Codable {
    let id: String
    let email: String?
    let name: String?
}

struct StripeErrorResponse: Codable {
    let error: StripeErrorDetail
    
    struct StripeErrorDetail: Codable {
        let message: String
        let type: String?
        let code: String?
    }
}
