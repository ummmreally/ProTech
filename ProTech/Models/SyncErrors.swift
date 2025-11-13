//
//  SyncErrors.swift
//  ProTech
//
//  Shared sync error definitions
//

import Foundation

enum SyncError: Error, LocalizedError {
    case notConfigured
    case mappingNotFound
    case invalidResponse
    case conflict
    case invalidData(String)
    case missingData
    case syncInProgress
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Square sync is not configured"
        case .mappingNotFound:
            return "Item mapping not found"
        case .invalidResponse:
            return "Invalid response from Square"
        case .conflict:
            return "Sync conflict detected"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        case .missingData:
            return "Required data is missing"
        case .syncInProgress:
            return "Sync already in progress"
        }
    }
}
