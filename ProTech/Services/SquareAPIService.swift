//
//  SquareAPIService.swift
//  ProTech
//
//  Service for all Square API interactions
//

import Foundation
import CryptoKit

class SquareAPIService {
    static let shared = SquareAPIService()
    
    private var configuration: SquareConfiguration?
    private let session: URLSession
    
    // OAuth Configuration
    private let clientId = "YOUR_SQUARE_APPLICATION_ID" // Replace with actual app ID
    private let clientSecret = "YOUR_SQUARE_APPLICATION_SECRET" // Store in Keychain
    private let redirectUri = "protech://square-oauth-callback"
    private let scopes = ["ITEMS_READ", "ITEMS_WRITE", "INVENTORY_READ", "INVENTORY_WRITE", "MERCHANT_PROFILE_READ"]
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
    }
    
    func setConfiguration(_ config: SquareConfiguration) {
        self.configuration = config
    }
    
    // MARK: - Authentication
    
    func getAuthorizationURL() -> URL? {
        guard let config = configuration else { return nil }
        
        var components = URLComponents(string: "\(config.baseURL)/oauth2/authorize")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "scope", value: scopes.joined(separator: " ")),
            URLQueryItem(name: "session", value: "false"),
            URLQueryItem(name: "state", value: UUID().uuidString)
        ]
        
        return components?.url
    }
    
    func exchangeCodeForToken(code: String) async throws -> OAuthTokenResponse {
        guard let config = configuration else {
            throw SquareAPIError.notConfigured
        }
        
        let url = URL(string: "\(config.baseURL)/oauth2/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "client_id": clientId,
            "client_secret": clientSecret,
            "code": code,
            "grant_type": "authorization_code"
        ]
        
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
        
        return try JSONDecoder().decode(OAuthTokenResponse.self, from: data)
    }
    
    func refreshAccessToken() async throws -> OAuthTokenResponse {
        guard let config = configuration, let refreshToken = config.refreshToken else {
            throw SquareAPIError.notConfigured
        }
        
        let url = URL(string: "\(config.baseURL)/oauth2/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "client_id": clientId,
            "client_secret": clientSecret,
            "refresh_token": refreshToken,
            "grant_type": "refresh_token"
        ]
        
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
        
        return try JSONDecoder().decode(OAuthTokenResponse.self, from: data)
    }
    
    func validateToken() async throws -> Bool {
        // Test the token by making a simple API call
        do {
            _ = try await listLocations()
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Catalog Operations
    
    func listCatalogItems(cursor: String? = nil, types: [CatalogObjectType] = [.item]) async throws -> CatalogListResponse {
        guard let config = configuration else {
            throw SquareAPIError.notConfigured
        }
        
        var components = URLComponents(string: "\(config.baseURL)/v2/catalog/list")!
        var queryItems: [URLQueryItem] = []
        
        if let cursor = cursor {
            queryItems.append(URLQueryItem(name: "cursor", value: cursor))
        }
        
        if !types.isEmpty {
            queryItems.append(URLQueryItem(name: "types", value: types.map { $0.rawValue }.joined(separator: ",")))
        }
        
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        
        let request = try createAuthenticatedRequest(url: components.url!, method: "GET")
        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
        
        return try JSONDecoder().decode(CatalogListResponse.self, from: data)
    }
    
    func getCatalogItem(objectId: String) async throws -> CatalogObjectResponse {
        guard let config = configuration else {
            throw SquareAPIError.notConfigured
        }
        
        let url = URL(string: "\(config.baseURL)/v2/catalog/object/\(objectId)")!
        let request = try createAuthenticatedRequest(url: url, method: "GET")
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
        
        return try JSONDecoder().decode(CatalogObjectResponse.self, from: data)
    }
    
    func createCatalogItem(_ itemRequest: CatalogItemRequest) async throws -> CatalogObjectResponse {
        guard let config = configuration else {
            throw SquareAPIError.notConfigured
        }
        
        let url = URL(string: "\(config.baseURL)/v2/catalog/object")!
        var request = try createAuthenticatedRequest(url: url, method: "POST")
        request.httpBody = try JSONEncoder().encode(itemRequest)
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
        
        return try JSONDecoder().decode(CatalogObjectResponse.self, from: data)
    }
    
    func updateCatalogItem(objectId: String, itemRequest: CatalogItemRequest) async throws -> CatalogObjectResponse {
        guard let config = configuration else {
            throw SquareAPIError.notConfigured
        }
        
        let url = URL(string: "\(config.baseURL)/v2/catalog/object")!
        var request = try createAuthenticatedRequest(url: url, method: "POST")
        request.httpBody = try JSONEncoder().encode(itemRequest)
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
        
        return try JSONDecoder().decode(CatalogObjectResponse.self, from: data)
    }
    
    func deleteCatalogItem(objectId: String) async throws {
        guard let config = configuration else {
            throw SquareAPIError.notConfigured
        }
        
        let url = URL(string: "\(config.baseURL)/v2/catalog/object/\(objectId)")!
        let request = try createAuthenticatedRequest(url: url, method: "DELETE")
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
    }
    
    func batchUpsertCatalogItems(_ items: [CatalogItemRequest]) async throws -> BatchUpsertResponse {
        guard let config = configuration else {
            throw SquareAPIError.notConfigured
        }
        
        let url = URL(string: "\(config.baseURL)/v2/catalog/batch-upsert")!
        var request = try createAuthenticatedRequest(url: url, method: "POST")
        
        let body: [String: Any] = [
            "idempotency_key": UUID().uuidString,
            "batches": items.map { item in
                ["objects": [item.object]]
            }
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
        
        return try JSONDecoder().decode(BatchUpsertResponse.self, from: data)
    }
    
    // MARK: - Inventory Operations
    
    func getInventoryCount(catalogObjectId: String, locationId: String) async throws -> InventoryCount? {
        let counts = try await batchRetrieveInventoryCounts(catalogObjectIds: [catalogObjectId], locationIds: [locationId])
        return counts.first
    }
    
    func batchRetrieveInventoryCounts(catalogObjectIds: [String], locationIds: [String]? = nil, cursor: String? = nil) async throws -> [InventoryCount] {
        guard let config = configuration else {
            throw SquareAPIError.notConfigured
        }
        
        let url = URL(string: "\(config.baseURL)/v2/inventory/counts/batch-retrieve")!
        var request = try createAuthenticatedRequest(url: url, method: "POST")
        
        let requestBody = BatchRetrieveInventoryCountsRequest(
            catalogObjectIds: catalogObjectIds,
            locationIds: locationIds,
            cursor: cursor
        )
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
        
        let countResponse = try JSONDecoder().decode(InventoryCountResponse.self, from: data)
        return countResponse.counts ?? []
    }
    
    func adjustInventory(adjustment: InventoryAdjustment) async throws -> [InventoryCount] {
        let change = InventoryChange(type: "ADJUSTMENT", physicalCount: nil, adjustment: adjustment)
        return try await batchChangeInventory(changes: [change])
    }
    
    func batchChangeInventory(changes: [InventoryChange]) async throws -> [InventoryCount] {
        guard let config = configuration else {
            throw SquareAPIError.notConfigured
        }
        
        let url = URL(string: "\(config.baseURL)/v2/inventory/changes/batch-create")!
        var request = try createAuthenticatedRequest(url: url, method: "POST")
        
        let requestBody = BatchChangeInventoryRequest(
            idempotencyKey: UUID().uuidString,
            changes: changes,
            ignoreUnchangedCounts: true
        )
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
        
        let changeResponse = try JSONDecoder().decode(InventoryChangeResponse.self, from: data)
        return changeResponse.counts ?? []
    }
    
    func setInventoryCount(catalogObjectId: String, locationId: String, quantity: Int) async throws -> [InventoryCount] {
        guard configuration != nil else {
            throw SquareAPIError.notConfigured
        }
        
        let physicalCount = InventoryPhysicalCount(
            id: nil,
            referenceId: UUID().uuidString,
            catalogObjectId: catalogObjectId,
            catalogObjectType: "ITEM_VARIATION",
            state: .inStock,
            locationId: locationId,
            quantity: String(quantity),
            occurredAt: ISO8601DateFormatter().string(from: Date())
        )
        
        let change = InventoryChange(type: "PHYSICAL_COUNT", physicalCount: physicalCount, adjustment: nil)
        return try await batchChangeInventory(changes: [change])
    }
    
    // MARK: - Webhooks
    
    func registerWebhook(url: String, eventTypes: [String]) async throws -> Webhook {
        guard let config = configuration else {
            throw SquareAPIError.notConfigured
        }
        
        let apiUrl = URL(string: "\(config.baseURL)/v2/webhooks/subscriptions")!
        var request = try createAuthenticatedRequest(url: apiUrl, method: "POST")
        
        let body: [String: Any] = [
            "subscription": [
                "name": "ProTech Inventory Sync",
                "event_types": eventTypes,
                "notification_url": url,
                "api_version": "2023-12-13"
            ],
            "idempotency_key": UUID().uuidString
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
        
        let webhookResponse = try JSONDecoder().decode([String: Webhook].self, from: data)
        guard let webhook = webhookResponse["subscription"] else {
            throw SquareAPIError.invalidResponse
        }
        
        return webhook
    }
    
    func verifyWebhookSignature(body: String, signature: String) -> Bool {
        guard let config = configuration, let signatureKey = config.webhookSignatureKey else {
            return false
        }
        
        guard let bodyData = body.data(using: .utf8),
              let keyData = signatureKey.data(using: .utf8) else {
            return false
        }
        
        let key = SymmetricKey(data: keyData)
        let hmac = HMAC<SHA256>.authenticationCode(for: bodyData, using: key)
        let computedSignature = Data(hmac).base64EncodedString()
        
        return computedSignature == signature
    }
    
    // MARK: - Locations
    
    func listLocations() async throws -> [Location] {
        guard let config = configuration else {
            throw SquareAPIError.notConfigured
        }
        
        let url = URL(string: "\(config.baseURL)/v2/locations")!
        let request = try createAuthenticatedRequest(url: url, method: "GET")
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
        
        let locationResponse = try JSONDecoder().decode(LocationListResponse.self, from: data)
        return locationResponse.locations ?? []
    }
    
    // MARK: - Helper Methods
    
    private func createAuthenticatedRequest(url: URL, method: String) throws -> URLRequest {
        guard let config = configuration, let accessToken = config.accessToken else {
            throw SquareAPIError.notConfigured
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2023-12-13", forHTTPHeaderField: "Square-Version")
        
        return request
    }
    
    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SquareAPIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw SquareAPIError.unauthorized
        case 429:
            throw SquareAPIError.rateLimitExceeded
        default:
            // Try to decode error response
            if let errorResponse = try? JSONDecoder().decode([String: [SquareError]].self, from: data),
               let errors = errorResponse["errors"], let firstError = errors.first {
                throw SquareAPIError.apiError(message: firstError.detail ?? firstError.code)
            }
            throw SquareAPIError.httpError(statusCode: httpResponse.statusCode)
        }
    }
    
    // MARK: - Retry Logic
    
    func retryWithExponentialBackoff<T>(
        maxAttempts: Int = 3,
        initialDelay: TimeInterval = 1.0,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var attempt = 0
        var delay = initialDelay
        
        while attempt < maxAttempts {
            do {
                return try await operation()
            } catch SquareAPIError.rateLimitExceeded {
                attempt += 1
                if attempt >= maxAttempts {
                    throw SquareAPIError.rateLimitExceeded
                }
                
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                delay *= 2
            } catch {
                throw error
            }
        }
        
        fatalError("Should not reach here")
    }
}

// MARK: - Errors

enum SquareAPIError: Error, LocalizedError {
    case notConfigured
    case invalidResponse
    case unauthorized
    case rateLimitExceeded
    case httpError(statusCode: Int)
    case apiError(message: String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Square API is not configured. Please connect your Square account."
        case .invalidResponse:
            return "Invalid response from Square API"
        case .unauthorized:
            return "Unauthorized. Please reconnect your Square account."
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .apiError(let message):
            return "Square API error: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Square Terminal API Extension

extension SquareAPIService {
    
    /// Creates a Terminal Checkout to process payment on Square Terminal/Stand
    func createTerminalCheckout(
        amount: Int, // Amount in cents
        deviceId: String,
        referenceId: String? = nil,
        note: String? = nil
    ) async throws -> TerminalCheckout {
        guard let config = configuration else {
            throw SquareAPIError.notConfigured
        }
        
        let endpoint = "/v2/terminal/checkouts"
        let url = URL(string: "\(config.baseURL)\(endpoint)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2024-10-17", forHTTPHeaderField: "Square-Version")
        
        let checkoutRequest = TerminalCheckoutRequest(
            idempotencyKey: UUID().uuidString,
            checkout: TerminalCheckoutData(
                amountMoney: TerminalMoney(amount: amount, currency: "USD"),
                deviceOptions: DeviceOptions(deviceId: deviceId),
                referenceId: referenceId,
                note: note
            )
        )
        
        request.httpBody = try JSONEncoder().encode(checkoutRequest)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SquareAPIError.networkError(NSError(domain: "Invalid response", code: -1))
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(SquareErrorResponse.self, from: data),
               let firstError = errorResponse.errors?.first {
                throw SquareAPIError.apiError(message: firstError.detail ?? "Terminal checkout creation failed")
            }
            throw SquareAPIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let checkoutResponse = try JSONDecoder().decode(TerminalCheckoutResponse.self, from: data)
        guard let checkout = checkoutResponse.checkout else {
            throw SquareAPIError.apiError(message: "No checkout in response")
        }
        
        return checkout
    }
    
    /// Gets the status of a Terminal Checkout
    func getTerminalCheckout(checkoutId: String) async throws -> TerminalCheckout {
        guard let config = configuration else {
            throw SquareAPIError.notConfigured
        }
        
        let endpoint = "/v2/terminal/checkouts/\(checkoutId)"
        let url = URL(string: "\(config.baseURL)\(endpoint)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(config.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("2024-10-17", forHTTPHeaderField: "Square-Version")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SquareAPIError.networkError(NSError(domain: "Invalid response", code: -1))
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(SquareErrorResponse.self, from: data),
               let firstError = errorResponse.errors?.first {
                throw SquareAPIError.apiError(message: firstError.detail ?? "Failed to get checkout status")
            }
            throw SquareAPIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let checkoutResponse = try JSONDecoder().decode(TerminalCheckoutResponse.self, from: data)
        guard let checkout = checkoutResponse.checkout else {
            throw SquareAPIError.apiError(message: "No checkout in response")
        }
        
        return checkout
    }
    
    /// Cancels a Terminal Checkout
    func cancelTerminalCheckout(checkoutId: String) async throws -> TerminalCheckout {
        guard let config = configuration else {
            throw SquareAPIError.notConfigured
        }
        
        let endpoint = "/v2/terminal/checkouts/\(checkoutId)/cancel"
        let url = URL(string: "\(config.baseURL)\(endpoint)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("2024-10-17", forHTTPHeaderField: "Square-Version")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SquareAPIError.networkError(NSError(domain: "Invalid response", code: -1))
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(SquareErrorResponse.self, from: data),
               let firstError = errorResponse.errors?.first {
                throw SquareAPIError.apiError(message: firstError.detail ?? "Failed to cancel checkout")
            }
            throw SquareAPIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let checkoutResponse = try JSONDecoder().decode(TerminalCheckoutResponse.self, from: data)
        guard let checkout = checkoutResponse.checkout else {
            throw SquareAPIError.apiError(message: "No checkout in response")
        }
        
        return checkout
    }
    
    /// Lists available Terminal devices
    func listTerminalDevices() async throws -> [TerminalDevice] {
        guard let config = configuration else {
            throw SquareAPIError.notConfigured
        }
        
        let endpoint = "/v2/devices/codes"
        let url = URL(string: "\(config.baseURL)\(endpoint)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(config.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("2024-10-17", forHTTPHeaderField: "Square-Version")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SquareAPIError.networkError(NSError(domain: "Invalid response", code: -1))
        }
        
        guard httpResponse.statusCode == 200 else {
            throw SquareAPIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let devicesResponse = try JSONDecoder().decode(TerminalDevicesResponse.self, from: data)
        return devicesResponse.deviceCodes ?? []
    }
}

// MARK: - Terminal API Models

struct SquareErrorResponse: Codable {
    let errors: [SquareError]?
}

struct TerminalCheckoutRequest: Codable {
    let idempotencyKey: String
    let checkout: TerminalCheckoutData
    
    enum CodingKeys: String, CodingKey {
        case idempotencyKey = "idempotency_key"
        case checkout
    }
}

struct TerminalCheckoutData: Codable {
    let amountMoney: TerminalMoney
    let deviceOptions: DeviceOptions
    let referenceId: String?
    let note: String?
    
    enum CodingKeys: String, CodingKey {
        case amountMoney = "amount_money"
        case deviceOptions = "device_options"
        case referenceId = "reference_id"
        case note
    }
}

struct TerminalMoney: Codable {
    let amount: Int // In cents
    let currency: String
}

struct DeviceOptions: Codable {
    let deviceId: String
    
    enum CodingKeys: String, CodingKey {
        case deviceId = "device_id"
    }
}

struct TerminalCheckoutResponse: Codable {
    let checkout: TerminalCheckout?
    let errors: [SquareError]?
}

struct TerminalCheckout: Codable {
    let id: String
    let amountMoney: TerminalMoney
    let referenceId: String?
    let note: String?
    let deviceOptions: DeviceOptions
    let status: String
    let paymentIds: [String]?
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case amountMoney = "amount_money"
        case referenceId = "reference_id"
        case note
        case deviceOptions = "device_options"
        case status
        case paymentIds = "payment_ids"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    var isCompleted: Bool {
        status == "COMPLETED"
    }
    
    var isCanceled: Bool {
        status == "CANCELED"
    }
    
    var isPending: Bool {
        status == "PENDING" || status == "IN_PROGRESS"
    }
}

struct TerminalDevice: Codable, Identifiable {
    let id: String
    let name: String?
    let deviceId: String
    let code: String
    let status: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case deviceId = "device_id"
        case code
        case status
    }
}

struct TerminalDevicesResponse: Codable {
    let deviceCodes: [TerminalDevice]?
    
    enum CodingKeys: String, CodingKey {
        case deviceCodes = "device_codes"
    }
}

// MARK: - Customer API Extension

extension SquareAPIService {
    
    /// Lists all customers with pagination support
    func listCustomers(cursor: String? = nil, limit: Int = 100) async throws -> CustomersListResponse {
        guard let config = configuration else {
            throw SquareAPIError.notConfigured
        }
        
        var components = URLComponents(string: "\(config.baseURL)/v2/customers")!
        var queryItems: [URLQueryItem] = []
        
        if let cursor = cursor {
            queryItems.append(URLQueryItem(name: "cursor", value: cursor))
        }
        
        queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        
        let request = try createAuthenticatedRequest(url: components.url!, method: "GET")
        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
        
        return try JSONDecoder().decode(CustomersListResponse.self, from: data)
    }
    
    /// Searches for customers based on query criteria
    func searchCustomers(query: CustomerQuery? = nil, cursor: String? = nil, limit: Int = 100) async throws -> SearchCustomersResponse {
        guard let config = configuration else {
            throw SquareAPIError.notConfigured
        }
        
        let url = URL(string: "\(config.baseURL)/v2/customers/search")!
        var request = try createAuthenticatedRequest(url: url, method: "POST")
        
        let searchRequest = SearchCustomersRequest(
            limit: limit,
            cursor: cursor,
            query: query
        )
        
        request.httpBody = try JSONEncoder().encode(searchRequest)
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
        
        return try JSONDecoder().decode(SearchCustomersResponse.self, from: data)
    }
    
    /// Gets a specific customer by ID
    func getCustomer(customerId: String) async throws -> SquareCustomer {
        guard let config = configuration else {
            throw SquareAPIError.notConfigured
        }
        
        let url = URL(string: "\(config.baseURL)/v2/customers/\(customerId)")!
        let request = try createAuthenticatedRequest(url: url, method: "GET")
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
        
        let customerResponse = try JSONDecoder().decode(CustomerResponse.self, from: data)
        guard let customer = customerResponse.customer else {
            throw SquareAPIError.apiError(message: "Customer not found")
        }
        
        return customer
    }
    
    /// Creates a new customer
    func createCustomer(
        givenName: String? = nil,
        familyName: String? = nil,
        emailAddress: String? = nil,
        phoneNumber: String? = nil,
        address: SquareAddress? = nil,
        note: String? = nil,
        referenceId: String? = nil
    ) async throws -> SquareCustomer {
        guard let config = configuration else {
            throw SquareAPIError.notConfigured
        }
        
        let url = URL(string: "\(config.baseURL)/v2/customers")!
        var request = try createAuthenticatedRequest(url: url, method: "POST")
        
        let createRequest = CreateCustomerRequest(
            givenName: givenName,
            familyName: familyName,
            emailAddress: emailAddress,
            phoneNumber: phoneNumber,
            address: address,
            note: note,
            referenceId: referenceId,
            idempotencyKey: UUID().uuidString
        )
        
        request.httpBody = try JSONEncoder().encode(createRequest)
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
        
        let customerResponse = try JSONDecoder().decode(CustomerResponse.self, from: data)
        guard let customer = customerResponse.customer else {
            throw SquareAPIError.apiError(message: "Failed to create customer")
        }
        
        return customer
    }
    
    /// Updates an existing customer
    func updateCustomer(
        customerId: String,
        givenName: String? = nil,
        familyName: String? = nil,
        emailAddress: String? = nil,
        phoneNumber: String? = nil,
        address: SquareAddress? = nil,
        note: String? = nil,
        version: Int? = nil
    ) async throws -> SquareCustomer {
        guard let config = configuration else {
            throw SquareAPIError.notConfigured
        }
        
        let url = URL(string: "\(config.baseURL)/v2/customers/\(customerId)")!
        var request = try createAuthenticatedRequest(url: url, method: "PUT")
        
        let updateRequest = UpdateCustomerRequest(
            givenName: givenName,
            familyName: familyName,
            emailAddress: emailAddress,
            phoneNumber: phoneNumber,
            address: address,
            note: note,
            version: version
        )
        
        request.httpBody = try JSONEncoder().encode(updateRequest)
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
        
        let customerResponse = try JSONDecoder().decode(CustomerResponse.self, from: data)
        guard let customer = customerResponse.customer else {
            throw SquareAPIError.apiError(message: "Failed to update customer")
        }
        
        return customer
    }
    
    /// Deletes a customer
    func deleteCustomer(customerId: String) async throws {
        guard let config = configuration else {
            throw SquareAPIError.notConfigured
        }
        
        let url = URL(string: "\(config.baseURL)/v2/customers/\(customerId)")!
        let request = try createAuthenticatedRequest(url: url, method: "DELETE")
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
    }
}
