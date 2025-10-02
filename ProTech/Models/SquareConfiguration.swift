//
//  SquareConfiguration.swift
//  ProTech
//
//  Stores Square API credentials and sync settings
//

import Foundation
import SwiftData

@Model
class SquareConfiguration {
    @Attribute(.unique) var id: UUID
    var accessToken: String
    var refreshToken: String?
    var merchantId: String
    var locationId: String
    var locationName: String?
    var environment: SquareEnvironment
    var syncEnabled: Bool
    var syncInterval: TimeInterval
    var lastFullSync: Date?
    var webhookSignatureKey: String?
    var webhookSubscriptionId: String?
    var defaultConflictResolution: ConflictResolutionStrategy
    var defaultSyncDirection: SyncDirection
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        accessToken: String,
        refreshToken: String? = nil,
        merchantId: String,
        locationId: String,
        locationName: String? = nil,
        environment: SquareEnvironment = .sandbox,
        syncEnabled: Bool = true,
        syncInterval: TimeInterval = 3600,
        lastFullSync: Date? = nil,
        webhookSignatureKey: String? = nil,
        webhookSubscriptionId: String? = nil,
        defaultConflictResolution: ConflictResolutionStrategy = .mostRecent,
        defaultSyncDirection: SyncDirection = .bidirectional,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.merchantId = merchantId
        self.locationId = locationId
        self.locationName = locationName
        self.environment = environment
        self.syncEnabled = syncEnabled
        self.syncInterval = syncInterval
        self.lastFullSync = lastFullSync
        self.webhookSignatureKey = webhookSignatureKey
        self.webhookSubscriptionId = webhookSubscriptionId
        self.defaultConflictResolution = defaultConflictResolution
        self.defaultSyncDirection = defaultSyncDirection
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    var isConfigured: Bool {
        !accessToken.isEmpty && !merchantId.isEmpty && !locationId.isEmpty
    }
    
    var baseURL: String {
        environment.baseURL
    }
}

enum SquareEnvironment: String, Codable {
    case sandbox
    case production
    
    var displayName: String {
        switch self {
        case .sandbox: return "Sandbox (Testing)"
        case .production: return "Production (Live)"
        }
    }
    
    var baseURL: String {
        switch self {
        case .sandbox: return "https://connect.squareupsandbox.com"
        case .production: return "https://connect.squareup.com"
        }
    }
}

// MARK: - Sync Interval Presets

extension TimeInterval {
    static let fifteenMinutes: TimeInterval = 900
    static let thirtyMinutes: TimeInterval = 1800
    static let oneHour: TimeInterval = 3600
    static let fourHours: TimeInterval = 14400
    static let daily: TimeInterval = 86400
    
    var syncIntervalDisplayName: String {
        switch self {
        case .fifteenMinutes: return "15 Minutes"
        case .thirtyMinutes: return "30 Minutes"
        case .oneHour: return "1 Hour"
        case .fourHours: return "4 Hours"
        case .daily: return "Daily"
        default: return "\(Int(self / 60)) Minutes"
        }
    }
}
