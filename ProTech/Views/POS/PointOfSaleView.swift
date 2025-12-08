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
    
    enum LeftPanelTab: String, CaseIterable {
        case products = "Products"
        case history = "Customer History"
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
                .background(Color(hex: "F5F5F5"))
            
            // Right Panel - Cart & Payment
            rightPanel
                .frame(width: 420)
                .background(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 10, x: -2, y: 0)
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
                
                if selectedCustomer != nil {
                    Picker("View", selection: $selectedLeftTab) {
                        ForEach(LeftPanelTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                }
                
                if selectedLeftTab == .products {
                    categoryFilter
                        .padding(.bottom, 8)
                }
            }
            .padding(.top)
            .background(Color.white)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 5)
            .zIndex(1)
            
            // Content
            if selectedLeftTab == .products {
                productGrid
            } else {
                customerHistoryView
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
                .foregroundColor(Color(hex: "757575"))
            TextField("Search products...", text: $searchText)
                .textFieldStyle(.plain)
                .foregroundColor(Color(hex: "212121"))
        }
        .padding(12)
        .background(Color(hex: "F5F5F5"))
        .cornerRadius(12)
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
                            .foregroundColor(Color(hex: "212121"))
                        
                        // Square Terminal Device Selector
                        if selectedPaymentMode == .card && !squareDevices.isEmpty {
                            Picker("Square Terminal", selection: $selectedDeviceId) {
                                Text("Select Terminal...").tag(nil as String?)
                                ForEach(squareDevices) { device in
                                    Text(device.name ?? "Terminal \(device.code)").tag(device.deviceId as String?)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(.bottom, 8)
                        }
                        
                        VStack(spacing: 10) {
                            PaymentModeCard(
                                icon: "creditcard.fill",
                                title: "Card",
                                description: "Square Terminal",
                                isSelected: selectedPaymentMode == .card,
                                accentColor: Color(hex: "00C853")
                            ) { selectedPaymentMode = .card }
                            
                            PaymentModeCard(
                                icon: "dollarsign.circle.fill",
                                title: "Cash",
                                description: "Cash payment",
                                isSelected: selectedPaymentMode == .cash,
                                accentColor: Color(hex: "00C853")
                            ) { selectedPaymentMode = .cash }
                            
                            PaymentModeCard(
                                icon: "qrcode",
                                title: "Other",
                                description: "External/UPI",
                                isSelected: selectedPaymentMode == .upi,
                                accentColor: Color(hex: "00C853")
                            ) { selectedPaymentMode = .upi }
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
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(canConfirmPayment ? Color(hex: "00C853") : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .disabled(!canConfirmPayment || isProcessingSquare)
            }
            .padding()
            .background(Color(hex: "F9F9F9"))
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
                    .background(Color(hex: "F5F5F5"))
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
                .background(Color(hex: "F5F5F5"))
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
                // Convert cart total to cents (apply both discount and reward)
                let finalAmount = cart.total - discountAmount - rewardDiscount
                let amountInCents = Int(finalAmount * 100)
                
                await MainActor.run {
                    isProcessingSquare = true
                    squarePaymentStatus = "Creating checkout..."
                }
                
                // Create terminal checkout
                let checkout = try await SquareAPIService.shared.createTerminalCheckout(
                    amount: amountInCents,
                    deviceId: deviceId,
                    referenceId: "POS-\(UUID().uuidString.prefix(8))",
                    note: "ProTech POS Sale"
                )
                
                await MainActor.run {
                    terminalCheckoutId = checkout.id
                    squarePaymentStatus = "Waiting for payment on terminal..."
                }
                
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
            VStack(alignment: .leading, spacing: 8) {
                // Icon/Image Placeholder
                ZStack {
                    Color.gray.opacity(0.1)
                    Image(systemName: item.inventoryCategory.icon)
                        .font(.system(size: 30))
                        .foregroundColor(categoryColor)
                }
                .frame(height: 100)
                .frame(maxWidth: .infinity)
                .cornerRadius(10)
                
                // Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name ?? "Unknown Item")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color(hex: "212121"))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        Text(item.formattedPrice)
                            .font(.footnote)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "00C853"))
                        
                        Spacer()
                        
                        Text("\(item.quantity) left")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
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
                    .foregroundColor(Color(hex: "212121"))
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
                        .foregroundColor(Color(hex: "00C853"))
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
        .padding(10)
        .background(Color(hex: "F9F9F9"))
        .cornerRadius(8)
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
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
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

