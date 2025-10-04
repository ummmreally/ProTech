//
//  SocialMediaOAuthService.swift
//  ProTech
//
//  OAuth authentication for social media platforms
//

import Foundation
import AuthenticationServices

class SocialMediaOAuthService: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = SocialMediaOAuthService()
    
    private override init() {}
    
    // MARK: - ASWebAuthenticationPresentationContextProviding
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return NSApplication.shared.windows.first { $0.isKeyWindow } ?? NSApplication.shared.windows.first!
    }
    
    // MARK: - Platform Configuration
    
    struct PlatformConfig {
        let clientId: String
        let clientSecret: String
        let redirectURI: String
        let authURL: String
        let tokenURL: String
        let scopes: [String]
    }
    
    // MARK: - X/Twitter OAuth 2.0
    
    func authenticateX(completion: @escaping (Result<String, Error>) -> Void) {
        guard let clientId = SecureStorage.retrieve(key: "x_client_id"),
              let clientSecret = SecureStorage.retrieve(key: "x_client_secret") else {
            completion(.failure(OAuthError.missingCredentials))
            return
        }
        
        let config = PlatformConfig(
            clientId: clientId,
            clientSecret: clientSecret,
            redirectURI: "protech://oauth/x",
            authURL: "https://twitter.com/i/oauth2/authorize",
            tokenURL: "https://api.twitter.com/2/oauth2/token",
            scopes: ["tweet.read", "tweet.write", "users.read", "offline.access"]
        )
        
        performOAuth(platform: "X", config: config, completion: completion)
    }
    
    // MARK: - Facebook OAuth
    
    func authenticateFacebook(completion: @escaping (Result<String, Error>) -> Void) {
        guard let clientId = SecureStorage.retrieve(key: "facebook_app_id"),
              let clientSecret = SecureStorage.retrieve(key: "facebook_app_secret") else {
            completion(.failure(OAuthError.missingCredentials))
            return
        }
        
        let config = PlatformConfig(
            clientId: clientId,
            clientSecret: clientSecret,
            redirectURI: "protech://oauth/facebook",
            authURL: "https://www.facebook.com/v18.0/dialog/oauth",
            tokenURL: "https://graph.facebook.com/v18.0/oauth/access_token",
            scopes: ["pages_manage_posts", "pages_read_engagement", "instagram_basic", "instagram_content_publish"]
        )
        
        performOAuth(platform: "Facebook", config: config, completion: completion)
    }
    
    // MARK: - LinkedIn OAuth
    
    func authenticateLinkedIn(completion: @escaping (Result<String, Error>) -> Void) {
        guard let clientId = SecureStorage.retrieve(key: "linkedin_client_id"),
              let clientSecret = SecureStorage.retrieve(key: "linkedin_client_secret") else {
            completion(.failure(OAuthError.missingCredentials))
            return
        }
        
        let config = PlatformConfig(
            clientId: clientId,
            clientSecret: clientSecret,
            redirectURI: "protech://oauth/linkedin",
            authURL: "https://www.linkedin.com/oauth/v2/authorization",
            tokenURL: "https://www.linkedin.com/oauth/v2/accessToken",
            scopes: ["w_member_social", "r_liteprofile", "r_emailaddress"]
        )
        
        performOAuth(platform: "LinkedIn", config: config, completion: completion)
    }
    
    // MARK: - Generic OAuth Flow
    
    private func performOAuth(platform: String, config: PlatformConfig, completion: @escaping (Result<String, Error>) -> Void) {
        // Generate PKCE code verifier and challenge (not used by Facebook)
        let codeVerifier = generateCodeVerifier()
        let codeChallenge = generateCodeChallenge(from: codeVerifier)
        let state = UUID().uuidString
        
        // Build authorization URL
        var components = URLComponents(string: config.authURL)!
        
        // Facebook doesn't support PKCE, so we build query items differently
        if platform == "Facebook" {
            components.queryItems = [
                URLQueryItem(name: "client_id", value: config.clientId),
                URLQueryItem(name: "redirect_uri", value: config.redirectURI),
                URLQueryItem(name: "response_type", value: "code"),
                URLQueryItem(name: "scope", value: config.scopes.joined(separator: ",")),
                URLQueryItem(name: "state", value: state)
            ]
        } else {
            // X/Twitter and LinkedIn support PKCE
            components.queryItems = [
                URLQueryItem(name: "client_id", value: config.clientId),
                URLQueryItem(name: "redirect_uri", value: config.redirectURI),
                URLQueryItem(name: "response_type", value: "code"),
                URLQueryItem(name: "scope", value: config.scopes.joined(separator: " ")),
                URLQueryItem(name: "code_challenge", value: codeChallenge),
                URLQueryItem(name: "code_challenge_method", value: "S256"),
                URLQueryItem(name: "state", value: state)
            ]
        }
        
        guard let authURL = components.url else {
            completion(.failure(OAuthError.invalidURL))
            return
        }
        
        // Use ASWebAuthenticationSession for OAuth
        DispatchQueue.main.async {
            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: "protech"
            ) { callbackURL, error in
                if let error = error {
                    // User cancelled or error occurred
                    completion(.failure(error))
                    return
                }
                
                guard let callbackURL = callbackURL else {
                    completion(.failure(OAuthError.invalidResponse))
                    return
                }
                
                // Extract authorization code from callback URL
                guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                      let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
                    completion(.failure(OAuthError.invalidResponse))
                    return
                }
                
                // Exchange code for access token
                self.exchangeCodeForToken(
                    code: code,
                    codeVerifier: codeVerifier,
                    config: config,
                    platform: platform,
                    completion: completion
                )
            }
            
            // Present the authentication session
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            session.start()
        }
    }
    
    private func exchangeCodeForToken(
        code: String,
        codeVerifier: String,
        config: PlatformConfig,
        platform: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        // Build token request
        let components = URLComponents(string: config.tokenURL)!
        
        var bodyComponents = URLComponents()
        
        // Facebook doesn't use PKCE
        if platform == "Facebook" {
            bodyComponents.queryItems = [
                URLQueryItem(name: "client_id", value: config.clientId),
                URLQueryItem(name: "client_secret", value: config.clientSecret),
                URLQueryItem(name: "code", value: code),
                URLQueryItem(name: "redirect_uri", value: config.redirectURI),
                URLQueryItem(name: "grant_type", value: "authorization_code")
            ]
        } else {
            // X/Twitter and LinkedIn use PKCE
            bodyComponents.queryItems = [
                URLQueryItem(name: "client_id", value: config.clientId),
                URLQueryItem(name: "code", value: code),
                URLQueryItem(name: "redirect_uri", value: config.redirectURI),
                URLQueryItem(name: "grant_type", value: "authorization_code"),
                URLQueryItem(name: "code_verifier", value: codeVerifier)
            ]
        }
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyComponents.query?.data(using: .utf8)
        
        // Add Basic Auth for LinkedIn (but not Facebook)
        if platform == "LinkedIn" {
            let credentials = "\(config.clientId):\(config.clientSecret)"
            if let credentialsData = credentials.data(using: .utf8) {
                let base64Credentials = credentialsData.base64EncodedString()
                request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
            }
        }
        
        // Make token request
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let accessToken = json["access_token"] as? String else {
                completion(.failure(OAuthError.tokenExchangeFailed))
                return
            }
            
            // Save token
            _ = SecureStorage.save(key: "\(platform.lowercased())_access_token", value: accessToken)
            
            // Save refresh token if available
            if let refreshToken = json["refresh_token"] as? String {
                _ = SecureStorage.save(key: "\(platform.lowercased())_refresh_token", value: refreshToken)
            }
            
            completion(.success(accessToken))
        }.resume()
    }
    
    // MARK: - PKCE Helpers
    
    private func generateCodeVerifier() -> String {
        var buffer = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)
        return Data(buffer).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
    }
    
    private func generateCodeChallenge(from verifier: String) -> String {
        guard let data = verifier.data(using: .utf8) else { return "" }
        let hashed = CryptoKit.SHA256.hash(data: data)
        let hashedData = Data(hashed)
        return hashedData.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
    
    // MARK: - Token Management
    
    nonisolated func getAccessToken(for platform: String) -> String? {
        return SecureStorage.retrieve(key: "\(platform.lowercased())_access_token")
    }
    
    func isAuthenticated(for platform: String) -> Bool {
        return getAccessToken(for: platform) != nil
    }
    
    func disconnect(platform: String) {
        _ = SecureStorage.delete(key: "\(platform.lowercased())_access_token")
    }
}

// MARK: - Errors

enum OAuthError: Error {
    case invalidURL
    case authorizationFailed
    case tokenExchangeFailed
    case invalidResponse
    case missingCredentials
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid authorization URL"
        case .authorizationFailed:
            return "Authorization was denied or cancelled"
        case .tokenExchangeFailed:
            return "Failed to exchange authorization code for access token"
        case .invalidResponse:
            return "Received invalid response from server"
        case .missingCredentials:
            return "API credentials not configured. Please go to Settings → Social Media and enter your API keys first."
        }
    }
}

// MARK: - SHA256 Helper

import CryptoKit
