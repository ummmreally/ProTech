//
//  SquareProxyService.swift
//  Centralized Square API access via Supabase Edge Function
//
//  Use this service in ALL 3 apps (ProTech, iScale, EScale)
//

import Foundation
import Supabase

class SquareProxyService {
    private let supabase: SupabaseClient
    private let supabaseURL: URL
    private let supabaseKey: String
    
    init(supabase: SupabaseClient, supabaseURL: URL? = nil, supabaseKey: String? = nil) {
        self.supabase = supabase
        
        let env = ProductionConfig.shared.currentEnvironment
        
        // Use provided URL/Key or fallback to Environment configuration
        self.supabaseURL = supabaseURL ?? URL(string: env.supabaseURL)!
        self.supabaseKey = supabaseKey ?? env.supabaseAnonKey
    }
    
    // MARK: - Generic Request
    
    private func callSquareProxy(action: String, data: [String: Any]? = nil) async throws -> [String: Any] {
        // Create a dynamic Encodable wrapper for the payload
        struct DynamicPayload: Encodable {
            let action: String
            let data: AnyCodable?
            
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(action, forKey: .action)
                if let data = data {
                    try container.encode(data, forKey: .data)
                }
            }
            
            enum CodingKeys: String, CodingKey {
                case action, data
            }
        }
        
        let payload = DynamicPayload(
            action: action,
            data: data.map { AnyCodable($0) }
        )
        
        // Encode payload to JSON
        let encoder = JSONEncoder()
        let payloadData = try encoder.encode(payload)
        
        // Invoke function using URLSession-based approach
        let functionURL = supabaseURL.appendingPathComponent("functions/v1/square-proxy")
        
        var request = URLRequest(url: functionURL)
        request.httpMethod = "POST"
        request.httpBody = payloadData
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw SquareProxyError.invalidResponse
        }
        
        if let error = json["error"] as? String {
            throw SquareProxyError.apiError(error)
        }
        
        return json
    }
    
    // MARK: - Catalog Items
    
    func listCatalogItems() async throws -> [SquareCatalogItem] {
        let result = try await callSquareProxy(action: "listCatalog")
        guard let objects = result["objects"] as? [[String: Any]] else {
            return []
        }
        return objects.compactMap { SquareCatalogItem(json: $0) }
    }
    
    func searchCatalogItems(query: String) async throws -> [SquareCatalogItem] {
        let searchData: [String: Any] = [
            "query": [
                "text_query": [
                    "keywords": [query]
                ]
            ]
        ]
        let result = try await callSquareProxy(action: "searchCatalog", data: searchData)
        guard let objects = result["objects"] as? [[String: Any]] else {
            return []
        }
        return objects.compactMap { SquareCatalogItem(json: $0) }
    }
    
    func createCatalogItem(name: String, price: Int, sku: String?) async throws -> SquareCatalogItem {
        let itemData: [String: Any] = [
            "type": "ITEM",
            "item_data": [
                "name": name,
                "variations": [
                    [
                        "type": "ITEM_VARIATION",
                        "item_variation_data": [
                            "name": "Regular",
                            "pricing_type": "FIXED_PRICING",
                            "price_money": [
                                "amount": price,
                                "currency": "USD"
                            ],
                            "sku": sku ?? ""
                        ]
                    ]
                ]
            ]
        ]
        
        let result = try await callSquareProxy(action: "createCatalogItem", data: itemData)
        guard let object = result["catalog_object"] as? [String: Any],
              let item = SquareCatalogItem(json: object) else {
            throw SquareProxyError.invalidResponse
        }
        return item
    }
    
    func updateCatalogItem(id: String, name: String?, price: Int?) async throws -> SquareCatalogItem {
        var itemData: [String: Any] = [
            "type": "ITEM",
            "id": id,
            "item_data": [:]
        ]
        
        var itemDataDict: [String: Any] = [:]
        if let name = name {
            itemDataDict["name"] = name
        }
        if let price = price {
            itemDataDict["variations"] = [
                [
                    "type": "ITEM_VARIATION",
                    "item_variation_data": [
                        "pricing_type": "FIXED_PRICING",
                        "price_money": [
                            "amount": price,
                            "currency": "USD"
                        ]
                    ]
                ]
            ]
        }
        itemData["item_data"] = itemDataDict
        
        let result = try await callSquareProxy(action: "updateCatalogItem", data: itemData)
        guard let object = result["catalog_object"] as? [String: Any],
              let item = SquareCatalogItem(json: object) else {
            throw SquareProxyError.invalidResponse
        }
        return item
    }
    
    // MARK: - Inventory
    
    func listInventory() async throws -> [SquareInventoryCount] {
        let result = try await callSquareProxy(action: "listInventory")
        guard let counts = result["counts"] as? [[String: Any]] else {
            return []
        }
        return counts.compactMap { SquareInventoryCount(json: $0) }
    }
    
    func adjustInventory(catalogObjectId: String, quantity: Int, reason: String = "RESTOCK") async throws {
        let changeData: [String: Any] = [
            "changes": [
                [
                    "type": "ADJUSTMENT",
                    "adjustment": [
                        "catalog_object_id": catalogObjectId,
                        "from_state": "IN_STOCK",
                        "to_state": "IN_STOCK",
                        "quantity": String(quantity),
                        "occurred_at": ISO8601DateFormatter().string(from: Date())
                    ]
                ]
            ]
        ]
        _ = try await callSquareProxy(action: "adjustInventory", data: changeData)
    }
    
    // MARK: - Customers
    
    func listCustomers(cursor: String? = nil, limit: Int = 100) async throws -> SquareCustomerList {
        var params: [String: Any] = ["limit": limit]
        if let cursor = cursor {
            params["cursor"] = cursor
        }
        let result = try await callSquareProxy(action: "listCustomers", data: params)
        
        let customers = (result["customers"] as? [[String: Any]])?.compactMap { SquareCustomer(json: $0) } ?? []
        let nextCursor = result["cursor"] as? String
        
        return SquareCustomerList(customers: customers, cursor: nextCursor)
    }
    
    func searchCustomers(query: String) async throws -> [SquareCustomer] {
        let searchData: [String: Any] = [
            "query": [
                "filter": [
                    "email_address": ["fuzzy": query],
                    "phone_number": ["fuzzy": query]
                ]
            ]
        ]
        let result = try await callSquareProxy(action: "searchCustomers", data: searchData)
        guard let customers = result["customers"] as? [[String: Any]] else {
            return []
        }
        return customers.compactMap { SquareCustomer(json: $0) }
    }
    
    func createCustomer(firstName: String, lastName: String, email: String?, phone: String?) async throws -> SquareCustomer {
        var customerData: [String: Any] = [
            "given_name": firstName,
            "family_name": lastName
        ]
        if let email = email {
            customerData["email_address"] = email
        }
        if let phone = phone {
            customerData["phone_number"] = phone
        }
        
        let result = try await callSquareProxy(action: "createCustomer", data: customerData)
        guard let customer = result["customer"] as? [String: Any],
              let squareCustomer = SquareCustomer(json: customer) else {
            throw SquareProxyError.invalidResponse
        }
        return squareCustomer
    }
    
    // MARK: - Orders
    
    func createOrder(customerId: String?, lineItems: [[String: Any]]) async throws -> ProxySquareOrder {
        var orderData: [String: Any] = [
            "line_items": lineItems
        ]
        if let customerId = customerId {
            orderData["customer_id"] = customerId
        }
        
        let result = try await callSquareProxy(action: "createOrder", data: orderData)
        guard let order = result["order"] as? [String: Any],
              let squareOrder = ProxySquareOrder(json: order) else {
            throw SquareProxyError.invalidResponse
        }
        return squareOrder
    }
    
    func searchOrders(startDate: Date? = nil, endDate: Date? = nil) async throws -> [ProxySquareOrder] {
        var searchData: [String: Any] = [
            "query": [
                "sort": [
                    "sort_field": "CREATED_AT",
                    "sort_order": "DESC"
                ]
            ]
        ]
        
        if let startDate = startDate, let endDate = endDate {
            let formatter = ISO8601DateFormatter()
            searchData["query"] = [
                "filter": [
                    "date_time_filter": [
                        "created_at": [
                            "start_at": formatter.string(from: startDate),
                            "end_at": formatter.string(from: endDate)
                        ]
                    ]
                ]
            ]
        }
        
        let result = try await callSquareProxy(action: "searchOrders", data: searchData)
        guard let orders = result["orders"] as? [[String: Any]] else {
            return []
        }
        return orders.compactMap { ProxySquareOrder(json: $0) }
    }
    
    // MARK: - Locations
    
    func listLocations() async throws -> [SquareLocation] {
        let result = try await callSquareProxy(action: "listLocations")
        guard let locations = result["locations"] as? [[String: Any]] else {
            return []
        }
        return locations.compactMap { SquareLocation(json: $0) }
    }
}

// MARK: - Models

struct SquareCatalogItem: Codable {
    let id: String
    let name: String
    let sku: String?
    let price: Int?
    
    init?(json: [String: Any]) {
        guard let id = json["id"] as? String,
              let itemData = json["item_data"] as? [String: Any],
              let name = itemData["name"] as? String else {
            return nil
        }
        
        self.id = id
        self.name = name
        
        if let variations = itemData["variations"] as? [[String: Any]],
           let firstVariation = variations.first,
           let variationData = firstVariation["item_variation_data"] as? [String: Any] {
            self.sku = variationData["sku"] as? String
            if let priceMoney = variationData["price_money"] as? [String: Any] {
                self.price = priceMoney["amount"] as? Int
            } else {
                self.price = nil
            }
        } else {
            self.sku = nil
            self.price = nil
        }
    }
}

struct SquareInventoryCount: Codable {
    let catalogObjectId: String
    let quantity: String
    let locationId: String
    
    init?(json: [String: Any]) {
        guard let catalogObjectId = json["catalog_object_id"] as? String,
              let quantity = json["quantity"] as? String,
              let locationId = json["location_id"] as? String else {
            return nil
        }
        
        self.catalogObjectId = catalogObjectId
        self.quantity = quantity
        self.locationId = locationId
    }
}

// SquareCustomer is defined in Models/SquareCustomerModels.swift

struct SquareCustomerList {
    let customers: [SquareCustomer]
    let cursor: String?
}

struct ProxySquareOrder: Codable {
    let id: String
    let totalMoney: Int?
    let createdAt: String
    
    init?(json: [String: Any]) {
        guard let id = json["id"] as? String,
              let createdAt = json["created_at"] as? String else {
            return nil
        }
        
        self.id = id
        self.createdAt = createdAt
        
        if let totalMoney = json["total_money"] as? [String: Any],
           let amount = totalMoney["amount"] as? Int {
            self.totalMoney = amount
        } else {
            self.totalMoney = nil
        }
    }
}

struct SquareLocation: Codable {
    let id: String
    let name: String
    let address: String?
    
    init?(json: [String: Any]) {
        guard let id = json["id"] as? String,
              let name = json["name"] as? String else {
            return nil
        }
        
        self.id = id
        self.name = name
        
        if let address = json["address"] as? [String: Any],
           let addressLine1 = address["address_line_1"] as? String {
            self.address = addressLine1
        } else {
            self.address = nil
        }
    }
}

// MARK: - Errors

enum SquareProxyError: Error, LocalizedError {
    case invalidResponse
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from Square API"
        case .apiError(let message):
            return "Square API error: \(message)"
        }
    }
}
