import Foundation

enum InventoryCategory: String, CaseIterable, Codable {
    case all
    case screens
    case batteries
    case cables
    case chargers
    case cases
    case tools
    case adhesives
    case components
    case accessories
    case other

    var displayName: String {
        switch self {
        case .all: return "All Categories"
        case .screens: return "Screens"
        case .batteries: return "Batteries"
        case .cables: return "Cables"
        case .chargers: return "Chargers"
        case .cases: return "Cases"
        case .tools: return "Tools"
        case .adhesives: return "Adhesives"
        case .components: return "Components"
        case .accessories: return "Accessories"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .screens: return "iphone"
        case .batteries: return "battery.100"
        case .cables: return "cable.connector"
        case .chargers: return "powerplug"
        case .cases: return "square.on.square"
        case .tools: return "wrench.and.screwdriver"
        case .adhesives: return "drop"
        case .components: return "cpu"
        case .accessories: return "headphones"
        case .other: return "shippingbox"
        }
    }
}

extension InventoryItem {
    var inventoryCategory: InventoryCategory {
        InventoryCategory(rawValue: category ?? "other") ?? .other
    }

    func updateCategory(_ newValue: InventoryCategory) {
        category = newValue.rawValue
    }
}
