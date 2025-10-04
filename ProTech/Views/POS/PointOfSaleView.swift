//
//  PointOfSaleView.swift
//  ProTech
//
//  Modern Point of Sale interface with split-panel design
//

import SwiftUI

struct PointOfSaleView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var cart = POSCart()
    @State private var searchText = ""
    @State private var selectedPaymentMode: PaymentMode?
    @State private var showingCheckout = false
    @State private var discountCode = ""
    @State private var discountAmount: Double = 0
    @State private var selectedCategory: InventoryCategory = .all
    @State private var squareDevices: [TerminalDevice] = []
    @State private var selectedDeviceId: String? = nil
    @State private var terminalCheckoutId: String? = nil
    @State private var isProcessingSquare = false
    @State private var squarePaymentStatus: String = ""
    @State private var showSquareError = false
    @State private var squareErrorMessage = ""
    
    // Customer selection and history
    @State private var selectedCustomer: Customer?
    @State private var showCustomerPicker = false
    @State private var customerPurchases: [PurchaseHistory] = []
    @State private var customerRepairs: [Ticket] = []
    private let historyService: CustomerHistoryService
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \InventoryItem.name, ascending: true)],
        predicate: NSPredicate(format: "isActive == true AND quantity > 0")
    ) var availableItems: FetchedResults<InventoryItem>
    
    init() {
        self.historyService = CustomerHistoryService()
    }
    
    var filteredItems: [InventoryItem] {
        var filtered = Array(availableItems)
        
        if !searchText.isEmpty {
            filtered = filtered.filter {
                ($0.name?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                ($0.sku?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                ($0.partNumber?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        if selectedCategory != .all {
            filtered = filtered.filter { $0.inventoryCategory == selectedCategory }
        }
        
        return filtered
    }
    
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
        .sheet(isPresented: $isProcessingSquare) {
            squarePaymentProcessingView
        }
        .sheet(isPresented: $showCustomerPicker) {
            CustomerPickerView(selectedCustomer: $selectedCustomer)
        }
        .alert("Square Payment Error", isPresented: $showSquareError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(squareErrorMessage)
        }
        .onChange(of: selectedCustomer) { _, newCustomer in
            loadCustomerHistory()
        }
        .task {
            await loadSquareDevices()
        }
    }
    
    // MARK: - Order Details Panel (Left)
    
    private var orderDetailsPanel: some View {
        VStack(spacing: 0) {
            // Search Bar
            searchBar
                .padding()
            
            // Category Filter
            categoryFilter
                .padding(.horizontal)
            
            // Product Grid
            productGrid
                .frame(height: 300)
                .padding()
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Customer Selection
                    customerSelectionCard
                    
                    // Customer History
                    if selectedCustomer != nil {
                        CustomerPurchaseHistoryCard(purchases: customerPurchases)
                        CustomerRepairHistoryCard(repairs: customerRepairs)
                    } else {
                        emptyCustomerHistoryView
                    }
                }
                .padding()
            }
        }
    }
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(InventoryCategory.allCases, id: \.self) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        HStack {
                            Image(systemName: category.icon)
                            Text(category.displayName)
                        }
                        .font(.subheadline)
                        .fontWeight(selectedCategory == category ? .semibold : .regular)
                        .foregroundColor(selectedCategory == category ? .white : Color(hex: "212121"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedCategory == category ? Color(hex: "00C853") : Color.white)
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var productGrid: some View {
        ScrollView {
            if filteredItems.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text(searchText.isEmpty ? "No products available" : "No products found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    if !searchText.isEmpty {
                        Button("Clear Search") {
                            searchText = ""
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(filteredItems, id: \.id) { item in
                        ProductCard(item: item) {
                            addToCart(item)
                        }
                    }
                }
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
    
    private var customerSelectionCard: some View {
        HStack(spacing: 15) {
            // Customer Avatar
            Circle()
                .fill(selectedCustomer == nil ? Color.gray.opacity(0.1) : Color.blue.opacity(0.1))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(selectedCustomer == nil ? .gray : .blue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(customerName)
                    .font(.headline)
                    .foregroundColor(Color(hex: "212121"))
                HStack(spacing: 8) {
                    Image(systemName: "phone.fill")
                        .font(.caption)
                    Text(customerPhone)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Select/Change Button
            Button {
                showCustomerPicker = true
            } label: {
                Text(selectedCustomer == nil ? "Select" : "Change")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "00C853"))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var customerName: String {
        if let customer = selectedCustomer {
            let firstName = customer.firstName ?? ""
            let lastName = customer.lastName ?? ""
            if !firstName.isEmpty || !lastName.isEmpty {
                return "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
            }
        }
        return "Walk-in Customer"
    }
    
    private var customerPhone: String {
        selectedCustomer?.phone ?? "No phone number"
    }
    
    private var emptyCustomerHistoryView: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "757575").opacity(0.3))
            Text("Select a customer")
                .font(.headline)
                .foregroundColor(Color(hex: "757575"))
            Text("View purchase and repair history")
                .font(.caption)
                .foregroundColor(Color(hex: "757575"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
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
                
                HStack {
                    Text("Tax (8.25%)")
                        .foregroundColor(Color(hex: "757575"))
                    Spacer()
                    Text("+ \(formatCurrency(cart.taxAmount))")
                        .fontWeight(.medium)
                }
                
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
        VStack(spacing: 16) {
            // Customer Header
            CustomerHeaderCard(customer: selectedCustomer)
                .padding(.horizontal, 24)
                .padding(.top, 16)
            
            // Order Details (moved from left panel)
            orderDetailsCard
                .padding(.horizontal, 24)
            
            // Discount Section
            discountCard
                .padding(.horizontal, 24)
            
            Divider()
                .padding(.horizontal, 24)
            
            // Payment Mode Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Select payment mode")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "212121"))
                
                // Square Terminal Device Selector
                if selectedPaymentMode == .card && !squareDevices.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Square Terminal Device")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "212121"))
                        
                        Picker("Select Device", selection: $selectedDeviceId) {
                            Text("Select Terminal...").tag(nil as String?)
                            ForEach(squareDevices) { device in
                                Text(device.name ?? "Terminal \(device.code)").tag(device.deviceId as String?)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            
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
                        canConfirmPayment ?
                        Color(hex: "00C853") :
                        Color.gray.opacity(0.3)
                    )
                    .cornerRadius(16)
            }
            .buttonStyle(.plain)
            .disabled(!canConfirmPayment)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
    
    // MARK: - Computed Properties
    
    private var canConfirmPayment: Bool {
        guard selectedPaymentMode != nil, !cart.items.isEmpty else {
            return false
        }
        
        // If card payment is selected, must have a device selected
        if selectedPaymentMode == .card {
            return selectedDeviceId != nil
        }
        
        return true
    }
    
    private var squarePaymentProcessingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text(squarePaymentStatus)
                .font(.title3)
                .fontWeight(.medium)
            
            if let checkoutId = terminalCheckoutId {
                Text("Checkout ID: \(checkoutId)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("Please complete payment on Square Terminal")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button("Cancel") {
                cancelSquarePayment()
            }
            .buttonStyle(.bordered)
        }
        .padding(40)
        .frame(width: 400, height: 300)
    }
    
    // MARK: - Helper Methods
    
    private func loadSquareDevices() async {
        do {
            let devices = try await SquareAPIService.shared.listTerminalDevices()
            await MainActor.run {
                self.squareDevices = devices
                // Auto-select first device if available
                if let firstDevice = devices.first {
                    self.selectedDeviceId = firstDevice.deviceId
                }
            }
        } catch {
            print("Failed to load Square devices: \(error.localizedDescription)")
        }
    }
    
    private func addToCart(_ item: InventoryItem) {
        let cartItem = CartItem(
            name: item.name ?? "Unknown",
            price: item.sellingPrice,
            quantity: 1,
            icon: item.inventoryCategory.icon,
            addOns: []
        )
        cart.addItem(cartItem)
    }
    
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
        guard let paymentMode = selectedPaymentMode else { return }
        
        switch paymentMode {
        case .card:
            // Process through Square Terminal
            processSquareTerminalPayment()
        case .cash, .upi:
            // Process locally
            processLocalPayment()
        }
    }
    
    private func processSquareTerminalPayment() {
        guard let deviceId = selectedDeviceId else {
            squareErrorMessage = "Please select a Square Terminal device"
            showSquareError = true
            return
        }
        
        Task {
            do {
                // Convert cart total to cents
                let amountInCents = Int((cart.total - discountAmount) * 100)
                
                isProcessingSquare = true
                squarePaymentStatus = "Creating checkout..."
                
                // Create terminal checkout
                let checkout = try await SquareAPIService.shared.createTerminalCheckout(
                    amount: amountInCents,
                    deviceId: deviceId,
                    referenceId: "POS-\(UUID().uuidString.prefix(8))",
                    note: "ProTech POS Sale"
                )
                
                terminalCheckoutId = checkout.id
                squarePaymentStatus = "Waiting for payment on terminal..."
                
                // Poll for checkout completion
                let completed = try await pollCheckoutStatus(checkoutId: checkout.id)
                
                if completed {
                    // Save purchase history
                    _ = try? historyService.savePurchase(
                        customer: selectedCustomer,
                        cart: cart,
                        paymentMethod: "card",
                        squareCheckoutId: checkout.id,
                        discount: discountAmount
                    )
                    
                    // Payment successful!
                    await MainActor.run {
                        isProcessingSquare = false
                        cart.clear()
                        selectedPaymentMode = nil
                        discountAmount = 0
                        discountCode = ""
                        terminalCheckoutId = nil
                        
                        // Reload customer history if customer selected
                        loadCustomerHistory()
                    }
                } else {
                    throw SquareAPIError.apiError(message: "Payment was not completed")
                }
            } catch {
                await MainActor.run {
                    isProcessingSquare = false
                    squareErrorMessage = "Payment failed: \(error.localizedDescription)"
                    showSquareError = true
                    terminalCheckoutId = nil
                }
            }
        }
    }
    
    private func pollCheckoutStatus(checkoutId: String) async throws -> Bool {
        // Poll every 2 seconds for up to 5 minutes
        for _ in 0..<150 {
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            let checkout = try await SquareAPIService.shared.getTerminalCheckout(checkoutId: checkoutId)
            
            await MainActor.run {
                squarePaymentStatus = "Status: \(checkout.status)"
            }
            
            if checkout.isCompleted {
                return true
            } else if checkout.isCanceled {
                return false
            }
            // Continue polling if pending
        }
        
        return false // Timeout
    }
    
    private func cancelSquarePayment() {
        guard let checkoutId = terminalCheckoutId else {
            isProcessingSquare = false
            return
        }
        
        Task {
            do {
                _ = try await SquareAPIService.shared.cancelTerminalCheckout(checkoutId: checkoutId)
                await MainActor.run {
                    isProcessingSquare = false
                    terminalCheckoutId = nil
                }
            } catch {
                await MainActor.run {
                    isProcessingSquare = false
                    terminalCheckoutId = nil
                    squareErrorMessage = "Failed to cancel: \(error.localizedDescription)"
                    showSquareError = true
                }
            }
        }
    }
    
    private func processLocalPayment() {
        // For cash and UPI payments - process locally
        let paymentMethod = selectedPaymentMode == .cash ? "cash" : "upi"
        
        // Save purchase history
        _ = try? historyService.savePurchase(
            customer: selectedCustomer,
            cart: cart,
            paymentMethod: paymentMethod,
            discount: discountAmount
        )
        
        showingCheckout = true
        
        // Clear cart after successful payment
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            cart.clear()
            selectedPaymentMode = nil
            discountAmount = 0
            discountCode = ""
            showingCheckout = false
            
            // Reload customer history
            loadCustomerHistory()
        }
    }
    
    // MARK: - Customer History
    
    private func loadCustomerHistory() {
        guard let customer = selectedCustomer else {
            customerPurchases = []
            customerRepairs = []
            return
        }
        
        customerPurchases = historyService.fetchPurchaseHistory(for: customer, limit: 10)
        customerRepairs = historyService.fetchRepairHistory(for: customer, limit: 10)
    }
}

// MARK: - Product Card

struct ProductCard: View {
    let item: InventoryItem
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(categoryColor.opacity(0.1))
                        .frame(height: 80)
                    
                    Image(systemName: item.inventoryCategory.icon)
                        .font(.system(size: 32))
                        .foregroundColor(categoryColor)
                }
                
                // Name
                Text(item.name ?? "Unknown")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(hex: "212121"))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(height: 36)
                
                // Price
                Text(String(format: "$%.2f", item.sellingPrice))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "00C853"))
                
                // Stock
                HStack(spacing: 4) {
                    Image(systemName: "cube.box")
                        .font(.caption2)
                    Text("\(item.quantity) in stock")
                        .font(.caption2)
                }
                .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
    
    private var categoryColor: Color {
        switch item.inventoryCategory {
        case .screens: return .blue
        case .batteries: return .green
        case .cables: return .orange
        case .chargers: return .purple
        case .tools: return .red
        default: return .gray
        }
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
