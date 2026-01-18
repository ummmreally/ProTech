//
//  DeviceType.swift
//  ProTech
//
//  Device type definitions matching Supabase enum
//

import Foundation

enum DeviceType: String, CaseIterable, Codable {
    case smartphone
    case tablet
    case computer
    case console = "game_console"
    case wearable
    case other
    
    var displayName: String {
        switch self {
        case .smartphone: return "Smartphone"
        case .tablet: return "Tablet"
        case .computer: return "Computer"
        case .console: return "Game Console"
        case .wearable: return "Wearable"
        case .other: return "Other"
        }
    }
    
    // Helper to safely init from nullable string, defaulting to .other
    static func from(_ string: String?) -> DeviceType {
        guard let string = string?.lowercased() else { return .other }
        
        // Direct match
        if let type = DeviceType(rawValue: string) { return type }
        
        // Fuzzy matching for migration/legacy data
        if string.contains("phone") { return .smartphone }
        if string.contains("pad") || string.contains("tab") { return .tablet }
        if string.contains("mac") || string.contains("book") || string.contains("pc") || string.contains("laptop") { return .computer }
        if string.contains("xbox") || string.contains("playstation") || string.contains("switch") { return .console }
        if string.contains("watch") { return .wearable }
        
        return .other
    }
}
