//
//  DiscountCodeService.swift
//  ProTech
//
//  Service for managing and validating discount codes
//

import Foundation
import CoreData

class DiscountCodeService {
    static let shared = DiscountCodeService()
    
    private let coreDataManager = CoreDataManager.shared
    private var context: NSManagedObjectContext {
        coreDataManager.viewContext
    }
    
    private init() {}
    
    // MARK: - Create Discount Code
    
    func createDiscountCode(
        code: String,
        type: DiscountType,
        value: Decimal,
        startDate: Date? = nil,
        endDate: Date? = nil,
        usageLimit: Int = 0,
        minimumPurchase: Decimal? = nil,
        maximumDiscount: Decimal? = nil,
        categories: [String] = [],
        description: String? = nil
    ) -> DiscountCode? {
        // Check if code already exists
        if findDiscountCode(byCode: code) != nil {
            return nil
        }
        
        let discountCode = DiscountCode(context: context)
        discountCode.id = UUID()
        discountCode.code = code.uppercased()
        discountCode.type = type.rawValue
        discountCode.value = value as NSDecimalNumber
        discountCode.startDate = startDate
        discountCode.endDate = endDate
        discountCode.usageLimit = Int32(usageLimit)
        discountCode.usageCount = 0
        discountCode.isActive = true
        discountCode.minimumPurchase = minimumPurchase as NSDecimalNumber?
        discountCode.maximumDiscount = maximumDiscount as NSDecimalNumber?
        discountCode.categories = categories
        discountCode.description_ = description
        discountCode.createdAt = Date()
        discountCode.updatedAt = Date()
        
        coreDataManager.save()
        return discountCode
    }
    
    // MARK: - Find Discount Code
    
    func findDiscountCode(byCode code: String) -> DiscountCode? {
        let request = DiscountCode.fetchRequest()
        request.predicate = NSPredicate(format: "code ==[c] %@", code)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
    
    func findDiscountCode(byId id: UUID) -> DiscountCode? {
        let request = DiscountCode.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
    
    // MARK: - Fetch Discount Codes
    
    func fetchAllDiscountCodes() -> [DiscountCode] {
        let request = DiscountCode.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }
    
    func fetchActiveDiscountCodes() -> [DiscountCode] {
        let request = DiscountCode.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == true")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }
    
    // MARK: - Validate Discount Code
    
    func validateCode(
        _ code: String,
        cartTotal: Decimal,
        categories: [String] = []
    ) -> DiscountValidationResult {
        guard let discountCode = findDiscountCode(byCode: code) else {
            return .invalid("Invalid discount code")
        }
        
        // Check if active
        guard discountCode.isActive else {
            return .invalid("This discount code is no longer active")
        }
        
        // Check date range
        let now = Date()
        if let startDate = discountCode.startDate, now < startDate {
            return .invalid("This discount code is not yet valid")
        }
        if let endDate = discountCode.endDate, now > endDate {
            return .invalid("This discount code has expired")
        }
        
        // Check usage limit
        if discountCode.usageLimit > 0 && discountCode.usageCount >= discountCode.usageLimit {
            return .invalid("This discount code has reached its usage limit")
        }
        
        // Check minimum purchase
        if discountCode.minimumPurchaseAmount > 0 && cartTotal < discountCode.minimumPurchaseAmount {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            let minString = formatter.string(from: discountCode.minimumPurchase ?? 0) ?? "$0.00"
            return .invalid("Minimum purchase of \(minString) required")
        }
        
        // Check categories if specified
        if !discountCode.categories.isEmpty && !categories.isEmpty {
            let hasMatchingCategory = discountCode.categories.contains { category in
                categories.contains(category)
            }
            if !hasMatchingCategory {
                return .invalid("This discount code is not applicable to items in your cart")
            }
        }
        
        // Calculate discount amount
        let discountAmount = calculateDiscount(
            code: discountCode,
            cartTotal: cartTotal
        )
        
        return .valid(discountAmount: discountAmount)
    }
    
    // MARK: - Calculate Discount
    
    func calculateDiscount(code: DiscountCode, cartTotal: Decimal) -> Decimal {
        var discountAmount: Decimal
        
        if code.discountType == .percentage {
            discountAmount = cartTotal * (code.discountValue / 100)
        } else {
            discountAmount = code.discountValue
        }
        
        // Apply maximum discount cap if set
        if let maxDiscount = code.maximumDiscountAmount {
            discountAmount = min(discountAmount, maxDiscount)
        }
        
        // Don't exceed cart total
        discountAmount = min(discountAmount, cartTotal)
        
        return discountAmount
    }
    
    // MARK: - Apply Discount
    
    func applyDiscount(code: String) -> Bool {
        guard let discountCode = findDiscountCode(byCode: code) else {
            return false
        }
        
        discountCode.usageCount += 1
        discountCode.updatedAt = Date()
        
        coreDataManager.save()
        return true
    }
    
    // MARK: - Update Discount Code
    
    func updateDiscountCode(
        _ discountCode: DiscountCode,
        code: String? = nil,
        type: DiscountType? = nil,
        value: Decimal? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        usageLimit: Int? = nil,
        minimumPurchase: Decimal? = nil,
        maximumDiscount: Decimal? = nil,
        categories: [String]? = nil,
        description: String? = nil,
        isActive: Bool? = nil
    ) {
        if let code = code {
            discountCode.code = code.uppercased()
        }
        if let type = type {
            discountCode.type = type.rawValue
        }
        if let value = value {
            discountCode.value = value as NSDecimalNumber
        }
        if let startDate = startDate {
            discountCode.startDate = startDate
        }
        if let endDate = endDate {
            discountCode.endDate = endDate
        }
        if let usageLimit = usageLimit {
            discountCode.usageLimit = Int32(usageLimit)
        }
        if let minimumPurchase = minimumPurchase {
            discountCode.minimumPurchase = minimumPurchase as NSDecimalNumber
        }
        if let maximumDiscount = maximumDiscount {
            discountCode.maximumDiscount = maximumDiscount as NSDecimalNumber
        }
        if let categories = categories {
            discountCode.categories = categories
        }
        if let description = description {
            discountCode.description_ = description
        }
        if let isActive = isActive {
            discountCode.isActive = isActive
        }
        
        discountCode.updatedAt = Date()
        coreDataManager.save()
    }
    
    // MARK: - Delete Discount Code
    
    func deleteDiscountCode(_ discountCode: DiscountCode) {
        context.delete(discountCode)
        coreDataManager.save()
    }
    
    // MARK: - Deactivate Discount Code
    
    func deactivateDiscountCode(_ discountCode: DiscountCode) {
        discountCode.isActive = false
        discountCode.updatedAt = Date()
        coreDataManager.save()
    }
    
    func activateDiscountCode(_ discountCode: DiscountCode) {
        discountCode.isActive = true
        discountCode.updatedAt = Date()
        coreDataManager.save()
    }
    
    // MARK: - Statistics
    
    func getDiscountCodeStatistics(_ discountCode: DiscountCode) -> DiscountCodeStatistics {
        let totalUses = Int(discountCode.usageCount)
        let remainingUses = discountCode.usageLimit > 0 ? Int(discountCode.usageLimit - discountCode.usageCount) : nil
        
        let now = Date()
        var daysRemaining: Int? = nil
        if let endDate = discountCode.endDate {
            let components = Calendar.current.dateComponents([.day], from: now, to: endDate)
            daysRemaining = components.day
        }
        
        return DiscountCodeStatistics(
            totalUses: totalUses,
            remainingUses: remainingUses,
            daysRemaining: daysRemaining,
            isValid: discountCode.isValid
        )
    }
}

// MARK: - Statistics Structure

struct DiscountCodeStatistics {
    let totalUses: Int
    let remainingUses: Int?
    let daysRemaining: Int?
    let isValid: Bool
}
