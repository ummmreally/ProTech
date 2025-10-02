//
//  PointOfSaleView.swift
//  ProTech
//
//  Modern Point of Sale interface with split-panel design
//

import SwiftUI

struct PointOfSaleView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var cart = POSCart()
    @State private var searchText = ""
    @State private var selectedPaymentMode: PaymentMode?
    @State private var showingCheckout = false
    @State private var discountCode = ""
    @State private var discountAmount: Double = 0
    
    var body: some View {
        HStack(spacing: 0) {
            // Left Panel - Order Details
            orderDetailsPanel
                .frame(maxWidth: .infinity)
                .background(Color(hex: "F5F5F5"))
            
            // Right Panel - Payment Mode Selection
            paymentSelectionPanel
                .frame(width: 420)
                .background(Color.white)
        }
        .navigationTitle("Point of Sale")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    dismiss()
                }
            }
        }
    }
    
    // MARK: - Order Details Panel (Left)
    
    private var orderDetailsPanel: some View {
        VStack(spacing: 0) {
            // Search Bar
            searchBar
                .padding()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Customer Info (Optional)
                    customerInfoCard
                    
                    // Order Details Section
                    orderDetailsCard
                    
                    // Discount Section
                    discountCard
                }
                .padding()
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color(hex: "757575"))
            TextField("Search products...", text: $searchText)
                .textFieldStyle(.plain)
                .foregroundColor(Color(hex: "212121"))
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var customerInfoCard: some View {
        HStack(spacing: 15) {
            // Customer Avatar
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Walk-in Customer")
                    .font(.headline)
                    .foregroundColor(Color(hex: "212121"))
                HStack(spacing: 8) {
                    Image(systemName: "phone.fill")
                        .font(.caption)
                    Text("No phone number")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Regular/VIP Badge
            Text("Walk-in")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(Color(hex: "00C853"))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(hex: "B9F6CA"))
                .cornerRadius(20)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var orderDetailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Order details")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: "212121"))
            
            // Table Header
            HStack {
                Text("Dish name")
                    .font(.caption)
                    .foregroundColor(Color(hex: "757575"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Add ons")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 120)
                
                Text("Quantity")
                    .font(.caption)
                    .foregroundColor(Color(hex: "757575"))
                    .frame(width: 80)
                
                Text("Amount")
                    .font(.caption)
                    .foregroundColor(Color(hex: "757575"))
                    .frame(width: 80, alignment: .trailing)
            }
            .padding(.horizontal)
            
            Divider()
            
            // Cart Items
            if cart.items.isEmpty {
                emptyCartView
            } else {
                ForEach(cart.items) { item in
                    CartItemRow(item: item, cart: cart)
                }
            }
            
            Divider()
            
            // Totals Section
            VStack(spacing: 12) {
                HStack {
                    Text("Subtotal")
                        .foregroundColor(Color(hex: "757575"))
                    Spacer()
                    Text(formatCurrency(cart.subtotal))
                        .fontWeight(.medium)
                        .foregroundColor(Color(hex: "212121"))
                }
                
                HStack {
                    Text("Service charges")
                        .foregroundColor(Color(hex: "757575"))
                    Spacer()
                    Text("+ \(formatCurrency(cart.serviceCharge))")
                        .fontWeight(.medium)
                        .foregroundColor(Color(hex: "00C853"))
                }
                
                    Text("Tax (8.25%)")
                        .foregroundColor(Color(hex: "757575"))
                    Spacer()
                    Text("+ \(formatCurrency(cart.taxAmount))")
                        .fontWeight(.medium)
                Divider()
                
                HStack {
                    Text("Total")
                        .font(.headline)
                        .foregroundColor(Color(hex: "212121"))
                    Spacer()
                    Text(formatCurrency(cart.total - discountAmount))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "212121"))
                }
            }
            .padding()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var emptyCartView: some View {
        VStack(spacing: 16) {
            Image(systemName: "cart")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "757575").opacity(0.5))
            
            Text("Cart is empty")
                .font(.headline)
                .foregroundColor(Color(hex: "757575"))
            
            Text("Add products to get started")
                .font(.caption)
                .foregroundColor(Color(hex: "757575"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private var discountCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "tag.fill")
                    .foregroundColor(Color(hex: "00C853"))
                Text("Discount coupon")
                    .font(.headline)
                    .foregroundColor(Color(hex: "212121"))
            }
            
            Text("Here apply the offered discount coupons or customers provided coupons for special discount on current cart value")
                .font(.caption)
                .foregroundColor(Color(hex: "757575"))
            
            HStack(spacing: 12) {
                TextField("Enter coupon code here or SELECT HERE", text: $discountCode)
                    .textFieldStyle(.plain)
                    .foregroundColor(Color(hex: "212121"))
                    .padding(12)
                    .background(Color(hex: "F5F5F5"))
                    .cornerRadius(8)
                
                Button {
                    applyDiscount()
                } label: {
                    Text("Apply")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color(hex: "00C853"))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Payment Selection Panel (Right)
    
    private var paymentSelectionPanel: some View {
        VStack(spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Select payment mode")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "212121"))
                
                Text("Select a payment method that helps our customers to feel seamless experience during checkout")
                    .font(.caption)
                    .foregroundColor(Color(hex: "757575"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 24)
            
            ScrollView {
                VStack(spacing: 16) {
                    // Payment Mode Cards
                    PaymentModeCard(
                        icon: "creditcard.fill",
                        title: "Pay using card",
                        description: "Complete the payment using credit or debit card, using swipe machine",
                        isSelected: selectedPaymentMode == .card,
                        accentColor: Color(hex: "00C853")
                    ) {
                        selectedPaymentMode = .card
                    }
                    
                    PaymentModeCard(
                        icon: "dollarsign.circle.fill",
                        title: "Pay on cash",
                        description: "Complete order payment taking cash on hand from customers easy skin simple",
                        isSelected: selectedPaymentMode == .cash,
                        accentColor: Color(hex: "00C853")
                    ) {
                        selectedPaymentMode = .cash
                    }
                    
                    PaymentModeCard(
                        icon: "qrcode",
                        title: "Pay using UPI or scan",
                        description: "Ask customer to complete the payment using by scanning our code or qr it",
                        isSelected: selectedPaymentMode == .upi,
                        accentColor: Color(hex: "00C853")
                    ) {
                        selectedPaymentMode = .upi
                    }
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
            
            // Confirm Payment Button
            Button {
                processPayment()
            } label: {
                Text("Confirm payment")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        selectedPaymentMode != nil ?
                        Color(hex: "00C853") :
                        Color.gray.opacity(0.3)
                    )
                    .cornerRadius(16)
            }
            .buttonStyle(.plain)
            .disabled(selectedPaymentMode == nil || cart.items.isEmpty)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatCurrency(_ amount: Double) -> String {
        return String(format: "$%.2f", amount)
    }
    
    private func applyDiscount() {
        // Mock discount logic
        if !discountCode.isEmpty {
            discountAmount = cart.subtotal * 0.10 // 10% discount
        }
    }
    
    private func processPayment() {
        guard selectedPaymentMode != nil else { return }
        
        // TODO: Process payment through Square
        // For now, just show success
        showingCheckout = true
    }
}

// MARK: - Cart Item Row

struct CartItemRow: View {
    let item: CartItem
    @ObservedObject var cart: POSCart
    
    var body: some View {
        HStack(spacing: 12) {
            // Product Image/Icon
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: item.icon)
                        .font(.title3)
                        .foregroundColor(.orange)
                )
            
            // Product Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(Color(hex: "212121"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Add-ons Badge
            if !item.addOns.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                        .foregroundColor(Color(hex: "00C853"))
                    Text("\(item.addOns.count) Add-ons")
                        .font(.caption)
                        .foregroundColor(Color(hex: "00C853"))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: "B9F6CA"))
                .cornerRadius(12)
            } else {
                Text("Add ons")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 120)
            }
            
            // Quantity Stepper
            HStack(spacing: 4) {
                Button {
                    cart.decrementQuantity(for: item)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                
                Text("×\(item.quantity)")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(Color(hex: "212121"))
                    .frame(width: 40)
                
                Button {
                    cart.incrementQuantity(for: item)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Color(hex: "00C853"))
                }
                .buttonStyle(.plain)
            }
            .frame(width: 80)
            
            // Price
            Text(formatCurrency(item.totalPrice))
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: "212121"))
                .frame(width: 80, alignment: .trailing)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(hex: "F9F9F9"))
        .cornerRadius(12)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        return String(format: "$%.2f", amount)
    }
}

// MARK: - Payment Mode Card

struct PaymentModeCard: View {
    let icon: String
    let title: String
    let description: String
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                Circle()
                    .fill(isSelected ? accentColor.opacity(0.1) : Color.gray.opacity(0.1))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundColor(isSelected ? accentColor : .secondary)
                    )
                
                // Text Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "212121"))
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(Color(hex: "757575"))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? accentColor : Color.clear, lineWidth: 2)
                    )
            )
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Supporting Models

enum PaymentMode {
    case card
    case cash
    case upi
}

class POSCart: ObservableObject {
    @Published var items: [CartItem] = []
    
    var subtotal: Double {
        items.reduce(0) { $0 + $1.totalPrice }
    }
    
    var serviceCharge: Double {
        subtotal * 0.05 // 5% service charge
    }
    
    var taxAmount: Double {
        subtotal * 0.0825 // 8.25% tax
    }
    
    var total: Double {
        subtotal + serviceCharge + taxAmount
    }
    
    func addItem(_ item: CartItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].quantity += 1
        } else {
            items.append(item)
        }
    }
    
    func removeItem(_ item: CartItem) {
        items.removeAll { $0.id == item.id }
    }
    
    func incrementQuantity(for item: CartItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].quantity += 1
        }
    }
    
    func decrementQuantity(for item: CartItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            if items[index].quantity > 1 {
                items[index].quantity -= 1
            } else {
                items.remove(at: index)
            }
        }
    }
    
    func clear() {
        items.removeAll()
    }
    
    // Add some mock items for demo
    func addMockItems() {
        items = [
            CartItem(name: "iPhone Case", price: 9.99, quantity: 2, icon: "iphone", addOns: []),
            CartItem(name: "Screen Protector", price: 12.99, quantity: 1, icon: "shield.fill", addOns: []),
            CartItem(name: "Charging Cable", price: 14.99, quantity: 1, icon: "cable.connector", addOns: ["Fast Charging"])
        ]
    }
}

struct CartItem: Identifiable {
    let id = UUID()
    let name: String
    let price: Double
    var quantity: Int
    let icon: String
    let addOns: [String]
    
    var totalPrice: Double {
        price * Double(quantity)
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview

struct PointOfSaleView_Previews: PreviewProvider {
    static var previews: some View {
        PointOfSaleView()
            .frame(width: 1200, height: 800)
            .onAppear {
                // Add mock items for preview
                let cart = POSCart()
                cart.addMockItems()
            }
    }
}
