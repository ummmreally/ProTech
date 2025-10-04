//
//  SquareCustomerModels.swift
//  ProTech
//
//  Models for Square Customers API
//

import Foundation

// MARK: - Customer Response Models

struct SquareCustomer: Codable, Identifiable {
    let id: String
    let createdAt: String?
    let updatedAt: String?
    let givenName: String?
    let familyName: String?
    let emailAddress: String?
    let phoneNumber: String?
    let address: SquareAddress?
    let note: String?
    let referenceId: String?
    let version: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case givenName = "given_name"
        case familyName = "family_name"
        case emailAddress = "email_address"
        case phoneNumber = "phone_number"
        case address
        case note
        case referenceId = "reference_id"
        case version
    }
}

struct SquareAddress: Codable {
    let addressLine1: String?
    let addressLine2: String?
    let addressLine3: String?
    let locality: String?
    let sublocality: String?
    let administrativeDistrictLevel1: String?
    let postalCode: String?
    let country: String?
    
    enum CodingKeys: String, CodingKey {
        case addressLine1 = "address_line_1"
        case addressLine2 = "address_line_2"
        case addressLine3 = "address_line_3"
        case locality
        case sublocality
        case administrativeDistrictLevel1 = "administrative_district_level_1"
        case postalCode = "postal_code"
        case country
    }
    
    var formattedAddress: String {
        var components: [String] = []
        if let line1 = addressLine1 { components.append(line1) }
        if let line2 = addressLine2 { components.append(line2) }
        if let city = locality, let state = administrativeDistrictLevel1, let zip = postalCode {
            components.append("\(city), \(state) \(zip)")
        }
        return components.joined(separator: ", ")
    }
}

// MARK: - Request Models

struct CreateCustomerRequest: Codable {
    let givenName: String?
    let familyName: String?
    let emailAddress: String?
    let phoneNumber: String?
    let address: SquareAddress?
    let note: String?
    let referenceId: String?
    let idempotencyKey: String
    
    enum CodingKeys: String, CodingKey {
        case givenName = "given_name"
        case familyName = "family_name"
        case emailAddress = "email_address"
        case phoneNumber = "phone_number"
        case address
        case note
        case referenceId = "reference_id"
        case idempotencyKey = "idempotency_key"
    }
}

struct UpdateCustomerRequest: Codable {
    let givenName: String?
    let familyName: String?
    let emailAddress: String?
    let phoneNumber: String?
    let address: SquareAddress?
    let note: String?
    let version: Int?
    
    enum CodingKeys: String, CodingKey {
        case givenName = "given_name"
        case familyName = "family_name"
        case emailAddress = "email_address"
        case phoneNumber = "phone_number"
        case address
        case note
        case version
    }
}

struct SearchCustomersRequest: Codable {
    let limit: Int?
    let cursor: String?
    let query: CustomerQuery?
    
    enum CodingKeys: String, CodingKey {
        case limit
        case cursor
        case query
    }
}

struct CustomerQuery: Codable {
    let filter: CustomerFilter?
    let sort: CustomerSort?
    
    enum CodingKeys: String, CodingKey {
        case filter
        case sort
    }
}

struct CustomerFilter: Codable {
    let createdAt: TimeRange?
    let updatedAt: TimeRange?
    let emailAddress: CustomerTextFilter?
    let phoneNumber: CustomerTextFilter?
    
    enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case emailAddress = "email_address"
        case phoneNumber = "phone_number"
    }
}

struct CustomerTextFilter: Codable {
    let exact: String?
    let fuzzy: String?
    
    enum CodingKeys: String, CodingKey {
        case exact
        case fuzzy
    }
}

struct TimeRange: Codable {
    let startAt: String?
    let endAt: String?
    
    enum CodingKeys: String, CodingKey {
        case startAt = "start_at"
        case endAt = "end_at"
    }
}

struct CustomerSort: Codable {
    let field: String?
    let order: String?
    
    enum CodingKeys: String, CodingKey {
        case field
        case order
    }
}

// MARK: - Response Models

struct CustomerResponse: Codable {
    let customer: SquareCustomer?
    let errors: [SquareError]?
}

struct CustomersListResponse: Codable {
    let customers: [SquareCustomer]?
    let cursor: String?
    let errors: [SquareError]?
}

struct SearchCustomersResponse: Codable {
    let customers: [SquareCustomer]?
    let cursor: String?
    let errors: [SquareError]?
}

struct DeleteCustomerResponse: Codable {
    let errors: [SquareError]?
}
