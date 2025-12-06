//
//  TwilioService.swift
//  TechStorePro
//
//  SMS integration with Twilio API
//  Credentials are hardcoded in SupabaseConfig.swift (TwilioConfig)
//

import Foundation

class TwilioService {
    static let shared = TwilioService()
    
    private init() {}
    
    // MARK: - Configuration (using hardcoded values from TwilioConfig)
    
    var isConfigured: Bool {
        return TwilioConfig.isConfigured
    }
    
    private var accountSID: String {
        TwilioConfig.accountSID
    }
    
    private var authToken: String {
        TwilioConfig.authToken
    }
    
    private var phoneNumber: String {
        TwilioConfig.phoneNumber
    }
    
    // MARK: - Send SMS
    
    func sendSMS(to: String, body: String) async throws -> SMSResult {
        guard isConfigured else {
            throw TwilioError.notConfigured
        }
        
        let from = phoneNumber
        
        // Twilio API endpoint
        let urlString = "\(TwilioConfig.apiBaseURL)/Accounts/\(accountSID)/Messages.json"
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
        guard isConfigured else {
            throw TwilioError.notConfigured
        }
        
        let urlString = "\(TwilioConfig.apiBaseURL)/Accounts/\(accountSID)/Messages.json?PageSize=\(limit)"
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
        guard isConfigured else {
            return .failure(.notConfigured)
        }
        
        do {
            let result = try await sendSMS(
                to: phoneNumber,
                body: "✅ ProTech test message. Setup successful!"
            )
            
            return .success("Test message sent successfully! Message SID: \(result.sid)")
        } catch let error as TwilioError {
            return .failure(error)
        } catch {
            return .failure(.unknown(error.localizedDescription))
        }
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
