//
//  SquareAPIModels.swift
//  ProTech
//
//  Data models for Square API requests and responses
//

import Foundation

// MARK: - Catalog Models

struct CatalogObject: Codable {
    let id: String
    let type: CatalogObjectType
    let updatedAt: String
    let version: Int
    let isDeleted: Bool?
    let catalogV1Ids: [CatalogV1Id]?
    let itemData: CatalogItem?
    
    enum CodingKeys: String, CodingKey {
        case id, type, version
        case updatedAt = "updated_at"
        case isDeleted = "is_deleted"
        case catalogV1Ids = "catalog_v1_ids"
        case itemData = "item_data"
    }
}

enum CatalogObjectType: String, Codable {
    case item = "ITEM"
    case itemVariation = "ITEM_VARIATION"
    case category = "CATEGORY"
    case discount = "DISCOUNT"
    case tax = "TAX"
    case modifier = "MODIFIER"
    case modifierList = "MODIFIER_LIST"
    case image = "IMAGE"
}

struct CatalogV1Id: Codable {
    let catalogV1Id: String?
    let locationId: String?
    
    enum CodingKeys: String, CodingKey {
        case catalogV1Id = "catalog_v1_id"
        case locationId = "location_id"
    }
}

struct CatalogItem: Codable {
    let name: String
    let description: String?
    let abbreviation: String?
    let labelColor: String?
    let availableOnline: Bool?
    let availableForPickup: Bool?
    let availableElectronically: Bool?
    let categoryId: String?
    let taxIds: [String]?
    let modifierListInfo: [CatalogItemModifierListInfo]?
    let variations: [CatalogItemVariation]?
    let productType: String?
    let skipModifierScreen: Bool?
    let itemOptions: [CatalogItemOptionForItem]?
    
    enum CodingKeys: String, CodingKey {
        case name, description, abbreviation
        case labelColor = "label_color"
        case availableOnline = "available_online"
        case availableForPickup = "available_for_pickup"
        case availableElectronically = "available_electronically"
        case categoryId = "category_id"
        case taxIds = "tax_ids"
        case modifierListInfo = "modifier_list_info"
        case variations
        case productType = "product_type"
        case skipModifierScreen = "skip_modifier_screen"
        case itemOptions = "item_options"
    }
}

struct CatalogItemModifierListInfo: Codable {
    let modifierListId: String
    let enabled: Bool?
    
    enum CodingKeys: String, CodingKey {
        case modifierListId = "modifier_list_id"
        case enabled
    }
}

struct CatalogItemVariation: Codable {
    let id: String?
    let type: String
    let updatedAt: String?
    let version: Int?
    let itemVariationData: ItemVariationData
    
    enum CodingKeys: String, CodingKey {
        case id, type, version
        case updatedAt = "updated_at"
        case itemVariationData = "item_variation_data"
    }
}

struct ItemVariationData: Codable {
    let itemId: String?
    let name: String
    let sku: String?
    let upc: String?
    let ordinal: Int?
    let pricingType: String
    let priceMoney: Money?
    let locationOverrides: [ItemVariationLocationOverrides]?
    let trackInventory: Bool?
    let inventoryAlertType: String?
    let inventoryAlertThreshold: Int?
    let userData: String?
    let serviceDuration: Int?
    let availableForBooking: Bool?
    let itemOptionValues: [CatalogItemOptionValueForItemVariation]?
    let measurementUnitId: String?
    let sellable: Bool?
    let stockable: Bool?
    
    enum CodingKeys: String, CodingKey {
        case name, sku, upc, ordinal
        case itemId = "item_id"
        case pricingType = "pricing_type"
        case priceMoney = "price_money"
        case locationOverrides = "location_overrides"
        case trackInventory = "track_inventory"
        case inventoryAlertType = "inventory_alert_type"
        case inventoryAlertThreshold = "inventory_alert_threshold"
        case userData = "user_data"
        case serviceDuration = "service_duration"
        case availableForBooking = "available_for_booking"
        case itemOptionValues = "item_option_values"
        case measurementUnitId = "measurement_unit_id"
        case sellable, stockable
    }
}

struct ItemVariationLocationOverrides: Codable {
    let locationId: String?
    let priceMoney: Money?
    let pricingType: String?
    let trackInventory: Bool?
    let inventoryAlertType: String?
    let inventoryAlertThreshold: Int?
    
    enum CodingKeys: String, CodingKey {
        case locationId = "location_id"
        case priceMoney = "price_money"
        case pricingType = "pricing_type"
        case trackInventory = "track_inventory"
        case inventoryAlertType = "inventory_alert_type"
        case inventoryAlertThreshold = "inventory_alert_threshold"
    }
}

struct CatalogItemOptionForItem: Codable {
    let itemOptionId: String?
    
    enum CodingKeys: String, CodingKey {
        case itemOptionId = "item_option_id"
    }
}

struct CatalogItemOptionValueForItemVariation: Codable {
    let itemOptionId: String?
    let itemOptionValueId: String?
    
    enum CodingKeys: String, CodingKey {
        case itemOptionId = "item_option_id"
        case itemOptionValueId = "item_option_value_id"
    }
}

struct Money: Codable {
    let amount: Int
    let currency: String
    
    var displayAmount: String {
        let dollars = Double(amount) / 100.0
        return String(format: "$%.2f", dollars)
    }
    
    init(amount: Int, currency: String = "USD") {
        self.amount = amount
        self.currency = currency
    }
    
    init(dollars: Double, currency: String = "USD") {
        self.amount = Int(dollars * 100)
        self.currency = currency
    }
}

// MARK: - Inventory Models

struct InventoryCount: Codable {
    let catalogObjectId: String
    let catalogObjectType: String
    let state: InventoryState
    let locationId: String
    let quantity: String
    let calculatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case catalogObjectId = "catalog_object_id"
        case catalogObjectType = "catalog_object_type"
        case state
        case locationId = "location_id"
        case quantity
        case calculatedAt = "calculated_at"
    }
    
    var quantityInt: Int {
        Int(quantity) ?? 0
    }
}

enum InventoryState: String, Codable {
    case custom = "CUSTOM"
    case inStock = "IN_STOCK"
    case sold = "SOLD"
    case returnedByCustomer = "RETURNED_BY_CUSTOMER"
    case reservedForSale = "RESERVED_FOR_SALE"
    case soldOnline = "SOLD_ONLINE"
    case orderedFromVendor = "ORDERED_FROM_VENDOR"
    case receivedFromVendor = "RECEIVED_FROM_VENDOR"
    case inTransitTo = "IN_TRANSIT_TO"
    case none = "NONE"
    case waste = "WASTE"
    case unlinkedReturn = "UNLINKED_RETURN"
    
    var displayName: String {
        switch self {
        case .custom: return "Custom"
        case .inStock: return "In Stock"
        case .sold: return "Sold"
        case .returnedByCustomer: return "Returned"
        case .reservedForSale: return "Reserved"
        case .soldOnline: return "Sold Online"
        case .orderedFromVendor: return "Ordered"
        case .receivedFromVendor: return "Received"
        case .inTransitTo: return "In Transit"
        case .none: return "None"
        case .waste: return "Waste"
        case .unlinkedReturn: return "Unlinked Return"
        }
    }
}

struct InventoryAdjustment: Codable {
    let idempotencyKey: String
    let type: String
    let state: InventoryState
    let locationId: String
    let catalogObjectId: String
    let catalogObjectType: String
    let quantity: String
    let occurredAt: String
    let referenceId: String?
    
    enum CodingKeys: String, CodingKey {
        case idempotencyKey = "idempotency_key"
        case type, state
        case locationId = "location_id"
        case catalogObjectId = "catalog_object_id"
        case catalogObjectType = "catalog_object_type"
        case quantity
        case occurredAt = "occurred_at"
        case referenceId = "reference_id"
    }
}

struct InventoryChange: Codable {
    let type: String
    let physicalCount: InventoryPhysicalCount?
    let adjustment: InventoryAdjustment?
    
    enum CodingKeys: String, CodingKey {
        case type
        case physicalCount = "physical_count"
        case adjustment
    }
}

struct InventoryPhysicalCount: Codable {
    let id: String?
    let referenceId: String?
    let catalogObjectId: String
    let catalogObjectType: String
    let state: InventoryState
    let locationId: String
    let quantity: String
    let occurredAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case referenceId = "reference_id"
        case catalogObjectId = "catalog_object_id"
        case catalogObjectType = "catalog_object_type"
        case state
        case locationId = "location_id"
        case quantity
        case occurredAt = "occurred_at"
    }
}

// MARK: - API Response Models

struct CatalogListResponse: Codable {
    let objects: [CatalogObject]?
    let cursor: String?
    let errors: [SquareError]?
}

struct CatalogObjectResponse: Codable {
    let object: CatalogObject?
    let relatedObjects: [CatalogObject]?
    let errors: [SquareError]?
    
    enum CodingKeys: String, CodingKey {
        case object
        case relatedObjects = "related_objects"
        case errors
    }
}

struct BatchUpsertResponse: Codable {
    let objects: [CatalogObject]?
    let updatedAt: String?
    let idMappings: [CatalogIdMapping]?
    let errors: [SquareError]?
    
    enum CodingKeys: String, CodingKey {
        case objects
        case updatedAt = "updated_at"
        case idMappings = "id_mappings"
        case errors
    }
}

struct CatalogIdMapping: Codable {
    let clientObjectId: String?
    let objectId: String?
    
    enum CodingKeys: String, CodingKey {
        case clientObjectId = "client_object_id"
        case objectId = "object_id"
    }
}

struct InventoryCountResponse: Codable {
    let counts: [InventoryCount]?
    let cursor: String?
    let errors: [SquareError]?
}

struct InventoryChangeResponse: Codable {
    let counts: [InventoryCount]?
    let errors: [SquareError]?
}

// MARK: - Webhook Models

struct Webhook: Codable {
    let id: String
    let name: String?
    let enabled: Bool
    let eventTypes: [String]
    let notificationUrl: String
    let apiVersion: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, enabled
        case eventTypes = "event_types"
        case notificationUrl = "notification_url"
        case apiVersion = "api_version"
    }
}

struct WebhookEvent: Codable {
    let merchantId: String
    let type: String
    let eventId: String
    let createdAt: String
    let data: WebhookEventData
    
    enum CodingKeys: String, CodingKey {
        case merchantId = "merchant_id"
        case type
        case eventId = "event_id"
        case createdAt = "created_at"
        case data
    }
}

struct WebhookEventData: Codable {
    let type: String
    let id: String
    let object: CatalogObject?
}

// MARK: - Location Models

struct Location: Codable {
    let id: String
    let name: String?
    let address: Address?
    let timezone: String?
    let capabilities: [String]?
    let status: String?
    let createdAt: String?
    let merchantId: String?
    let country: String?
    let languageCode: String?
    let currency: String?
    let phoneNumber: String?
    let businessName: String?
    let type: String?
    let websiteUrl: String?
    let businessHours: BusinessHours?
    
    enum CodingKeys: String, CodingKey {
        case id, name, address, timezone, capabilities, status, country, currency, type
        case createdAt = "created_at"
        case merchantId = "merchant_id"
        case languageCode = "language_code"
        case phoneNumber = "phone_number"
        case businessName = "business_name"
        case websiteUrl = "website_url"
        case businessHours = "business_hours"
    }
}

struct Address: Codable {
    let addressLine1: String?
    let addressLine2: String?
    let locality: String?
    let administrativeDistrictLevel1: String?
    let postalCode: String?
    let country: String?
    
    enum CodingKeys: String, CodingKey {
        case addressLine1 = "address_line_1"
        case addressLine2 = "address_line_2"
        case locality
        case administrativeDistrictLevel1 = "administrative_district_level_1"
        case postalCode = "postal_code"
        case country
    }
}

struct BusinessHours: Codable {
    let periods: [BusinessPeriod]?
}

struct BusinessPeriod: Codable {
    let dayOfWeek: String?
    let startLocalTime: String?
    let endLocalTime: String?
    
    enum CodingKeys: String, CodingKey {
        case dayOfWeek = "day_of_week"
        case startLocalTime = "start_local_time"
        case endLocalTime = "end_local_time"
    }
}

struct LocationListResponse: Codable {
    let locations: [Location]?
    let errors: [SquareError]?
}

// MARK: - OAuth Models

struct OAuthTokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    let expiresAt: String
    let merchantId: String
    let refreshToken: String?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresAt = "expires_at"
        case merchantId = "merchant_id"
        case refreshToken = "refresh_token"
    }
}

// MARK: - Error Models

struct SquareError: Codable {
    let category: String
    let code: String
    let detail: String?
    let field: String?
}

// MARK: - Request Models

struct CatalogItemRequest: Codable {
    let idempotencyKey: String
    let object: CatalogObject
    
    enum CodingKeys: String, CodingKey {
        case idempotencyKey = "idempotency_key"
        case object
    }
}

struct BatchRetrieveInventoryCountsRequest: Codable {
    let catalogObjectIds: [String]
    let locationIds: [String]?
    let cursor: String?
    
    enum CodingKeys: String, CodingKey {
        case catalogObjectIds = "catalog_object_ids"
        case locationIds = "location_ids"
        case cursor
    }
}

struct BatchChangeInventoryRequest: Codable {
    let idempotencyKey: String
    let changes: [InventoryChange]
    let ignoreUnchangedCounts: Bool?
    
    enum CodingKeys: String, CodingKey {
        case idempotencyKey = "idempotency_key"
        case changes
        case ignoreUnchangedCounts = "ignore_unchanged_counts"
    }
}
