//
//  InventoryListView.swift
//  ProTech
//
//  Comprehensive inventory list with search, filter, and management
//

import SwiftUI

struct InventoryListView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \InventoryItem.name, ascending: true)],
        predicate: NSPredicate(format: "isActive == true")
    ) var items: FetchedResults<InventoryItem>
    
    @State private var searchText = ""
    @State private var selectedCategory: InventoryCategory = .all
    @State private var sortOption: InventorySortOption = .name
    @State private var showLowStockOnly = false
    @State private var showingAddItem = false
    @State private var selectedItem: InventoryItem?
    @State private var adjustingItem: InventoryItem?
    @State private var showingBatchPrintDialog = false
    @State private var labelCopies = 1
    @State private var isRefreshing = false
    @StateObject private var inventorySyncer = InventorySyncer()
    
    var lowStockItems: [InventoryItem] {
        items.filter { $0.quantity <= $0.minQuantity }
    }
    
    var filteredItems: [InventoryItem] {
        var filtered = Array(items)
        
        // Search filter
        if !searchText.isEmpty {
            filtered = filtered.filter {
                ($0.name?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                ($0.partNumber?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                ($0.sku?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        
        // Category filter
        if selectedCategory != .all {
            filtered = filtered.filter { $0.inventoryCategory == selectedCategory }
        }
        
        // Low stock filter logic (updated for reorderPoint)
        if showLowStockOnly {
            filtered = filtered.filter { $0.quantity <= $0.reorderPoint }
        }
        
        // Sort
        switch sortOption {
        case .name:
            filtered.sort { ($0.name ?? "") < ($1.name ?? "") }
        case .quantity:
            filtered.sort { $0.quantity > $1.quantity }
        case .price:
            filtered.sort { $0.priceDouble > $1.priceDouble }
        case .lowStock:
            filtered.sort { $0.quantity < $1.quantity }
        case .value:
            filtered.sort { $0.totalValue > $1.totalValue }
        }
        
        return filtered
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Offline Banner
            OfflineBanner()
            
            // Header with Sync Badge
            HStack {
                Text("Inventory")
                    .font(AppTheme.Typography.largeTitle)
                    .bold()
                
                SyncStatusBadge()
                
                Spacer()
            }
            // Warning Header
            if !lowStockItems.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.white)
                    
                    Text("\(lowStockItems.count) Items Low Stock")
                        .bold()
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button {
                        showLowStockOnly = true
                    } label: {
                        Text("View All")
                            .font(AppTheme.Typography.caption)
                            .bold()
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(4)
                            .foregroundColor(.white)
                    }
                }
                .padding()
                .background(Color.orange)
                .cornerRadius(AppTheme.cardCornerRadius)
                .padding(.horizontal)
            }
            
            // Search and Filters
            VStack(spacing: AppTheme.Spacing.md) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search items, part numbers, SKU...", text: $searchText)
                        .textFieldStyle(.plain)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(AppTheme.Spacing.sm)
                .background(AppTheme.Colors.cardBackground)
                .cornerRadius(AppTheme.cardCornerRadius)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                
                HStack {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(InventoryCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                    .frame(width: 200)
                    
                    Picker("Sort", selection: $sortOption) {
                        ForEach(InventorySortOption.allCases, id: \.self) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .frame(width: 150)
                    
                    Toggle("Low Stock Only", isOn: $showLowStockOnly)
                    
                    Spacer()
                    
                    Text("\(filteredItems.count) items")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(AppTheme.Spacing.xl)
            
            Divider()
            
            // Inventory List (Themed)
            if filteredItems.isEmpty {
                emptyStateView
            } else {
                List {
                    ForEach(filteredItems, id: \.id) { item in
                        InventoryItemRow(item: item)
                            .padding(.horizontal, 4) // Inner padding adjustment for card content
                            .premiumCard()
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .padding(.vertical, 4) // Spacing between cards
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedItem = item
                            }
                            .contextMenu {
                                Button {
                                    selectedItem = item
                                } label: {
                                    Label("View Details", systemImage: "eye")
                                }
                                
                                Button {
                                    adjustStock(item: item)
                                } label: {
                                    Label("Adjust Stock", systemImage: "plus.forwardslash.minus")
                                }
                                
                                Button {
                                    DymoPrintService.shared.printProductLabel(product: item)
                                } label: {
                                    Label("Print Label", systemImage: "printer.fill")
                                }
                                
                                Divider()
                                
                                Button(role: .destructive) {
                                    deleteItem(item)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(AppTheme.Colors.groupedBackground)
        .navigationTitle("Inventory")
        .toolbar {
            ToolbarItemGroup {
                Menu {
                    Button {
                        printAllVisibleLabels()
                    } label: {
                        Label("Print All Visible (\(filteredItems.count))", systemImage: "printer.fill")
                    }
                    .disabled(filteredItems.isEmpty)
                    
                    Button {
                        showingBatchPrintDialog = true
                    } label: {
                        Label("Print with Options...", systemImage: "printer.dotmatrix.fill")
                    }
                    .disabled(filteredItems.isEmpty)
                } label: {
                    Label("Print Labels", systemImage: "printer")
                }
                
                Button {
                    exportInventory()
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                
                NavigationLink(destination: SupplierListView()) {
                    Label("Suppliers", systemImage: "shippingbox.fill")
                }
                
                Button {
                    showingAddItem = true
                } label: {
                    Label("Add Item", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddInventoryItemView()
        }
        .sheet(item: $selectedItem) { item in
            InventoryItemDetailView(item: item)
        }
        .sheet(item: $adjustingItem) { item in
            StockAdjustmentSheet(item: item)
        }
        .sheet(isPresented: $showingBatchPrintDialog) {
            BatchPrintOptionsView(
                itemCount: filteredItems.count,
                onPrint: { copies in
                    printLabelsWithCopies(copies)
                }
            )
        }
        .pullToRefresh(isRefreshing: $isRefreshing) {
            do {
                // Sync with Supabase
                try await inventorySyncer.download()
                
                // Sync with Square
                try await SquareInventorySyncManager.shared.syncChangedItems(since: SquareInventorySyncManager.shared.lastSyncDate ?? .distantPast)
            } catch {
                print("⚠️ Failed to sync inventory: \(error.localizedDescription)")
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Image(systemName: searchText.isEmpty ? "shippingbox" : "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text(searchText.isEmpty ? "No Inventory Items" : "No Results Found")
                .font(AppTheme.Typography.title2)
                .foregroundColor(.secondary)
            if searchText.isEmpty {
                Button {
                    showingAddItem = true
                } label: {
                    Label("Add First Item", systemImage: "plus")
                }
                .buttonStyle(PremiumButtonStyle(variant: .primary))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func adjustStock(item: InventoryItem) {
        adjustingItem = item
    }
    
    private func deleteItem(_ item: InventoryItem) {
        InventoryService.shared.deleteItem(item)
    }
    
    private func printAllVisibleLabels() {
        DymoPrintService.shared.printProductLabels(products: filteredItems, copies: 1)
    }
    
    private func printLabelsWithCopies(_ copies: Int) {
        DymoPrintService.shared.printProductLabels(products: filteredItems, copies: copies)
    }
    
    private func exportInventory() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.commaSeparatedText]
        savePanel.nameFieldStringValue = "inventory_\(Date().formatted(date: .numeric, time: .omitted)).csv"
        
        savePanel.begin { response in
            guard response == .OK, let url = savePanel.url else { return }
            
            var csv = "Name,Part Number,SKU,Category,Quantity,Cost Price,Selling Price\n"
            for item in filteredItems {
                csv += "\(item.name ?? ""),\(item.partNumber ?? ""),\(item.sku ?? ""),\(item.category ?? ""),\(item.quantity),\(item.costDouble),\(item.priceDouble)\n"
            }
            
            try? csv.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}

// MARK: - Inventory Item Row

struct InventoryItemRow: View {
    @ObservedObject var item: InventoryItem
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            // Icon
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: categoryIcon)
                    .foregroundColor(categoryColor)
            }
            
            // Info
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(item.name ?? "Unknown")
                    .font(AppTheme.Typography.headline)
                
                HStack(spacing: AppTheme.Spacing.sm) {
                    if let partNumber = item.partNumber {
                        Text("PN: \(partNumber)")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let sku = item.sku {
                        Text("SKU: \(sku)")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Stock Status
            VStack(alignment: .trailing, spacing: AppTheme.Spacing.xs) {
                HStack(spacing: 6) {
                    if item.isOutOfStock {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    } else if item.isLowStock {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                    }
                    
                    Text("\(item.quantity)")
                        .font(AppTheme.Typography.title3)
                        .bold()
                        .foregroundColor(item.isOutOfStock ? .red : item.isLowStock ? .orange : .primary)
                }
                
                Text(String(format: "$%.2f", item.priceDouble))
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Sync status indicator
            if let syncStatus = item.cloudSyncStatus {
                syncStatusIcon(for: syncStatus)
            }
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
    
    private func syncStatusIcon(for status: String) -> some View {
        Group {
            switch status {
            case "synced":
                Image(systemName: "checkmark.icloud.fill")
                    .foregroundColor(.green)
                    .font(AppTheme.Typography.caption)
                    .help("Synced to cloud")
            case "pending":
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.orange)
                    .font(AppTheme.Typography.caption)
                    .help("Sync pending")
            case "failed":
                Image(systemName: "exclamationmark.icloud.fill")
                    .foregroundColor(.red)
                    .font(AppTheme.Typography.caption)
                    .help("Sync failed - will retry")
            default:
                EmptyView()
            }
        }
    }
    
    private var categoryIcon: String {
        guard let category = item.category,
              let inventoryCategory = InventoryCategory(rawValue: category) else {
            return "shippingbox"
        }
        return inventoryCategory.icon
    }
    
    private var categoryColor: Color {
        switch item.category {
        case "screens": return .blue
        case "batteries": return .green
        case "cables": return .orange
        case "tools": return .purple
        default: return .gray
        }
    }
}

// MARK: - Sort Option

enum InventorySortOption: String, CaseIterable {
    case name = "name"
    case quantity = "quantity"
    case price = "price"
    case lowStock = "low_stock"
    case value = "value"
    
    var displayName: String {
        switch self {
        case .name: return "Name"
        case .quantity: return "Quantity"
        case .price: return "Price"
        case .lowStock: return "Low Stock"
        case .value: return "Total Value"
        }
    }
}
