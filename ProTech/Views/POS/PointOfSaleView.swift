//
//  PointOfSaleView.swift
//  ProTech
//
//  Modern Point of Sale interface with split-panel design
//

import SwiftUI
import Supabase

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
    @State private var showingPairingCode = false
    @State private var pairingCode = ""
    
    // Layout State
    @State private var selectedLeftTab: LeftPanelTab = .products
    
    // Loyalty rewards
    @State private var availableRewards: [LoyaltyReward] = []
    @State private var appliedReward: LoyaltyReward?
    @State private var rewardDiscount: Double = 0
    @State private var showingRewardPicker = false
    @State private var pointsEarned: Int32 = 0
    
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

// MARK: - Square Sales Edge Function Types

private struct SquareSalesCreateTerminalCheckoutRequest: Encodable {
    let action = "create_terminal_checkout"
    let deviceId: String
    let amountCents: Int
    let referenceId: String?
    let note: String?
    let squareCustomerId: String?

    enum CodingKeys: String, CodingKey {
        case action
        case deviceId = "device_id"
        case amountCents = "amount_cents"
        case referenceId = "reference_id"
        case note
        case squareCustomerId = "square_customer_id"
    }
}

private struct SquareSalesCreateTerminalCheckoutResponse: Decodable {
    let ok: Bool
    let orderId: String
    let checkoutId: String
    let checkoutStatus: String
    let paymentIds: [String]

    enum CodingKeys: String, CodingKey {
        case ok
        case orderId = "order_id"
        case checkoutId = "checkout_id"
        case checkoutStatus = "checkout_status"
        case paymentIds = "payment_ids"
    }
}

private struct SquareSalesGetTerminalCheckoutRequest: Encodable {
    let action = "get_terminal_checkout"
    let checkoutId: String

    enum CodingKeys: String, CodingKey {
        case action
        case checkoutId = "checkout_id"
    }
}

private struct SquareSalesGetTerminalCheckoutResponse: Decodable {
    let ok: Bool
    let checkoutId: String
    let checkoutStatus: String
    let paymentIds: [String]

    enum CodingKeys: String, CodingKey {
        case ok
        case checkoutId = "checkout_id"
        case checkoutStatus = "checkout_status"
        case paymentIds = "payment_ids"
    }
}

private struct SquareSalesCancelTerminalCheckoutRequest: Encodable {
    let action = "cancel_terminal_checkout"
    let checkoutId: String

    enum CodingKeys: String, CodingKey {
        case action
        case checkoutId = "checkout_id"
    }
}

private struct SquareSalesCancelTerminalCheckoutResponse: Decodable {
    let ok: Bool
    let checkoutId: String
    let checkoutStatus: String
    let paymentIds: [String]

    enum CodingKeys: String, CodingKey {
        case ok
        case checkoutId = "checkout_id"
        case checkoutStatus = "checkout_status"
        case paymentIds = "payment_ids"
    }
}

private struct SquareSalesCreateCashPaymentRequest: Encodable {
    let action = "create_cash_payment"
    let amountCents: Int
    let referenceId: String?
    let note: String?
    let squareCustomerId: String?

    enum CodingKeys: String, CodingKey {
        case action
        case amountCents = "amount_cents"
        case referenceId = "reference_id"
        case note
        case squareCustomerId = "square_customer_id"
    }
}

private struct SquareSalesCreateCashPaymentResponse: Decodable {
    let ok: Bool
    let orderId: String
    let paymentId: String

    enum CodingKeys: String, CodingKey {
        case ok
        case orderId = "order_id"
        case paymentId = "payment_id"
    }
}
    
    enum LeftPanelTab: String, CaseIterable {
        case products = "Products"
        case history = "Customer History"
        case transactions = "Transactions"
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
            // Left Panel - Order Details & Catalog
            leftPanel
                .frame(maxWidth: .infinity)
                .background(AppTheme.Colors.groupedBackground)
            
            // Right Panel - Cart & Payment
            rightPanel
                .frame(width: 420)
                .background(AppTheme.Colors.cardBackground)
                .shadow(color: .black.opacity(0.1), radius: AppTheme.shadowRadius, x: -2, y: 0)
        }
        .navigationTitle("Point of Sale")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
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
        .alert("Pair Square Terminal", isPresented: $showingPairingCode) {
            Button("OK", role: .cancel) {
                Task {
                    await loadSquareDevices()
                }
            }
        } message: {
            Text("Enter this code on your Square Terminal to pair:\n\n\(pairingCode)\n\nAfter pairing, tap OK to refresh devices.")
        }
        .onChange(of: selectedCustomer) { _, newCustomer in
            if newCustomer != nil {
                loadCustomerHistory()
                loadAvailableRewards()
            }
            appliedReward = nil
            rewardDiscount = 0
        }
        .sheet(isPresented: $showingRewardPicker) {
            if let customer = selectedCustomer {
                RewardPickerView(
                    customer: customer,
                    availableRewards: availableRewards,
                    onSelect: { reward in
                        applyReward(reward)
                    }
                )
            }
        }
        .task {
            await loadSquareDevices()
        }
        .overlay {
            if showingCheckout {
                CheckoutSuccessOverlay(
                    totalAmount: cart.total - discountAmount - rewardDiscount,
                    pointsEarned: pointsEarned,
                    customer: selectedCustomer
                )
            }
        }
    }
    
    // MARK: - Left Panel
    
    private var leftPanel: some View {
        VStack(spacing: 0) {
            // Top Bar with Search and Segmented Control
            VStack(spacing: 12) {
                searchBar
                
                Picker("View", selection: $selectedLeftTab) {
                    ForEach(LeftPanelTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                if selectedLeftTab == .products {
                    categoryFilter
                        .padding(.bottom, 8)
                }
            }
            .padding(.top)
            .background(AppTheme.Colors.cardBackground)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 5)
            .zIndex(1)
            
            // Content
            if selectedLeftTab == .products {
                productGrid
            } else if selectedLeftTab == .history {
                customerHistoryView
            } else {
                POSTransactionHistoryView()
            }
        }
    }
    
    private var customerHistoryView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                customerSelectionCard
                
                if let customer = selectedCustomer {
                    LoyaltyWidget(customer: customer)
                    CustomerPurchaseHistoryCard(purchases: customerPurchases)
                    CustomerRepairHistoryCard(repairs: customerRepairs)
                } else {
                    emptyCustomerHistoryView
                }
            }
            .padding()
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
                        .font(AppTheme.Typography.subheadline)
                        .fontWeight(selectedCategory == category ? .semibold : .regular)
                        .foregroundColor(selectedCategory == category ? .white : .primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedCategory == category ? AppTheme.Colors.success : AppTheme.Colors.cardBackground)
                        .cornerRadius(AppTheme.buttonCornerRadius)
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
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
                .padding(.top, 60)
            } else {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 150), spacing: 16)
                ], spacing: 16) {
                    ForEach(filteredItems, id: \.id) { item in
                        ProductCard(item: item) {
                            addToCart(item)
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search products...", text: $searchText)
                .textFieldStyle(.plain)
                .font(AppTheme.Typography.body)
        }
        .padding(12)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.cornerRadius)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    private var customerSelectionCard: some View {
        HStack(spacing: 15) {
            // Customer Avatar
            Circle()
                .fill(selectedCustomer == nil ? Color.gray.opacity(0.1) : Color.blue.opacity(0.1))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.title2)
                        .foregroundColor(selectedCustomer == nil ? .gray : .blue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(customerName)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                HStack(spacing: 8) {
                    Image(systemName: "phone.fill")
                        .font(.caption)
                    Text(customerPhone)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(AppTheme.Colors.cardBackground)
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
                .foregroundColor(.secondary.opacity(0.3))
            Text("Select a customer")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("View purchase and repair history")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Right Panel (Cart & Checkout)
    
    private var rightPanel: some View {
        VStack(spacing: 0) {
            // Customer Header (Clickable to select/change)
            Button {
                showCustomerPicker = true
            } label: {
                CustomerHeaderCard(customer: selectedCustomer)
            }
            .buttonStyle(.plain)
            .padding()
            
            Divider()
            
            // Scrollable Cart & Payment Options
            ScrollView {
                VStack(spacing: 20) {
                    // Cart Items
                    if cart.items.isEmpty {
                        emptyCartView
                    } else {
                        VStack(spacing: 12) {
                            ForEach(cart.items) { item in
                                CartItemRow(item: item, cart: cart)
                            }
                        }
                    }
                    
                    // Discount
                    discountCard
                    
                    // Loyalty
                    if selectedCustomer != nil && !availableRewards.isEmpty {
                        loyaltyRewardsCard
                    }
                    
                    Divider()
                    
                    // Payment Mode Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Payment Mode")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        // Cash Drawer Access
                        Button {
                            CashDrawerService.shared.openDrawer(startingBalance: 0, employeeId: UUID()) // Using UUID() for now as auth provider is not active in this context
                        } label: {
                            Label("Open Drawer", systemImage: "archivebox")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                        
                        // Square Terminal Device Selector
                        if selectedPaymentMode == .card && !squareDevices.isEmpty {
                            Picker("Square Terminal", selection: $selectedDeviceId) {
                                Text("Select Terminal...").tag(nil as String?)
                                ForEach(squareDevices) { device in
                                    Text(device.name ?? device.id).tag(device.id as String?)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(.bottom, 8)
                        }

                        if selectedPaymentMode == .card && squareDevices.isEmpty {
                            Button {
                                Task {
                                    do {
                                        let code = try await SquareAPIService.shared.createDeviceCode(name: "ProTech POS")
                                        await MainActor.run {
                                            pairingCode = code.code ?? ""
                                            showingPairingCode = true
                                        }
                                    } catch {
                                        await MainActor.run {
                                            squareErrorMessage = "Failed to generate pairing code: \(error.localizedDescription)"
                                            showSquareError = true
                                        }
                                    }
                                }
                            } label: {
                                Text("Generate Pairing Code")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(AppTheme.Colors.groupedBackground)
                                    .foregroundColor(.primary)
                                    .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        VStack(spacing: 10) {
                            PaymentModeCard(
                                icon: "creditcard.fill",
                                title: "Card",
                                description: "Square Terminal",
                                isSelected: selectedPaymentMode == .card,
                                accentColor: AppTheme.Colors.success
                            ) { selectedPaymentMode = .card }
                            
                            PaymentModeCard(
                                icon: "dollarsign.circle.fill",
                                title: "Cash",
                                description: "Cash payment",
                                isSelected: selectedPaymentMode == .cash,
                                accentColor: AppTheme.Colors.success
                            ) { selectedPaymentMode = .cash }
                            
                            PaymentModeCard(
                                icon: "qrcode",
                                title: "Other",
                                description: "External/UPI",
                                isSelected: selectedPaymentMode == .upi,
                                accentColor: AppTheme.Colors.success
                            ) { selectedPaymentMode = .upi }
                            
                            PaymentModeCard(
                                icon: "arrow.triangle.branch",
                                title: "Split",
                                description: "Card + Cash",
                                isSelected: selectedPaymentMode == .split,
                                accentColor: AppTheme.Colors.primary
                            ) { selectedPaymentMode = .split }
                        }
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Totals & Action Button (Fixed Bottom)
            VStack(spacing: 16) {
                // Totals
                VStack(spacing: 8) {
                    HStack {
                        Text("Subtotal")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatCurrency(cart.subtotal))
                    }
                    
                    if cart.serviceCharge > 0 {
                        HStack {
                            Text("Service Fee")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formatCurrency(cart.serviceCharge))
                        }
                    }
                    
                    HStack {
                        Text("Tax")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatCurrency(cart.taxAmount))
                    }
                    
                    if discountAmount > 0 {
                        HStack {
                            Text("Discount")
                                .foregroundColor(.green)
                            Spacer()
                            Text("-\(formatCurrency(discountAmount))")
                                .foregroundColor(.green)
                        }
                    }
                    
                    if rewardDiscount > 0 {
                        HStack {
                            Text("Reward")
                                .foregroundColor(.green)
                            Spacer()
                            Text("-\(formatCurrency(rewardDiscount))")
                                .foregroundColor(.green)
                        }
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Total")
                            .font(.title3)
                            .fontWeight(.bold)
                        Spacer()
                        Text(formatCurrency(max(0, cart.total - discountAmount - rewardDiscount)))
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                }
                
                Button {
                    processPayment()
                } label: {
                    HStack {
                        if isProcessingSquare {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.trailing, 8)
                        }
                        Text(isProcessingSquare ? "Processing..." : "Charge \(formatCurrency(max(0, cart.total - discountAmount - rewardDiscount)))")
                            .font(AppTheme.Typography.headline)
                    }
                }
                .buttonStyle(PremiumButtonStyle(variant: canConfirmPayment ? .success : .secondary))
                .disabled(!canConfirmPayment || isProcessingSquare)
            }
            .padding()
            .background(AppTheme.Colors.groupedBackground)
        }
    }
    
    private var emptyCartView: some View {
        VStack(spacing: 12) {
            Image(systemName: "cart")
                .font(.largeTitle)
                .foregroundColor(.secondary.opacity(0.5))
            Text("Cart is empty")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    private var discountCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Discount Code")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            HStack {
                TextField("Code", text: $discountCode)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(AppTheme.Colors.groupedBackground)
                    .cornerRadius(8)
                
                if discountAmount > 0 {
                    Button {
                        discountAmount = 0
                        discountCode = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button("Apply") {
                        applyDiscount()
                    }
                    .disabled(discountCode.isEmpty)
                }
            }
        }
    }
    
    private var loyaltyRewardsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Available Rewards")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Button {
                showingRewardPicker = true
            } label: {
                HStack {
                    Image(systemName: "gift.fill")
                        .foregroundColor(.purple)
                    
                    if let reward = appliedReward {
                        Text(reward.name ?? "Reward Applied")
                            .foregroundColor(.primary)
                        Spacer()
                        Text("-\(formatCurrency(rewardDiscount))")
                            .foregroundColor(.green)
                    } else {
                        Text("\(availableRewards.count) rewards available")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(10)
                .background(AppTheme.Colors.groupedBackground)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Logic
    
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
    
    private func loadCustomerHistory() {
        guard let customer = selectedCustomer else {
            customerPurchases = []
            customerRepairs = []
            return
        }
        
        // Load purchase history
        customerPurchases = historyService.fetchPurchaseHistory(for: customer)
        
        // Load repair history
        customerRepairs = historyService.fetchRepairHistory(for: customer)
    }
    
    private func loadAvailableRewards() {
        guard let customer = selectedCustomer,
              let customerId = customer.id,
              let member = LoyaltyService.shared.getMember(for: customerId) else {
            availableRewards = []
            return
        }
        
        availableRewards = LoyaltyService.shared.getAvailableRewards(for: member)
    }
    
    private func applyReward(_ reward: LoyaltyReward) {
        appliedReward = reward
        
        // Calculate discount amount based on reward type
        // Assuming reward has some value or discount percentage
        // For now, let's assume a flat $10 or 10% if not specified
        // In a real app, reward entity would have type/value fields
        
        // Mock logic:
        rewardDiscount = 10.00 // Flat $10 discount for demo
        
        // Logic for percentage vs flat would go here
    }
    
    private func loadSquareDevices() async {
        do {
            let devices = try await SquareAPIService.shared.listTerminalDevices()
            await MainActor.run {
                self.squareDevices = devices
                // Auto-select first device if available
                if let firstDevice = devices.first {
                    self.selectedDeviceId = firstDevice.id
                }
            }
        } catch {
            await MainActor.run {
                squareErrorMessage = "Failed to load Square Terminal devices: \(error.localizedDescription)"
                showSquareError = true
                squareDevices = []
                selectedDeviceId = nil
            }
        }
    }
    
    private func addToCart(_ item: InventoryItem) {
        let cartItem = CartItem(
            name: item.name ?? "Unknown",
            price: item.priceDouble,
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
        case .cash:
            processSquareCashPayment()
        case .upi:
            // Process locally
            processLocalPayment()
        case .split:
            // TODO: Implement split payment logic
            // For now, treat as local/other
            processLocalPayment()
        }
    }

    private func processSquareCashPayment() {
        Task {
            do {
                let finalAmount = cart.total - discountAmount - rewardDiscount
                let amountInCents = Int(finalAmount * 100)

                await MainActor.run {
                    isProcessingSquare = true
                    squarePaymentStatus = "Recording cash payment in Square..."
                }

                let referenceId = "POS-\(UUID().uuidString.prefix(8))"
                let response: SquareSalesCreateCashPaymentResponse = try await SupabaseService.shared.client.functions.invoke(
                    "square-sales",
                    options: FunctionInvokeOptions(
                        body: SquareSalesCreateCashPaymentRequest(
                            amountCents: amountInCents,
                            referenceId: referenceId,
                            note: "ProTech POS Sale (Cash)",
                            squareCustomerId: selectedCustomer?.squareCustomerId
                        )
                    )
                )

                _ = try? historyService.savePurchase(
                    customer: selectedCustomer,
                    cart: cart,
                    paymentMethod: "cash",
                    squareTransactionId: response.paymentId,
                    discount: discountAmount
                )

                handleLoyaltyPoints()

                await MainActor.run {
                    isProcessingSquare = false
                    showingCheckout = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        resetCart()
                    }
                }
            } catch {
                await MainActor.run {
                    isProcessingSquare = false
                    squareErrorMessage = "Cash payment failed: \(error.localizedDescription)"
                    showSquareError = true
                }
            }
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
                // Convert cart total to cents (apply both discount and reward)
                let finalAmount = cart.total - discountAmount - rewardDiscount
                let amountInCents = Int(finalAmount * 100)
                
                await MainActor.run {
                    isProcessingSquare = true
                    squarePaymentStatus = "Creating checkout..."
                }

                let referenceId = "POS-\(UUID().uuidString.prefix(8))"
                let checkoutResponse: SquareSalesCreateTerminalCheckoutResponse = try await SupabaseService.shared.client.functions.invoke(
                    "square-sales",
                    options: FunctionInvokeOptions(
                        body: SquareSalesCreateTerminalCheckoutRequest(
                            deviceId: deviceId,
                            amountCents: amountInCents,
                            referenceId: referenceId,
                            note: "ProTech POS Sale",
                            squareCustomerId: selectedCustomer?.squareCustomerId
                        )
                    )
                )
                
                await MainActor.run {
                    terminalCheckoutId = checkoutResponse.checkoutId
                    squarePaymentStatus = "Waiting for payment on terminal..."
                }
                
                // Poll for checkout completion
                let completed = try await pollCheckoutStatus(checkoutId: checkoutResponse.checkoutId)
                
                if completed {
                    // Save purchase history
                    _ = try? historyService.savePurchase(
                        customer: selectedCustomer,
                        cart: cart,
                        paymentMethod: "card",
                        squareCheckoutId: checkoutResponse.checkoutId,
                        discount: discountAmount
                    )
                    
                    // Handle loyalty points
                    handleLoyaltyPoints()
                    
                    // Payment successful!
                    await MainActor.run {
                        isProcessingSquare = false
                        showingCheckout = true
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                           resetCart()
                        }
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

            let statusResponse: SquareSalesGetTerminalCheckoutResponse = try await SupabaseService.shared.client.functions.invoke(
                "square-sales",
                options: FunctionInvokeOptions(
                    body: SquareSalesGetTerminalCheckoutRequest(checkoutId: checkoutId)
                )
            )

            await MainActor.run {
                squarePaymentStatus = "Status: \(statusResponse.checkoutStatus)"
            }

            if statusResponse.checkoutStatus == "COMPLETED" {
                return true
            } else if statusResponse.checkoutStatus == "CANCELED" {
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
                let _: SquareSalesCancelTerminalCheckoutResponse = try await SupabaseService.shared.client.functions.invoke(
                    "square-sales",
                    options: FunctionInvokeOptions(
                        body: SquareSalesCancelTerminalCheckoutRequest(checkoutId: checkoutId)
                    )
                )
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
        
        // Handle loyalty points
        handleLoyaltyPoints()
        
        // Show success
        showingCheckout = true
        pointsEarned = 100 // Mock points
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
           resetCart()
        }
    }
    
    private func handleLoyaltyPoints() {
        // Award loyalty points if customer is selected
        var earnedPoints: Int32 = 0
        if let customerId = selectedCustomer?.id {
            let finalAmount = cart.total - discountAmount - rewardDiscount
            
            // Calculate points before awarding
            if let program = LoyaltyService.shared.getActiveProgram(),
               let member = LoyaltyService.shared.getMember(for: customerId) {
                var points = Int32(finalAmount * program.pointsPerDollar)
                
                // Apply tier multiplier
                if let tierId = member.currentTierId,
                   let tier = LoyaltyService.shared.getTier(tierId) {
                    points = Int32(Double(points) * tier.pointsMultiplier)
                }
                
                // Add visit bonus
                points += program.pointsPerVisit
                earnedPoints = points
            }
            
            LoyaltyService.shared.awardPointsForPurchase(
                customerId: customerId,
                amount: finalAmount,
                invoiceId: nil
            )
        }
        
        // Redeem loyalty reward if applied
        if let reward = appliedReward,
           let customerId = selectedCustomer?.id,
           let member = LoyaltyService.shared.getMember(for: customerId),
           let memberId = member.id,
           let rewardId = reward.id {
            _ = LoyaltyService.shared.redeemReward(memberId: memberId, rewardId: rewardId)
        }
        
        self.pointsEarned = earnedPoints
    }
    
    private func resetCart() {
        cart.clear()
        selectedPaymentMode = nil
        discountAmount = 0
        discountCode = ""
        rewardDiscount = 0
        appliedReward = nil
        terminalCheckoutId = nil
        showingCheckout = false
        pointsEarned = 0
        
        // Reload customer history and rewards
        loadCustomerHistory()
        loadAvailableRewards()
    }
}

// MARK: - Product Card

struct ProductCard: View {
    let item: InventoryItem
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                // Icon/Image Placeholder
                ZStack {
                    categoryColor.opacity(0.1)
                    Image(systemName: item.inventoryCategory.icon)
                        .font(.system(size: 30))
                        .foregroundColor(categoryColor)
                }
                .frame(height: 100)
                .frame(maxWidth: .infinity)
                .cornerRadius(AppTheme.cardCornerRadius)
                
                // Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name ?? "Unknown Item")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        Text(item.formattedPrice)
                            .font(AppTheme.Typography.body)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.Colors.success)
                        
                        Spacer()
                        
                        Text("\(item.quantity) left")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .premiumCard()
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
                .fill(Color.orange.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: item.icon)
                        .foregroundColor(.orange)
                )
            
            // Product Info
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                Text(formatCurrency(item.price))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Quantity Stepper
            HStack(spacing: 0) {
                Button {
                    cart.decrementQuantity(for: item)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
                
                Text("\(item.quantity)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(width: 30)
                    .multilineTextAlignment(.center)
                
                Button {
                    cart.incrementQuantity(for: item)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(AppTheme.Colors.success)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            
            // Total
            Text(formatCurrency(item.totalPrice))
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.groupedBackground)
        .cornerRadius(AppTheme.cornerRadius)
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
            HStack(spacing: 12) {
                // Icon
                Circle()
                    .fill(isSelected ? accentColor.opacity(0.1) : Color.gray.opacity(0.1))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 16))
                            .foregroundColor(isSelected ? accentColor : .secondary)
                    )
                
                // Text Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "212121"))
                    
                    Text(description)
                        .font(.caption2)
                        .foregroundColor(Color(hex: "757575"))
                        .lineLimit(1)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(accentColor)
                }
            }
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius)
                    .stroke(isSelected ? accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Supporting Models

enum PaymentMode {
    case card
    case cash
    case upi
    case split
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

