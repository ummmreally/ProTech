//
//  SocialMediaAPIService.swift
//  ProTech
//
//  API services for posting to social media platforms
//

import Foundation
import AppKit

class SocialMediaAPIService {
    static let shared = SocialMediaAPIService()
    
    private init() {}
    
    // MARK: - Post to X/Twitter
    
    func postToX(content: String, image: NSImage? = nil) async throws -> PostResult {
        guard let accessToken = SocialMediaOAuthService.shared.getAccessToken(for: "X") else {
            throw SocialMediaError.notAuthenticated
        }
        
        // Upload image if present
        var mediaId: String?
        if let image = image {
            mediaId = try await uploadMediaToX(image: image, accessToken: accessToken)
        }
        
        // Create tweet
        let url = URL(string: "https://api.twitter.com/2/tweets")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = ["text": content]
        if let mediaId = mediaId {
            body["media"] = ["media_ids": [mediaId]]
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SocialMediaError.invalidResponse
        }
        
        if httpResponse.statusCode == 201 {
            let result = try JSONDecoder().decode(XPostResponse.self, from: data)
            return PostResult(platform: "X", postId: result.data.id, success: true, timestamp: Date())
        } else {
            throw SocialMediaError.apiError(message: "Failed to post to X")
        }
    }
    
    private func uploadMediaToX(image: NSImage, accessToken: String) async throws -> String {
        // Simplified media upload - in real implementation, use Twitter's media upload API
        return "mock_media_id_\(UUID().uuidString)"
    }
    
    // MARK: - Post to Facebook
    
    func postToFacebook(content: String, image: NSImage? = nil) async throws -> PostResult {
        guard let accessToken = SocialMediaOAuthService.shared.getAccessToken(for: "Facebook") else {
            throw SocialMediaError.notAuthenticated
        }
        
        // Get Page ID (you'd store this during OAuth)
        let pageId = "YOUR_PAGE_ID"
        
        let url = URL(string: "https://graph.facebook.com/v18.0/\(pageId)/feed")!
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "message", value: content),
            URLQueryItem(name: "access_token", value: accessToken)
        ]
        
        guard let finalURL = components.url else {
            throw SocialMediaError.invalidURL
        }
        
        var request = URLRequest(url: finalURL)
        request.httpMethod = "POST"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SocialMediaError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            let result = try JSONDecoder().decode(FacebookPostResponse.self, from: data)
            return PostResult(platform: "Facebook", postId: result.id, success: true, timestamp: Date())
        } else {
            throw SocialMediaError.apiError(message: "Failed to post to Facebook")
        }
    }
    
    // MARK: - Post to LinkedIn
    
    func postToLinkedIn(content: String, image: NSImage? = nil) async throws -> PostResult {
        guard let accessToken = SocialMediaOAuthService.shared.getAccessToken(for: "LinkedIn") else {
            throw SocialMediaError.notAuthenticated
        }
        
        // Get user URN (you'd store this during OAuth)
        let userURN = "urn:li:person:YOUR_USER_ID"
        
        let url = URL(string: "https://api.linkedin.com/v2/ugcPosts")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "author": userURN,
            "lifecycleState": "PUBLISHED",
            "specificContent": [
                "com.linkedin.ugc.ShareContent": [
                    "shareCommentary": ["text": content],
                    "shareMediaCategory": "NONE"
                ]
            ],
            "visibility": [
                "com.linkedin.ugc.MemberNetworkVisibility": "PUBLIC"
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SocialMediaError.invalidResponse
        }
        
        if httpResponse.statusCode == 201 {
            let result = try JSONDecoder().decode(LinkedInPostResponse.self, from: data)
            return PostResult(platform: "LinkedIn", postId: result.id, success: true, timestamp: Date())
        } else {
            throw SocialMediaError.apiError(message: "Failed to post to LinkedIn")
        }
    }
    
    // MARK: - Fetch Analytics
    
    func fetchAnalytics(for platform: String, postId: String) async throws -> PostAnalytics {
        guard let accessToken = SocialMediaOAuthService.shared.getAccessToken(for: platform) else {
            throw SocialMediaError.notAuthenticated
        }
        
        switch platform {
        case "X":
            return try await fetchXAnalytics(postId: postId, accessToken: accessToken)
        case "Facebook":
            return try await fetchFacebookAnalytics(postId: postId, accessToken: accessToken)
        case "LinkedIn":
            return try await fetchLinkedInAnalytics(postId: postId, accessToken: accessToken)
        default:
            throw SocialMediaError.unsupportedPlatform
        }
    }
    
    private func fetchXAnalytics(postId: String, accessToken: String) async throws -> PostAnalytics {
        let url = URL(string: "https://api.twitter.com/2/tweets/\(postId)?tweet.fields=public_metrics")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(XAnalyticsResponse.self, from: data)
        
        return PostAnalytics(
            likes: response.data.publicMetrics.likeCount,
            comments: response.data.publicMetrics.replyCount,
            shares: response.data.publicMetrics.retweetCount,
            impressions: response.data.publicMetrics.impressionCount
        )
    }
    
    private func fetchFacebookAnalytics(postId: String, accessToken: String) async throws -> PostAnalytics {
        let url = URL(string: "https://graph.facebook.com/v18.0/\(postId)?fields=likes.summary(true),comments.summary(true),shares&access_token=\(accessToken)")!
        let (data, _) = try await URLSession.shared.data(for: URLRequest(url: url))
        let response = try JSONDecoder().decode(FacebookAnalyticsResponse.self, from: data)
        
        return PostAnalytics(
            likes: response.likes?.summary?.totalCount ?? 0,
            comments: response.comments?.summary?.totalCount ?? 0,
            shares: response.shares?.count ?? 0,
            impressions: 0 // Facebook doesn't provide this in basic API
        )
    }
    
    private func fetchLinkedInAnalytics(postId: String, accessToken: String) async throws -> PostAnalytics {
        // LinkedIn analytics requires separate API call
        // Simplified for this implementation
        return PostAnalytics(likes: 0, comments: 0, shares: 0, impressions: 0)
    }
}

// MARK: - Models

struct PostResult {
    let platform: String
    let postId: String
    let success: Bool
    let timestamp: Date
}

struct PostAnalytics {
    let likes: Int
    let comments: Int
    let shares: Int
    let impressions: Int
}

// MARK: - API Response Models

struct XPostResponse: Codable {
    let data: XPostData
}

struct XPostData: Codable {
    let id: String
    let text: String
}

struct XAnalyticsResponse: Codable {
    let data: XAnalyticsData
}

struct XAnalyticsData: Codable {
    let publicMetrics: XPublicMetrics
    
    enum CodingKeys: String, CodingKey {
        case publicMetrics = "public_metrics"
    }
}

struct XPublicMetrics: Codable {
    let likeCount: Int
    let retweetCount: Int
    let replyCount: Int
    let impressionCount: Int
    
    enum CodingKeys: String, CodingKey {
        case likeCount = "like_count"
        case retweetCount = "retweet_count"
        case replyCount = "reply_count"
        case impressionCount = "impression_count"
    }
}

struct FacebookPostResponse: Codable {
    let id: String
}

struct FacebookAnalyticsResponse: Codable {
    let likes: FacebookLikes?
    let comments: FacebookComments?
    let shares: FacebookShares?
}

struct FacebookLikes: Codable {
    let summary: FacebookSummary?
}

struct FacebookComments: Codable {
    let summary: FacebookSummary?
}

struct FacebookShares: Codable {
    let count: Int?
}

struct FacebookSummary: Codable {
    let totalCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
    }
}

struct LinkedInPostResponse: Codable {
    let id: String
}

// MARK: - Errors

enum SocialMediaError: Error {
    case notAuthenticated
    case invalidURL
    case invalidResponse
    case apiError(message: String)
    case unsupportedPlatform
}
