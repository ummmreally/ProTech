//
//  AppLogger.swift
//  ProTech
//
//  Centralized logging infrastructure using OSLog
//

import Foundation
import OSLog

/// A centralized logger that wraps OSLog for structured, performance-optimized logging.
/// usage: AppLogger.info("User logged in", category: .auth)
struct AppLogger {
    
    // MARK: - Categories
    
    enum Category: String {
        case ui = "UI"
        case auth = "Auth"
        case database = "Database"
        case sync = "Sync"
        case network = "Network"
        case general = "General"
        case inventory = "Inventory"
        case customers = "Customers"
    }
    
    // MARK: - Subsystem
    
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.protech.app"
    
    // MARK: - Loggers
    
    private static let uiLogger = Logger(subsystem: subsystem, category: Category.ui.rawValue)
    private static let authLogger = Logger(subsystem: subsystem, category: Category.auth.rawValue)
    private static let dbLogger = Logger(subsystem: subsystem, category: Category.database.rawValue)
    private static let syncLogger = Logger(subsystem: subsystem, category: Category.sync.rawValue)
    private static let networkLogger = Logger(subsystem: subsystem, category: Category.network.rawValue)
    private static let generalLogger = Logger(subsystem: subsystem, category: Category.general.rawValue)
    private static let inventoryLogger = Logger(subsystem: subsystem, category: Category.inventory.rawValue)
    private static let customersLogger = Logger(subsystem: subsystem, category: Category.customers.rawValue)
    
    // MARK: - Helper Methods
    
    private static func logger(for category: Category) -> Logger {
        switch category {
        case .ui: return uiLogger
        case .auth: return authLogger
        case .database: return dbLogger
        case .sync: return syncLogger
        case .network: return networkLogger
        case .general: return generalLogger
        case .inventory: return inventoryLogger
        case .customers: return customersLogger
        }
    }
    
    // MARK: - Logging API
    
    /// Log informational messages (standard usage)
    static func info(_ message: String, category: Category = .general) {
        logger(for: category).info("\(message, privacy: .public)")
    }
    
    /// Log debug messages (verbose, development only)
    static func debug(_ message: String, category: Category = .general) {
        logger(for: category).debug("\(message, privacy: .public)")
    }
    
    /// Log warnings (potential issues)
    static func warning(_ message: String, category: Category = .general) {
        logger(for: category).warning("⚠️ \(message, privacy: .public)")
    }
    
    /// Log errors (something went wrong)
    static func error(_ message: String, error: Error? = nil, category: Category = .general) {
        if let error = error {
            logger(for: category).error("❌ \(message, privacy: .public) - Error: \(error.localizedDescription, privacy: .public)")
        } else {
            logger(for: category).error("❌ \(message, privacy: .public)")
        }
    }
    
    /// Log faults (critical system failures)
    static func fault(_ message: String, category: Category = .general) {
        logger(for: category).fault("💥 \(message, privacy: .public)")
    }
}
