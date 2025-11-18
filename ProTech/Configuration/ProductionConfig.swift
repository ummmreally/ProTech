//
//  ProductionConfig.swift
//  ProTech
//
//  Production environment configuration and setup
//

import Foundation

// MARK: - Environment Configuration

enum AppEnvironment: String, CaseIterable, Codable {
    case development = "Development"
    case staging = "Staging"
    case production = "Production"
    
    var supabaseURL: String {
        switch self {
        case .development:
            return "https://sztwxxwnhupwmvxhbzyo.supabase.co"
        case .staging:
            // Replace with staging project URL
            return "https://staging-project.supabase.co"
        case .production:
            // Replace with production project URL
            return "https://production-project.supabase.co"
        }
    }
    
    var supabaseAnonKey: String {
        switch self {
        case .development:
            return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN6dHd4eHduaHVwd212eGhienlvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzY5NzMxMjEsImV4cCI6MjA1MjU0OTEyMX0.JQSjAC_-GByJfj-AqpqBylPLdmK9MZy8V-f8vQsCaHc"
        case .staging:
            // Replace with staging anon key
            return "staging-anon-key"
        case .production:
            // Replace with production anon key  
            return "production-anon-key"
        }
    }
    
    var squareEnvironment: SquareEnvironment {
        switch self {
        case .development, .staging:
            return .sandbox
        case .production:
            return .production
        }
    }
    
    var sentryDSN: String? {
        switch self {
        case .development:
            return nil // No Sentry in development
        case .staging:
            return "https://staging-sentry-dsn@sentry.io/project"
        case .production:
            return "https://production-sentry-dsn@sentry.io/project"
        }
    }
    
    var enableDebugLogging: Bool {
        switch self {
        case .development:
            return true
        case .staging:
            return true
        case .production:
            return false
        }
    }
    
    var enableAnalytics: Bool {
        switch self {
        case .development:
            return false
        case .staging:
            return true
        case .production:
            return true
        }
    }
    
    var maxRetryAttempts: Int {
        switch self {
        case .development:
            return 2
        case .staging:
            return 3
        case .production:
            return 5
        }
    }
    
    var syncInterval: TimeInterval {
        switch self {
        case .development:
            return 30 // 30 seconds
        case .staging:
            return 60 // 1 minute
        case .production:
            return 300 // 5 minutes
        }
    }
}

// MARK: - Configuration Manager

class ConfigurationManager {
    static let shared = ConfigurationManager()
    
    // Current environment
    private(set) var currentEnvironment: AppEnvironment {
        didSet {
            saveEnvironment()
            NotificationCenter.default.post(
                name: .environmentChanged,
                object: nil,
                userInfo: ["environment": currentEnvironment]
            )
        }
    }
    
    // Feature flags
    private(set) var featureFlags: FeatureFlags
    
    // Security settings
    private(set) var securitySettings: SecuritySettings
    
    // Performance settings
    private(set) var performanceSettings: PerformanceSettings
    
    private init() {
        // Load saved environment or default to development
        if let saved = UserDefaults.standard.string(forKey: "AppEnvironment"),
           let environment = AppEnvironment(rawValue: saved) {
            self.currentEnvironment = environment
        } else {
            #if DEBUG
            self.currentEnvironment = .development
            #else
            self.currentEnvironment = .production
            #endif
        }
        
        // Load feature flags
        self.featureFlags = FeatureFlags.load()
        
        // Load security settings
        self.securitySettings = SecuritySettings.load()
        
        // Load performance settings
        self.performanceSettings = PerformanceSettings.load()
    }
    
    // MARK: - Environment Management
    
    func switchEnvironment(to environment: AppEnvironment) {
        guard environment != currentEnvironment else { return }
        
        print("Switching from \(currentEnvironment.rawValue) to \(environment.rawValue)")
        
        // Clear cached data
        clearCachedData()
        
        // Update environment
        currentEnvironment = environment
        
        // Reconfigure services
        reconfigureServices()
    }
    
    private func saveEnvironment() {
        UserDefaults.standard.set(currentEnvironment.rawValue, forKey: "AppEnvironment")
    }
    
    private func clearCachedData() {
        // Clear any cached credentials or tokens
        UserDefaults.standard.removeObject(forKey: "SupabaseSession")
        
        // Clear sync queue
        Task { @MainActor in
            OfflineQueueManager.shared.clearQueue()
        }
        
        // Clear any cached API responses
        URLCache.shared.removeAllCachedResponses()
    }
    
    private func reconfigureServices() {
        // Reconfigure Supabase
        Task { @MainActor in
            await SupabaseService.shared.reconfigure(
                url: currentEnvironment.supabaseURL,
                key: currentEnvironment.supabaseAnonKey
            )
        }
        
        // Configure Sentry if available
        if let sentryDSN = currentEnvironment.sentryDSN {
            configureSentry(dsn: sentryDSN)
        }
        
        // Update sync settings
        // TODO: Configure sync interval when SupabaseConfig.syncConfig is available
    }
    
    private func configureSentry(dsn: String) {
        // Configure Sentry error tracking
        // This would integrate with Sentry SDK
        print("Configuring Sentry with DSN: \(dsn)")
    }
    
    // MARK: - Feature Flags
    
    func isFeatureEnabled(_ feature: Feature) -> Bool {
        switch currentEnvironment {
        case .development:
            return true // All features enabled in dev
        case .staging:
            return featureFlags.stagingFeatures.contains(feature)
        case .production:
            return featureFlags.productionFeatures.contains(feature)
        }
    }
    
    func updateFeatureFlag(_ feature: Feature, enabled: Bool, for environment: AppEnvironment) {
        switch environment {
        case .development:
            break // All features always enabled
        case .staging:
            if enabled {
                featureFlags.stagingFeatures.insert(feature)
            } else {
                featureFlags.stagingFeatures.remove(feature)
            }
        case .production:
            if enabled {
                featureFlags.productionFeatures.insert(feature)
            } else {
                featureFlags.productionFeatures.remove(feature)
            }
        }
        
        featureFlags.save()
    }
}

// MARK: - Feature Flags

struct FeatureFlags: Codable {
    var stagingFeatures: Set<Feature>
    var productionFeatures: Set<Feature>
    
    static func load() -> FeatureFlags {
        if let data = UserDefaults.standard.data(forKey: "FeatureFlags"),
           let flags = try? JSONDecoder().decode(FeatureFlags.self, from: data) {
            return flags
        }
        
        // Default feature flags
        return FeatureFlags(
            stagingFeatures: [
                .supabaseSync,
                .realtimeUpdates,
                .teamPresence,
                .offlineMode
            ],
            productionFeatures: [
                .supabaseSync,
                .offlineMode
            ]
        )
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "FeatureFlags")
        }
    }
}

enum Feature: String, Codable, CaseIterable {
    case supabaseSync = "Supabase Sync"
    case realtimeUpdates = "Realtime Updates"
    case teamPresence = "Team Presence"
    case offlineMode = "Offline Mode"
    case advancedAnalytics = "Advanced Analytics"
    case betaFeatures = "Beta Features"
    case debugTools = "Debug Tools"
}

// MARK: - Security Settings

struct SecuritySettings: Codable {
    var requireHTTPS: Bool
    var enableCertificatePinning: Bool
    var maxLoginAttempts: Int
    var sessionTimeout: TimeInterval
    var requireBiometricAuth: Bool
    var enableDataEncryption: Bool
    
    static func load() -> SecuritySettings {
        if let data = UserDefaults.standard.data(forKey: "SecuritySettings"),
           let settings = try? JSONDecoder().decode(SecuritySettings.self, from: data) {
            return settings
        }
        
        // Default security settings
        return SecuritySettings(
            requireHTTPS: true,
            enableCertificatePinning: false,
            maxLoginAttempts: 5,
            sessionTimeout: 1800, // 30 minutes
            requireBiometricAuth: false,
            enableDataEncryption: true
        )
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "SecuritySettings")
        }
    }
}

// MARK: - Performance Settings

struct PerformanceSettings: Codable {
    var enableCaching: Bool
    var cacheExpiration: TimeInterval
    var batchSize: Int
    var maxConcurrentOperations: Int
    var enableCompression: Bool
    var imageQuality: Float
    
    static func load() -> PerformanceSettings {
        if let data = UserDefaults.standard.data(forKey: "PerformanceSettings"),
           let settings = try? JSONDecoder().decode(PerformanceSettings.self, from: data) {
            return settings
        }
        
        // Default performance settings
        return PerformanceSettings(
            enableCaching: true,
            cacheExpiration: 3600, // 1 hour
            batchSize: 100,
            maxConcurrentOperations: 5,
            enableCompression: true,
            imageQuality: 0.8
        )
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "PerformanceSettings")
        }
    }
}

// MARK: - Square Environment

// MARK: - Notification Names

extension Notification.Name {
    static let environmentChanged = Notification.Name("environmentChanged")
}

// MARK: - Environment Validation

extension ConfigurationManager {
    
    /// Validates that the current environment is properly configured
    func validateConfiguration() -> [ConfigurationIssue] {
        var issues: [ConfigurationIssue] = []
        
        // Check Supabase configuration
        if currentEnvironment.supabaseURL.isEmpty {
            issues.append(.missingSupabaseURL)
        }
        
        if currentEnvironment.supabaseAnonKey.isEmpty {
            issues.append(.missingSupabaseKey)
        }
        
        // Check production-specific requirements
        if currentEnvironment == .production {
            if currentEnvironment.sentryDSN == nil {
                issues.append(.missingSentryDSN)
            }
            
            if !securitySettings.requireHTTPS {
                issues.append(.insecureHTTP)
            }
            
            if securitySettings.maxLoginAttempts > 10 {
                issues.append(.excessiveLoginAttempts)
            }
        }
        
        // Check feature flag consistency
        if currentEnvironment == .production {
            let devOnlyFeatures: Set<Feature> = [.debugTools, .betaFeatures]
            let enabledDevFeatures = devOnlyFeatures.intersection(featureFlags.productionFeatures)
            
            if !enabledDevFeatures.isEmpty {
                issues.append(.devFeaturesInProduction(enabledDevFeatures))
            }
        }
        
        return issues
    }
}

enum ConfigurationIssue {
    case missingSupabaseURL
    case missingSupabaseKey
    case missingSentryDSN
    case insecureHTTP
    case excessiveLoginAttempts
    case devFeaturesInProduction(Set<Feature>)
    
    var description: String {
        switch self {
        case .missingSupabaseURL:
            return "Supabase URL is not configured"
        case .missingSupabaseKey:
            return "Supabase API key is not configured"
        case .missingSentryDSN:
            return "Sentry DSN is not configured for production"
        case .insecureHTTP:
            return "HTTPS is not required in production"
        case .excessiveLoginAttempts:
            return "Maximum login attempts is too high"
        case .devFeaturesInProduction(let features):
            return "Development features enabled in production: \(features.map { $0.rawValue }.joined(separator: ", "))"
        }
    }
    
    var severity: IssueSeverity {
        switch self {
        case .missingSupabaseURL, .missingSupabaseKey:
            return .critical
        case .missingSentryDSN, .insecureHTTP:
            return .high
        case .excessiveLoginAttempts:
            return .medium
        case .devFeaturesInProduction:
            return .low
        }
    }
}

// IssueSeverity is now defined in SecurityAuditService.swift

// MARK: - Supabase Service Extension

extension SupabaseService {
    @MainActor
    func reconfigure(url: String, key: String) async {
        // Reconfigure Supabase client with new credentials
        // This would reinitialize the client with new settings
        print("Reconfiguring Supabase with URL: \(url)")
    }
}
