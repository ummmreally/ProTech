//
//  InventoryNotifications.swift
//  ProTech
//
//  Low stock notifications and inventory alerts with Supabase
//

import SwiftUI
@preconcurrency import UserNotifications

// MARK: - Low Stock Alert View

struct LowStockAlertView: View {
    @StateObject private var inventoryMonitor = InventoryMonitor()
    @State private var showAllItems = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Label("Low Stock Alerts", systemImage: "exclamationmark.triangle.fill")
                    .font(.headline)
                    .foregroundColor(.orange)
                
                Spacer()
                
                if inventoryMonitor.isMonitoring {
                    LiveStatusIndicator(isLive: true)
                }
                
                // Refresh button
                Button(action: {
                    Task {
                        await inventoryMonitor.checkLowStock()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
            }
            
            if inventoryMonitor.lowStockItems.isEmpty {
                // No alerts
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("All items sufficiently stocked")
                        .foregroundColor(.secondary)
                }
                .font(.subheadline)
                .padding(.vertical, 8)
            } else {
                // Alert list
                VStack(spacing: 8) {
                    ForEach(inventoryMonitor.lowStockItems.prefix(showAllItems ? 100 : 3)) { item in
                        LowStockItemRow(item: item)
                    }
                    
                    if inventoryMonitor.lowStockItems.count > 3 && !showAllItems {
                        Button(action: { showAllItems.toggle() }) {
                            Text("Show \(inventoryMonitor.lowStockItems.count - 3) more...")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding()
        .background(inventoryMonitor.hasUrgentItems ? 
                   Color.orange.opacity(0.05) : 
                   Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(inventoryMonitor.hasUrgentItems ? 
                       Color.orange.opacity(0.5) : 
                       Color.clear, lineWidth: 1)
        )
        .onAppear {
            inventoryMonitor.startMonitoring()
        }
        .onDisappear {
            inventoryMonitor.stopMonitoring()
        }
    }
}

// MARK: - Low Stock Item Row

struct LowStockItemRow: View {
    let item: LowStockItem
    @State private var isOrdering = false
    @State private var showReorderSheet = false
    
    var stockLevel: StockLevel {
        let percentage = Double(item.quantity) / Double(item.minQuantity)
        if percentage <= 0 {
            return .outOfStock
        } else if percentage <= 0.5 {
            return .critical
        } else if percentage <= 1.0 {
            return .low
        } else {
            return .normal
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(stockLevel.color)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(stockLevel.color.opacity(0.3), lineWidth: 8)
                        .scaleEffect(item.quantity == 0 ? 2 : 1)
                        .opacity(item.quantity == 0 ? 0 : 1)
                        .animation(
                            item.quantity == 0 ? 
                            Animation.easeOut(duration: 1.0).repeatForever(autoreverses: true) : 
                            .default,
                            value: item.quantity
                        )
                )
            
            // Item info
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 8) {
                    if let sku = item.sku {
                        Text("SKU: \(sku)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("\(item.quantity) / \(item.minQuantity) units")
                        .font(.caption)
                        .foregroundColor(stockLevel.color)
                        .fontWeight(.medium)
                }
            }
            
            Spacer()
            
            // Quick actions
            HStack(spacing: 8) {
                // Reorder button
                Button(action: { showReorderSheet = true }) {
                    Label("Reorder", systemImage: "cart.badge.plus")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(isOrdering)
                
                // Urgency badge
                if stockLevel == .outOfStock {
                    Text("OUT")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                } else if stockLevel == .critical {
                    Text("CRITICAL")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(stockLevel == .outOfStock ? 
                   Color.red.opacity(0.05) : 
                   Color.clear)
        .cornerRadius(6)
        .sheet(isPresented: $showReorderSheet) {
            ReorderSheet(item: item, isOrdering: $isOrdering)
        }
    }
}

// MARK: - Reorder Sheet

struct ReorderSheet: View {
    let item: LowStockItem
    @Binding var isOrdering: Bool
    @Environment(\.dismiss) private var dismiss
    
    @State private var orderQuantity = 50
    @State private var notes = ""
    @State private var priority = OrderPriority.normal
    
    enum OrderPriority: String, CaseIterable {
        case low = "Low"
        case normal = "Normal"
        case urgent = "Urgent"
        
        var color: Color {
            switch self {
            case .low: return .gray
            case .normal: return .blue
            case .urgent: return .red
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "cart.badge.plus")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
                
                Text("Reorder \(item.name)")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Current stock: \(item.quantity) units")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Order form
            Form {
                // Quantity
                HStack {
                    Text("Quantity to Order:")
                    Spacer()
                    TextField("Quantity", value: $orderQuantity, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                        .multilineTextAlignment(.trailing)
                    Stepper("", value: $orderQuantity, in: 1...1000, step: 10)
                }
                
                // Priority
                Picker("Priority:", selection: $priority) {
                    ForEach(OrderPriority.allCases, id: \.self) { priority in
                        Label(priority.rawValue, systemImage: "flag.fill")
                            .foregroundColor(priority.color)
                            .tag(priority)
                    }
                }
                .pickerStyle(.segmented)
                
                // Notes
                VStack(alignment: .leading) {
                    Text("Notes:")
                    TextEditor(text: $notes)
                        .frame(height: 80)
                        .font(.system(size: 12))
                        .border(Color.gray.opacity(0.2))
                }
                
                // Estimated restock
                HStack {
                    Text("Estimated after reorder:")
                    Spacer()
                    Text("\(item.quantity + orderQuantity) units")
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
            }
            .padding()
            
            // Actions
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button(action: submitOrder) {
                    Label("Place Order", systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(orderQuantity <= 0)
            }
        }
        .padding(30)
        .frame(width: 500, height: 450)
    }
    
    private func submitOrder() {
        isOrdering = true
        
        // In production, this would create a purchase order
        Task {
            // Simulate order submission
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            await MainActor.run {
                // Show success notification using modern UserNotifications
                if #available(macOS 10.14, *) {
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
                        guard granted else { return }
                        
                        let content = UNMutableNotificationContent()
                        content.title = "Reorder Submitted"
                        content.body = "Order for \(orderQuantity) units of \(item.name) has been placed"
                        content.sound = .default
                        
                        let request = UNNotificationRequest(
                            identifier: UUID().uuidString,
                            content: content,
                            trigger: nil
                        )
                        
                        UNUserNotificationCenter.current().add(request) { error in
                            if let error = error {
                                print("Notification error: \(error)")
                            }
                        }
                    }
                }
                
                isOrdering = false
                dismiss()
            }
        }
    }
}

// MARK: - Inventory Dashboard

struct InventoryDashboard: View {
    @StateObject private var inventoryMonitor = InventoryMonitor()
    @StateObject private var inventorySyncer = InventorySyncer()
    @State private var selectedCategory: String? = nil
    @State private var searchText = ""
    @State private var showOnlyLowStock = false
    @State private var isRefreshing = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    Text("Inventory")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    // Stats
                    HStack(spacing: 20) {
                        InventoryStatBadge(
                            label: "Total Items",
                            value: "\(inventoryMonitor.totalItems)",
                            color: .blue
                        )
                        
                        InventoryStatBadge(
                            label: "Low Stock",
                            value: "\(inventoryMonitor.lowStockItems.count)",
                            color: .orange
                        )
                        
                        InventoryStatBadge(
                            label: "Out of Stock",
                            value: "\(inventoryMonitor.outOfStockCount)",
                            color: .red
                        )
                    }
                    
                    SyncStatusBadge()
                }
                
                // Filters
                HStack(spacing: 12) {
                    // Search
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search inventory...", text: $searchText)
                            .textFieldStyle(.plain)
                    }
                    .padding(8)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .frame(maxWidth: 300)
                    
                    // Low stock filter
                    Toggle(isOn: $showOnlyLowStock) {
                        Label("Low Stock Only", systemImage: "exclamationmark.triangle")
                    }
                    .toggleStyle(.button)
                    
                    Spacer()
                    
                    // Refresh
                    Button(action: {
                        Task { await refreshInventory() }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .disabled(isRefreshing)
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Low stock alerts
            if inventoryMonitor.hasUrgentItems {
                LowStockAlertView()
                    .padding()
            }
            
            // Main content
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredItems) { item in
                        InventoryItemCard(item: item)
                    }
                }
                .padding()
            }
            .pullToRefresh(isRefreshing: $isRefreshing, onRefresh: {
                await refreshInventory()
            })
        }
        .onAppear {
            inventoryMonitor.startMonitoring()
        }
    }
    
    private var filteredItems: [LowStockItem] {
        var items = inventoryMonitor.allItems
        
        if showOnlyLowStock {
            items = inventoryMonitor.lowStockItems
        }
        
        if !searchText.isEmpty {
            items = items.filter { item in
                item.name.localizedCaseInsensitiveContains(searchText) ||
                item.sku?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        return items
    }
    
    private func refreshInventory() async {
        isRefreshing = true
        do {
            try await inventorySyncer.download()
            await inventoryMonitor.checkLowStock()
        } catch {
            print("Failed to refresh inventory: \(error)")
        }
        isRefreshing = false
    }
}

// MARK: - Supporting Views

private struct InventoryStatBadge: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct InventoryItemCard: View {
    let item: LowStockItem
    
    var stockPercentage: Double {
        guard item.minQuantity > 0 else { return 1.0 }
        return min(Double(item.quantity) / Double(item.minQuantity), 1.0)
    }
    
    var stockColor: Color {
        if stockPercentage <= 0 {
            return .red
        } else if stockPercentage <= 0.5 {
            return .orange
        } else {
            return .green
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Stock indicator
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: stockPercentage)
                    .stroke(stockColor, lineWidth: 4)
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(stockPercentage * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            // Item details
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                
                HStack(spacing: 12) {
                    if let sku = item.sku {
                        Label(sku, systemImage: "barcode")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Label("\(item.category ?? "Uncategorized")", systemImage: "folder")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Stock info
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(item.quantity)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(stockColor)
                
                Text("Min: \(item.minQuantity)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Models

struct LowStockItem: Identifiable {
    let id: UUID
    let name: String
    let sku: String?
    let category: String?
    let quantity: Int
    let minQuantity: Int
    let price: Double
}

enum StockLevel {
    case outOfStock
    case critical
    case low
    case normal
    
    var color: Color {
        switch self {
        case .outOfStock: return .red
        case .critical: return .orange
        case .low: return .yellow
        case .normal: return .green
        }
    }
}

// MARK: - Inventory Monitor

@MainActor
class InventoryMonitor: ObservableObject {
    @Published var lowStockItems: [LowStockItem] = []
    @Published var allItems: [LowStockItem] = []
    @Published var isMonitoring = false
    @Published var hasUrgentItems = false
    @Published var totalItems = 0
    @Published var outOfStockCount = 0
    
    private let supabase = SupabaseService.shared
    private let syncer = InventorySyncer()
    // TODO: Uncomment when Supabase Realtime types are available
    // private var channel: RealtimeChannel?
    
    func startMonitoring() {
        Task {
            await checkLowStock()
        }
        // TODO: Implement proper Supabase Realtime inventory monitoring
        isMonitoring = true
    }
    
    func stopMonitoring() {
        isMonitoring = false
    }
    
    func checkLowStock() async {
        do {
            let items = try await syncer.checkLowStock()
            
            let lowStock = items.compactMap { item -> LowStockItem? in
                guard let itemId = item.id else { return nil }
                return LowStockItem(
                    id: itemId,
                    name: item.name ?? "Unknown",
                    sku: item.sku,
                    category: item.category,
                    quantity: Int(item.quantity),
                    minQuantity: Int(item.minQuantity),
                    price: item.costDouble
                )
            }
            
            await MainActor.run {
                self.lowStockItems = lowStock
                self.outOfStockCount = lowStock.filter { $0.quantity == 0 }.count
                self.hasUrgentItems = self.outOfStockCount > 0 || lowStock.count > 5
                
                // Send notification for critical items
                for item in lowStock where item.quantity == 0 {
                    sendOutOfStockNotification(for: item)
                }
            }
            
            // Also fetch all items for the dashboard
            await fetchAllItems()
        } catch {
            print("Failed to check low stock: \(error)")
        }
    }
    
    private func fetchAllItems() async {
        // In production, this would fetch from Core Data or Supabase
        // For now, using mock data combined with low stock items
        totalItems = 150 // Mock total
        allItems = lowStockItems // For demo purposes
    }
    
    private func sendOutOfStockNotification(for item: LowStockItem) {
        guard #available(macOS 11.0, *) else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "⚠️ Out of Stock"
            content.body = "\(item.name) is now out of stock"
            content.sound = .default
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        }
    }
}

#Preview {
    InventoryDashboard()
}
