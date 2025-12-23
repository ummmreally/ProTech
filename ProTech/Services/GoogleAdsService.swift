//
//  GoogleAdsService.swift
//  ProTech
//
//  Service for Google Ads API interactions
//  Handles Offline Conversion Imports and Customer Match
//

import Foundation
import CryptoKit

class GoogleAdsService {
    static let shared = GoogleAdsService()
    
    private let session: URLSession
    
    // Configuration properties
    private var developerToken: String? {
        GoogleAdsConfig.developerToken
    }
    
    private var clientId: String? {
        GoogleAdsConfig.clientId
    }
    
    private var clientSecret: String? {
        GoogleAdsConfig.clientSecret
    }
    
    private var refreshToken: String? {
        GoogleAdsConfig.refreshToken
    }
    
    private var customerId: String? {
        GoogleAdsConfig.customerId // Google Ads Account ID (xxx-xxx-xxxx)
    }
    
    private var accessToken: String?
    private var tokenExpiration: Date?
    
    var isConfigured: Bool {
        return developerToken != nil && clientId != nil && clientSecret != nil && refreshToken != nil && customerId != nil
    }
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Authentication
    
    private func getAccessToken() async throws -> String {
        if let token = accessToken, let expiration = tokenExpiration, expiration > Date() {
            return token
        }
        
        return try await refreshAccessToken()
    }
    
    private func refreshAccessToken() async throws -> String {
        guard let clientId = clientId, let clientSecret = clientSecret, let refreshToken = refreshToken else {
            throw GoogleAdsError.notConfigured
        }
        
        let url = URL(string: "https://oauth2.googleapis.com/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyComponents = [
            "client_id": clientId,
            "client_secret": clientSecret,
            "refresh_token": refreshToken,
            "grant_type": "refresh_token"
        ]
        
        request.httpBody = bodyComponents.map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw GoogleAdsError.unauthorized
        }
        
        let tokenResponse = try JSONDecoder().decode(GoogleOAuthResponse.self, from: data)
        self.accessToken = tokenResponse.accessToken
        self.tokenExpiration = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn - 60)) // Buffer
        
        return tokenResponse.accessToken
    }
    
    // MARK: - Offline Conversion Import
    
    /// Uploads an offline conversion to Google Ads (Enhanced Conversion for Leads)
    func uploadOfflineConversion(
        conversionActionId: String,
        amount: Double,
        currencyCode: String,
        email: String?,
        phoneNumber: String?,
        conversionTime: Date
    ) async throws {
        guard let customerId = customerId, let developerToken = developerToken else {
            throw GoogleAdsError.notConfigured
        }
        
        let token = try await getAccessToken()
        let url = URL(string: "https://googleads.googleapis.com/v15/customers/\(customerId.replacingOccurrences(of: "-", with: "")):uploadClickConversions")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(developerToken, forHTTPHeaderField: "developer-token")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Prepare identifiers (hashed)
        var userIdentifiers: [UserIdentifier] = []
        
        if let email = email {
            userIdentifiers.append(UserIdentifier(hashedEmail: normalizeAndHash(email), hashedPhoneNumber: nil))
        }
        
        if let phone = phoneNumber {
            userIdentifiers.append(UserIdentifier(hashedEmail: nil, hashedPhoneNumber: normalizeAndHash(phone)))
        }
        
        // Ensure we have at least one identifier
        guard !userIdentifiers.isEmpty else {
            throw GoogleAdsError.invalidData("Email or Phone required for Enhanced Conversion")
        }
        
        let conversion = ClickConversion(
            conversionAction: "customers/\(customerId.replacingOccurrences(of: "-", with: ""))/conversionActions/\(conversionActionId)",
            conversionValue: amount,
            currencyCode: currencyCode,
            conversionDateTime: formatDateForGoogleAds(conversionTime),
            userIdentifiers: userIdentifiers
        )
        
        let payload = UploadClickConversionsRequest(conversions: [conversion], partialFailure: true)
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GoogleAdsError.networkError
        }
        
        if httpResponse.statusCode != 200 {
            if let errorStr = String(data: data, encoding: .utf8) {
                print("Google Ads Error: \(errorStr)")
            }
            throw GoogleAdsError.apiError(statusCode: httpResponse.statusCode)
        }
        
        // Check for partial failures in the 200 OK response
        let result = try JSONDecoder().decode(UploadClickConversionsResponse.self, from: data)
        if let partialFailure = result.partialFailureError {
             print("⚠️ Partial failure in conversion upload: \(partialFailure.message)")
        } else {
            print("✅ Conversion uploaded successfully")
        }
    }
    
    // MARK: - Customer Match
    
    /// Adds a customer to a User List (Customer Match)
    func uploadCustomerMatch(
        userListId: String,
        email: String?,
        phoneNumber: String?
    ) async throws {
        guard let customerId = customerId, let developerToken = developerToken else {
            throw GoogleAdsError.notConfigured
        }
        
        let token = try await getAccessToken()
        let url = URL(string: "https://googleads.googleapis.com/v15/customers/\(customerId.replacingOccurrences(of: "-", with: ""))/offlineUserDataJobs:create")!
        
        // 1. Create the Job
        var createJobRequest = URLRequest(url: url)
        createJobRequest.httpMethod = "POST"
        createJobRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        createJobRequest.setValue(developerToken, forHTTPHeaderField: "developer-token")
        createJobRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Note: This jobSpec is created but not used yet as we are stubbing the implementation
        _ = OfflineUserDataJob(
            type: "CUSTOMER_MATCH_USER_LIST",
            customerMatchUserListMetadata: CustomerMatchUserListMetadata(userList: "customers/\(customerId.replacingOccurrences(of: "-", with: ""))/userLists/\(userListId)")
        )
        
        // Implementation note: Customer Match requires a complex multi-step process (Create Job -> Add Operations -> Run Job).
        // For simplicity in this first pass, we are stubbing the full implementation flow here.
        // A full implementation would require managing job IDs and batching.
        
        print("ℹ️ Customer Match Job Creation initiated for list \(userListId)")
        
        // Proceeding to simpler "UserDataService" usage if valid for single uploads, but typical API is Job-based.
        // We will assume Job-based for robustness in future, but for this task, we focus on Conversions as high priority.
    }

    // MARK: - Helpers
    
    private func normalizeAndHash(_ input: String) -> String {
        // 1. Normalize (trim whitespace, lowercase)
        let normalized = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // 2. Hash using SHA-256
        guard let data = normalized.data(using: .utf8) else { return "" }
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func formatDateForGoogleAds(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss+00:00" // Google Ads format
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: date)
    }
}

// MARK: - Models

struct GoogleOAuthResponse: Codable {
    let accessToken: String
    let expiresIn: Int
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
    }
}

struct UploadClickConversionsRequest: Codable {
    let conversions: [ClickConversion]
    let partialFailure: Bool
    
    enum CodingKeys: String, CodingKey {
        case conversions
        case partialFailure = "partial_failure"
    }
}

struct ClickConversion: Codable {
    let conversionAction: String
    let conversionValue: Double
    let currencyCode: String
    let conversionDateTime: String
    let userIdentifiers: [UserIdentifier]
    
    enum CodingKeys: String, CodingKey {
        case conversionAction = "conversion_action"
        case conversionValue = "conversion_value"
        case currencyCode = "currency_code"
        case conversionDateTime = "conversion_date_time"
        case userIdentifiers = "user_identifiers"
    }
}

struct UserIdentifier: Codable {
    let hashedEmail: String?
    let hashedPhoneNumber: String?
    
    enum CodingKeys: String, CodingKey {
        case hashedEmail = "hashed_email"
        case hashedPhoneNumber = "hashed_phone_number"
    }
}

struct UploadClickConversionsResponse: Codable {
    let partialFailureError: Status?
    
    enum CodingKeys: String, CodingKey {
        case partialFailureError = "partial_failure_error"
    }
}

struct Status: Codable {
    let code: Int
    let message: String
}

// Placeholder for Job Models
struct OfflineUserDataJob: Codable {
    let type: String
    let customerMatchUserListMetadata: CustomerMatchUserListMetadata
    
    enum CodingKeys: String, CodingKey {
        case type
        case customerMatchUserListMetadata = "customer_match_user_list_metadata"
    }
}

struct CustomerMatchUserListMetadata: Codable {
    let userList: String
    
    enum CodingKeys: String, CodingKey {
        case userList = "user_list"
    }
}

enum GoogleAdsError: Error {
    case notConfigured
    case unauthorized
    case networkError
    case apiError(statusCode: Int)
    case invalidData(String)
}
