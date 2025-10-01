//
//  TwilioService.swift
//  TechStorePro
//
//  SMS integration with Twilio API
//

import Foundation

class TwilioService {
    static let shared = TwilioService()
    
    private init() {}
    
    // MARK: - Configuration
    
    var isConfigured: Bool {
        return accountSID != nil && authToken != nil && phoneNumber != nil
    }
    
    private var accountSID: String? {
        SecureStorage.retrieve(key: SecureStorage.Keys.twilioAccountSID)
    }
    
    private var authToken: String? {
        SecureStorage.retrieve(key: SecureStorage.Keys.twilioAuthToken)
    }
    
    private var phoneNumber: String? {
        SecureStorage.retrieve(key: SecureStorage.Keys.twilioPhoneNumber)
    }
    
    // MARK: - Send SMS
    
    func sendSMS(to: String, body: String) async throws -> SMSResult {
        guard let accountSID = accountSID,
              let authToken = authToken,
              let from = phoneNumber else {
            throw TwilioError.notConfigured
        }
        
        // Twilio API endpoint
        let urlString = "\(Configuration.twilioAPIBaseURL)/Accounts/\(accountSID)/Messages.json"
        guard let url = URL(string: urlString) else {
            throw TwilioError.invalidURL
        }
        
        // Prepare request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        
        // Basic Authentication
        let credentials = "\(accountSID):\(authToken)"
        guard let credentialsData = credentials.data(using: .utf8) else {
            throw TwilioError.authenticationFailed
        }
        let base64Credentials = credentialsData.base64EncodedString()
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        
        // Form data
        let parameters = [
            "From": from,
            "To": to,
            "Body": body
        ]
        
        let formBody = parameters
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
        
        request.httpBody = formBody.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Make request
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TwilioError.invalidResponse
            }
            
            // Handle response
            if httpResponse.statusCode == 201 {
                // Success
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let json = try decoder.decode(TwilioMessageResponse.self, from: data)
                return SMSResult(
                    sid: json.sid,
                    status: json.status,
                    to: json.to,
                    from: json.from,
                    body: json.body,
                    dateCreated: json.dateCreated
                )
            } else {
                // Error
                let errorResponse = try? JSONDecoder().decode(TwilioErrorResponse.self, from: data)
                throw TwilioError.apiError(
                    code: errorResponse?.code ?? httpResponse.statusCode,
                    message: errorResponse?.message ?? "Unknown error"
                )
            }
        } catch let error as TwilioError {
            throw error
        } catch {
            throw TwilioError.networkError(error.localizedDescription)
        }
    }
    
    // MARK: - Get Message History
    
    func getMessageHistory(limit: Int = 50) async throws -> [SMSResult] {
        guard let accountSID = accountSID,
              let authToken = authToken else {
            throw TwilioError.notConfigured
        }
        
        let urlString = "\(Configuration.twilioAPIBaseURL)/Accounts/\(accountSID)/Messages.json?PageSize=\(limit)"
        guard let url = URL(string: urlString) else {
            throw TwilioError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Basic Authentication
        let credentials = "\(accountSID):\(authToken)"
        guard let credentialsData = credentials.data(using: .utf8) else {
            throw TwilioError.authenticationFailed
        }
        let base64Credentials = credentialsData.base64EncodedString()
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(TwilioMessagesListResponse.self, from: data)
        
        return response.messages.map { message in
            SMSResult(
                sid: message.sid,
                status: message.status,
                to: message.to,
                from: message.from,
                body: message.body,
                dateCreated: message.dateCreated
            )
        }
    }
    
    // MARK: - Test Connection
    
    func testConnection() async -> Result<String, TwilioError> {
        do {
            guard let phoneNumber = phoneNumber else {
                return .failure(.notConfigured)
            }
            
            let result = try await sendSMS(
                to: phoneNumber,
                body: "✅ TechStore Pro test message. Setup successful!"
            )
            
            return .success("Test message sent successfully! Message SID: \(result.sid)")
        } catch let error as TwilioError {
            return .failure(error)
        } catch {
            return .failure(.unknown(error.localizedDescription))
        }
    }
    
    // MARK: - Configuration Methods
    
    func saveCredentials(accountSID: String, authToken: String, phoneNumber: String) -> Bool {
        let sidSaved = SecureStorage.save(key: SecureStorage.Keys.twilioAccountSID, value: accountSID)
        let tokenSaved = SecureStorage.save(key: SecureStorage.Keys.twilioAuthToken, value: authToken)
        let phoneSaved = SecureStorage.save(key: SecureStorage.Keys.twilioPhoneNumber, value: phoneNumber)
        
        return sidSaved && tokenSaved && phoneSaved
    }
    
    func clearCredentials() {
        _ = SecureStorage.delete(key: SecureStorage.Keys.twilioAccountSID)
        _ = SecureStorage.delete(key: SecureStorage.Keys.twilioAuthToken)
        _ = SecureStorage.delete(key: SecureStorage.Keys.twilioPhoneNumber)
    }
}

// MARK: - Models

struct SMSResult {
    let sid: String
    let status: String
    let to: String
    let from: String
    let body: String
    let dateCreated: String
}

struct TwilioMessageResponse: Codable {
    let sid: String
    let status: String
    let to: String
    let from: String
    let body: String
    let dateCreated: String
}

struct TwilioMessagesListResponse: Codable {
    let messages: [TwilioMessageResponse]
}

struct TwilioErrorResponse: Codable {
    let code: Int
    let message: String
}

// MARK: - Errors

enum TwilioError: LocalizedError {
    case notConfigured
    case invalidURL
    case invalidResponse
    case authenticationFailed
    case apiError(code: Int, message: String)
    case networkError(String)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Twilio is not configured. Please add your credentials in Settings → SMS."
        case .invalidURL:
            return "Invalid Twilio API URL"
        case .invalidResponse:
            return "Invalid response from Twilio"
        case .authenticationFailed:
            return "Authentication failed. Please check your Account SID and Auth Token."
        case .apiError(let code, let message):
            return "Twilio Error \(code): \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .unknown(let message):
            return message
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .notConfigured:
            return "Go to Settings → SMS and enter your Twilio credentials."
        case .authenticationFailed:
            return "Verify your credentials in the Twilio Console."
        case .apiError(let code, _):
            if code == 21211 {
                return "The phone number format is invalid. Use E.164 format: +15551234567"
            } else if code == 21608 {
                return "The phone number is not a valid mobile number."
            }
            return "Check the Twilio documentation for error code \(code)."
        default:
            return nil
        }
    }
}
