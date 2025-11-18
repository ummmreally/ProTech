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
    case conflict(details: String? = nil)
    case invalidData(String)
    case missingData
    case syncInProgress
    case notAuthenticated
    case insufficientPermissions
    case networkError(Error)
    case itemNotFound
    case employeeNotFound

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Square sync is not configured"
        case .mappingNotFound:
            return "Item mapping not found"
        case .invalidResponse:
            return "Invalid response from remote service"
        case .conflict(let details):
            if let details, !details.isEmpty {
                return "Sync conflict detected: \(details)"
            }
            return "Sync conflict detected"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        case .missingData:
            return "Required data is missing"
        case .syncInProgress:
            return "Sync already in progress"
        case .notAuthenticated:
            return "Not authenticated with Supabase"
        case .insufficientPermissions:
            return "Insufficient permissions for this operation"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .itemNotFound:
            return "Requested inventory item could not be found"
        case .employeeNotFound:
            return "Requested employee record could not be found"
        }
    }
}
