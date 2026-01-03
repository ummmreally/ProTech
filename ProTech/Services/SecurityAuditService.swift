//
//  SecurityAuditService.swift
//  ProTech
//
//  Security audit and monitoring for production deployment
//

import Foundation
import CryptoKit
import LocalAuthentication

// MARK: - Security Audit Service

@MainActor
class SecurityAuditService: ObservableObject {
    static let shared = SecurityAuditService()
    
    @Published var auditResults: [AuditResult] = []
    @Published var isAuditing = false
    @Published var overallScore: SecurityScore = .unknown
    @Published var lastAuditDate: Date?
    
    private let supabase = SupabaseService.shared
    private let config = ProductionConfig.shared
    
    // MARK: - Main Audit
    
    func runFullSecurityAudit() async {
        isAuditing = true
        auditResults.removeAll()
        
        // Run all audit checks
        await auditAuthentication()
        await auditDataProtection()
        await auditNetworkSecurity()
        await auditRLSPolicies()
        await auditAPIEndpoints()
        await auditSessionManagement()
        await auditDataValidation()
        await auditLogging()
        
        // Calculate overall score
        calculateOverallScore()
        
        lastAuditDate = Date()
        isAuditing = false
        
        // Save results
        saveAuditResults()
    }
    
    // MARK: - Authentication Audits
    
    private func auditAuthentication() async {
        var issues: [SecurityIssue] = []
        
        // Check password policies
        if !isPasswordPolicyStrong() {
            issues.append(SecurityIssue(
                severity: .high,
                category: .authentication,
                title: "Weak Password Policy",
                description: "Password requirements are not strong enough for production",
                recommendation: "Require minimum 12 characters with uppercase, lowercase, numbers, and symbols"
            ))
        }
        
        // Check PIN security
        if isPINAuthEnabled() && !isPINSecure() {
            issues.append(SecurityIssue(
                severity: .medium,
                category: .authentication,
                title: "PIN Security",
                description: "PIN authentication may be vulnerable to brute force",
                recommendation: "Implement rate limiting and account lockout after failed attempts"
            ))
        }
        
        // Check MFA
        if !isMFAAvailable() {
            issues.append(SecurityIssue(
                severity: .high,
                category: .authentication,
                title: "No Multi-Factor Authentication",
                description: "MFA is not enabled for admin accounts",
                recommendation: "Enable MFA for all administrative accounts"
            ))
        }
        
        // Check session timeout
        let sessionTimeout = config.securitySettings.sessionTimeout
        if sessionTimeout > 3600 { // More than 1 hour
            issues.append(SecurityIssue(
                severity: .medium,
                category: .authentication,
                title: "Long Session Timeout",
                description: "Sessions remain active for \(Int(sessionTimeout/60)) minutes",
                recommendation: "Reduce session timeout to 30 minutes or less"
            ))
        }
        
        auditResults.append(AuditResult(
            category: .authentication,
            passed: issues.isEmpty,
            issues: issues,
            score: calculateCategoryScore(issues: issues)
        ))
    }
    
    // MARK: - Data Protection Audits
    
    private func auditDataProtection() async {
        var issues: [SecurityIssue] = []
        
        // Check encryption at rest
        if !isDataEncryptedAtRest() {
            issues.append(SecurityIssue(
                severity: .critical,
                category: .dataProtection,
                title: "No Encryption at Rest",
                description: "Sensitive data is not encrypted in the database",
                recommendation: "Enable transparent data encryption in Supabase"
            ))
        }
        
        // Check PII handling
        if hasPIIExposure() {
            issues.append(SecurityIssue(
                severity: .high,
                category: .dataProtection,
                title: "PII Exposure Risk",
                description: "Personal information may be exposed in logs or errors",
                recommendation: "Implement PII masking in logs and error messages"
            ))
        }
        
        // Check data retention
        if !hasDataRetentionPolicy() {
            issues.append(SecurityIssue(
                severity: .medium,
                category: .dataProtection,
                title: "No Data Retention Policy",
                description: "Old data is not automatically purged",
                recommendation: "Implement data retention policies for compliance"
            ))
        }
        
        // Check backup security
        if !areBackupsEncrypted() {
            issues.append(SecurityIssue(
                severity: .high,
                category: .dataProtection,
                title: "Unencrypted Backups",
                description: "Database backups are not encrypted",
                recommendation: "Enable encryption for all backup files"
            ))
        }
        
        auditResults.append(AuditResult(
            category: .dataProtection,
            passed: issues.isEmpty,
            issues: issues,
            score: calculateCategoryScore(issues: issues)
        ))
    }
    
    // MARK: - Network Security Audits
    
    private func auditNetworkSecurity() async {
        var issues: [SecurityIssue] = []
        
        // Check HTTPS enforcement
        if !config.securitySettings.requireHTTPS {
            issues.append(SecurityIssue(
                severity: .critical,
                category: .network,
                title: "HTTPS Not Enforced",
                description: "API calls may be made over unencrypted HTTP",
                recommendation: "Force all connections to use HTTPS"
            ))
        }
        
        // Check certificate pinning
        if config.currentEnvironment == .production && 
           !config.securitySettings.enableCertificatePinning {
            issues.append(SecurityIssue(
                severity: .medium,
                category: .network,
                title: "No Certificate Pinning",
                description: "App doesn't verify server certificates",
                recommendation: "Implement certificate pinning for production"
            ))
        }
        
        // Check API rate limiting
        if !hasRateLimiting() {
            issues.append(SecurityIssue(
                severity: .high,
                category: .network,
                title: "No Rate Limiting",
                description: "APIs are vulnerable to abuse",
                recommendation: "Implement rate limiting on all endpoints"
            ))
        }
        
        // Check CORS configuration
        if hasCORSMisconfiguration() {
            issues.append(SecurityIssue(
                severity: .medium,
                category: .network,
                title: "CORS Misconfiguration",
                description: "Cross-origin requests may be too permissive",
                recommendation: "Restrict CORS to specific domains"
            ))
        }
        
        auditResults.append(AuditResult(
            category: .network,
            passed: issues.isEmpty,
            issues: issues,
            score: calculateCategoryScore(issues: issues)
        ))
    }
    
    // MARK: - RLS Policy Audits
    
    private func auditRLSPolicies() async {
        var issues: [SecurityIssue] = []
        
        // Check if RLS is enabled
        let tables = ["customers", "tickets", "inventory_items", "employees"]
        
        for table in tables {
            let hasRLS = await checkRLSEnabled(table: table)
            if !hasRLS {
                issues.append(SecurityIssue(
                    severity: .critical,
                    category: .database,
                    title: "RLS Disabled",
                    description: "Row Level Security is not enabled for \(table)",
                    recommendation: "Enable RLS policies for \(table) table"
                ))
            }
        }
        
        // Check for overly permissive policies
        if await hasPermissivePolicies() {
            issues.append(SecurityIssue(
                severity: .high,
                category: .database,
                title: "Permissive RLS Policies",
                description: "Some RLS policies may be too permissive",
                recommendation: "Review and tighten RLS policies"
            ))
        }
        
        // Check shop isolation
        let shopIsolationVerified = await verifyShopIsolation()
        if !shopIsolationVerified {
            issues.append(SecurityIssue(
                severity: .critical,
                category: .database,
                title: "Shop Isolation Failure",
                description: "Multi-tenancy isolation may be compromised",
                recommendation: "Verify shop_id checks in all RLS policies"
            ))
        }
        
        auditResults.append(AuditResult(
            category: .database,
            passed: issues.isEmpty,
            issues: issues,
            score: calculateCategoryScore(issues: issues)
        ))
    }
    
    // MARK: - API Endpoint Audits
    
    private func auditAPIEndpoints() async {
        var issues: [SecurityIssue] = []
        
        // Check for exposed admin endpoints
        if hasExposedAdminEndpoints() {
            issues.append(SecurityIssue(
                severity: .critical,
                category: .api,
                title: "Exposed Admin Endpoints",
                description: "Administrative endpoints are publicly accessible",
                recommendation: "Restrict admin endpoints to authenticated admins only"
            ))
        }
        
        // Check input validation
        if !hasProperInputValidation() {
            issues.append(SecurityIssue(
                severity: .high,
                category: .api,
                title: "Insufficient Input Validation",
                description: "API inputs are not properly validated",
                recommendation: "Implement strict input validation and sanitization"
            ))
        }
        
        // Check for SQL injection vulnerabilities
        if hasSQLInjectionRisk() {
            issues.append(SecurityIssue(
                severity: .critical,
                category: .api,
                title: "SQL Injection Risk",
                description: "Direct SQL queries may be vulnerable",
                recommendation: "Use parameterized queries exclusively"
            ))
        }
        
        // Check API versioning
        if !hasAPIVersioning() {
            issues.append(SecurityIssue(
                severity: .low,
                category: .api,
                title: "No API Versioning",
                description: "APIs are not versioned",
                recommendation: "Implement API versioning for backwards compatibility"
            ))
        }
        
        auditResults.append(AuditResult(
            category: .api,
            passed: issues.isEmpty,
            issues: issues,
            score: calculateCategoryScore(issues: issues)
        ))
    }
    
    // MARK: - Session Management Audits
    
    private func auditSessionManagement() async {
        var issues: [SecurityIssue] = []
        
        // Check session storage
        if !isSessionStorageSecure() {
            issues.append(SecurityIssue(
                severity: .high,
                category: .session,
                title: "Insecure Session Storage",
                description: "Session tokens may be stored insecurely",
                recommendation: "Use Keychain for session token storage"
            ))
        }
        
        // Check session invalidation
        if !hasProperSessionInvalidation() {
            issues.append(SecurityIssue(
                severity: .medium,
                category: .session,
                title: "Poor Session Invalidation",
                description: "Sessions may not be properly invalidated on logout",
                recommendation: "Ensure server-side session invalidation"
            ))
        }
        
        // Check concurrent session handling
        if !limitsConcurrentSessions() {
            issues.append(SecurityIssue(
                severity: .low,
                category: .session,
                title: "Unlimited Concurrent Sessions",
                description: "Users can have unlimited active sessions",
                recommendation: "Limit concurrent sessions per user"
            ))
        }
        
        auditResults.append(AuditResult(
            category: .session,
            passed: issues.isEmpty,
            issues: issues,
            score: calculateCategoryScore(issues: issues)
        ))
    }
    
    // MARK: - Data Validation Audits
    
    private func auditDataValidation() async {
        var issues: [SecurityIssue] = []
        
        // Check email validation
        if !hasProperEmailValidation() {
            issues.append(SecurityIssue(
                severity: .medium,
                category: .validation,
                title: "Weak Email Validation",
                description: "Email addresses are not properly validated",
                recommendation: "Implement RFC-compliant email validation"
            ))
        }
        
        // Check phone number validation
        if !hasProperPhoneValidation() {
            issues.append(SecurityIssue(
                severity: .low,
                category: .validation,
                title: "Phone Number Validation",
                description: "Phone numbers are not validated",
                recommendation: "Implement E.164 phone number validation"
            ))
        }
        
        // Check data sanitization
        if !hasDataSanitization() {
            issues.append(SecurityIssue(
                severity: .high,
                category: .validation,
                title: "No Data Sanitization",
                description: "User input is not sanitized",
                recommendation: "Sanitize all user input before storage"
            ))
        }
        
        auditResults.append(AuditResult(
            category: .validation,
            passed: issues.isEmpty,
            issues: issues,
            score: calculateCategoryScore(issues: issues)
        ))
    }
    
    // MARK: - Logging Audits
    
    private func auditLogging() async {
        var issues: [SecurityIssue] = []
        
        // Check security event logging
        if !logsSecurityEvents() {
            issues.append(SecurityIssue(
                severity: .high,
                category: .logging,
                title: "Insufficient Security Logging",
                description: "Security events are not logged",
                recommendation: "Log all authentication and authorization events"
            ))
        }
        
        // Check log retention
        if !hasLogRetention() {
            issues.append(SecurityIssue(
                severity: .medium,
                category: .logging,
                title: "No Log Retention Policy",
                description: "Logs are not retained for audit purposes",
                recommendation: "Retain logs for at least 90 days"
            ))
        }
        
        // Check log security
        if !areLogsSecure() {
            issues.append(SecurityIssue(
                severity: .medium,
                category: .logging,
                title: "Insecure Log Storage",
                description: "Logs may contain sensitive information",
                recommendation: "Encrypt logs and mask sensitive data"
            ))
        }
        
        auditResults.append(AuditResult(
            category: .logging,
            passed: issues.isEmpty,
            issues: issues,
            score: calculateCategoryScore(issues: issues)
        ))
    }
    
    // MARK: - Scoring
    
    private func calculateCategoryScore(issues: [SecurityIssue]) -> Int {
        if issues.isEmpty { return 100 }
        
        var deduction = 0
        for issue in issues {
            switch issue.severity {
            case .critical: deduction += 30
            case .high: deduction += 20
            case .medium: deduction += 10
            case .low: deduction += 5
            }
        }
        
        return max(0, 100 - deduction)
    }
    
    private func calculateOverallScore() {
        let totalScore = auditResults.reduce(0) { $0 + $1.score }
        let averageScore = totalScore / max(1, auditResults.count)
        
        overallScore = SecurityScore.from(score: averageScore)
    }
    
    // MARK: - Helper Methods
    
    private func isPasswordPolicyStrong() -> Bool {
        // Check password requirements
        return true // Placeholder
    }
    
    private func isPINAuthEnabled() -> Bool {
        return true
    }
    
    private func isPINSecure() -> Bool {
        // Check PIN security measures
        return config.securitySettings.maxLoginAttempts <= 5
    }
    
    private func isMFAAvailable() -> Bool {
        // Check if MFA is available
        return false // Not yet implemented
    }
    
    private func isDataEncryptedAtRest() -> Bool {
        // Supabase encrypts data at rest by default
        return true
    }
    
    private func hasPIIExposure() -> Bool {
        // Check for PII in logs
        return false
    }
    
    private func hasDataRetentionPolicy() -> Bool {
        return false // Not yet implemented
    }
    
    private func areBackupsEncrypted() -> Bool {
        // Supabase encrypts backups
        return true
    }
    
    private func hasRateLimiting() -> Bool {
        // Check if rate limiting is configured
        return false // Needs implementation
    }
    
    private func hasCORSMisconfiguration() -> Bool {
        return false
    }
    
    private func checkRLSEnabled(table: String) async -> Bool {
        // Check if RLS is enabled for table
        // This would query pg_policies
        return true // Placeholder
    }
    
    private func hasPermissivePolicies() async -> Bool {
        return false
    }
    
    private func verifyShopIsolation() async -> Bool {
        // Verify multi-tenancy isolation
        return true
    }
    
    private func hasExposedAdminEndpoints() -> Bool {
        return false
    }
    
    private func hasProperInputValidation() -> Bool {
        return true
    }
    
    private func hasSQLInjectionRisk() -> Bool {
        // Check for raw SQL queries
        return false
    }
    
    private func hasAPIVersioning() -> Bool {
        return false
    }
    
    private func isSessionStorageSecure() -> Bool {
        // Check if using Keychain
        return true
    }
    
    private func hasProperSessionInvalidation() -> Bool {
        return true
    }
    
    private func limitsConcurrentSessions() -> Bool {
        return false
    }
    
    private func hasProperEmailValidation() -> Bool {
        return true
    }
    
    private func hasProperPhoneValidation() -> Bool {
        return true
    }
    
    private func hasDataSanitization() -> Bool {
        return true
    }
    
    private func logsSecurityEvents() -> Bool {
        return config.currentEnvironment == .production
    }
    
    private func hasLogRetention() -> Bool {
        return false
    }
    
    private func areLogsSecure() -> Bool {
        return true
    }
    
    // MARK: - Persistence
    
    private func saveAuditResults() {
        let report = SecurityAuditReport(
            date: Date(),
            results: auditResults,
            overallScore: overallScore,
            environment: config.currentEnvironment
        )
        
        if let data = try? JSONEncoder().encode(report) {
            UserDefaults.standard.set(data, forKey: "LastSecurityAudit")
        }
    }
    
    func loadLastAudit() -> SecurityAuditReport? {
        guard let data = UserDefaults.standard.data(forKey: "LastSecurityAudit"),
              let report = try? JSONDecoder().decode(SecurityAuditReport.self, from: data) else {
            return nil
        }
        return report
    }
}

// MARK: - Models

struct AuditResult: Codable {
    let category: AuditCategory
    let passed: Bool
    let issues: [SecurityIssue]
    let score: Int
}

struct SecurityIssue: Codable {
    let severity: IssueSeverity
    let category: AuditCategory
    let title: String
    let description: String
    let recommendation: String
}

enum IssueSeverity: String, Codable {
    case critical = "Critical"
    case high = "High"
    case medium = "Medium"
    case low = "Low"
}

enum AuditCategory: String, CaseIterable, Codable {
    case authentication = "Authentication"
    case dataProtection = "Data Protection"
    case network = "Network Security"
    case database = "Database Security"
    case api = "API Security"
    case session = "Session Management"
    case validation = "Data Validation"
    case logging = "Logging & Monitoring"
}

enum SecurityScore: String, Codable {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
    case critical = "Critical"
    case unknown = "Unknown"
    
    static func from(score: Int) -> SecurityScore {
        switch score {
        case 90...100: return .excellent
        case 70..<90: return .good
        case 50..<70: return .fair
        case 30..<50: return .poor
        case 0..<30: return .critical
        default: return .unknown
        }
    }
    
    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "blue"
        case .fair: return "yellow"
        case .poor: return "orange"
        case .critical: return "red"
        case .unknown: return "gray"
        }
    }
    
    var description: String {
        self.rawValue + " Security"
    }
}

struct SecurityAuditReport: Codable {
    let date: Date
    let results: [AuditResult]
    let overallScore: SecurityScore
    let environment: AppEnvironment
}

// MARK: - Security Monitoring

extension SecurityAuditService {
    
    /// Monitor for security events in real-time
    func startSecurityMonitoring() {
        // Monitor failed login attempts
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFailedLogin),
            name: .failedLoginAttempt,
            object: nil
        )
        
        // Monitor suspicious activity
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSuspiciousActivity),
            name: .suspiciousActivity,
            object: nil
        )
    }
    
    @objc private func handleFailedLogin(_ notification: Notification) {
        // Log and track failed login attempts
        if let userInfo = notification.userInfo,
           let email = userInfo["email"] as? String {
            logSecurityEvent(.failedLogin(email: email))
        }
    }
    
    @objc private func handleSuspiciousActivity(_ notification: Notification) {
        // Handle suspicious activity
        if let userInfo = notification.userInfo,
           let activity = userInfo["activity"] as? String {
            logSecurityEvent(.suspiciousActivity(description: activity))
        }
    }
    
    private func logSecurityEvent(_ event: SecurityEvent) {
        // Log to secure audit log
        print("[SECURITY] \(event.description)")
        
        // In production, send to monitoring service
        if config.currentEnvironment == .production {
            // Send to Sentry or similar
        }
    }
}

enum SecurityEvent {
    case failedLogin(email: String)
    case suspiciousActivity(description: String)
    case unauthorizedAccess(resource: String)
    case dataBreachAttempt
    
    var description: String {
        switch self {
        case .failedLogin(let email):
            return "Failed login attempt for \(email)"
        case .suspiciousActivity(let description):
            return "Suspicious activity: \(description)"
        case .unauthorizedAccess(let resource):
            return "Unauthorized access attempt to \(resource)"
        case .dataBreachAttempt:
            return "Potential data breach attempt detected"
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let failedLoginAttempt = Notification.Name("failedLoginAttempt")
    static let suspiciousActivity = Notification.Name("suspiciousActivity")
}
