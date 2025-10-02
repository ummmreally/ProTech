import Foundation

struct LineItemData: Codable, Identifiable {
    let id: UUID
    let description: String
    let quantity: Decimal
    let unitPrice: Decimal
    let total: Decimal
    let itemType: String

    init(id: UUID = UUID(), description: String, quantity: Decimal, unitPrice: Decimal, total: Decimal, itemType: String) {
        self.id = id
        self.description = description
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.total = total
        self.itemType = itemType
    }
}
