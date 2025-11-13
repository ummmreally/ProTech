//
//  InventoryItemDetailView.swift
//  ProTech
//
//  Detailed view of inventory item with stock management
//

import SwiftUI
import Charts

struct InventoryItemDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var item: InventoryItem
    
    @State private var showingStockAdjustment = false
    @State private var showingEditView = false
    @State private var showingFullHistory = false
    @State private var stockHistory: [StockAdjustment] = []
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.2))
                                    .frame(width: 60, height: 60)
                                Image(systemName: categoryIcon)
                                    .font(.title)
                                    .foregroundColor(.blue)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name ?? "Unknown")
                                    .font(.title2)
                                    .bold()
                                Text(item.category ?? "Uncategorized")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        // Status Badges
                        HStack(spacing: 8) {
                            if item.isOutOfStock {
                                InventoryStatusBadge(text: "Out of Stock", color: .red)
                            } else if item.isLowStock {
                                InventoryStatusBadge(text: "Low Stock", color: .orange)
                            } else {
                                InventoryStatusBadge(text: "In Stock", color: .green)
                            }
                            
                            if item.isDiscontinued {
                                InventoryStatusBadge(text: "Discontinued", color: .gray)
                            }
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                    
                    // Quick Stats
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        QuickStatCard(title: "Quantity", value: "\(item.quantity)", icon: "cube.box")
                        QuickStatCard(title: "Value", value: String(format: "$%.2f", item.totalValue), icon: "dollarsign.circle")
                        QuickStatCard(title: "Price", value: String(format: "$%.2f", item.sellingPrice), icon: "tag")
                    }
                    
                    // Stock Management
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Stock Management")
                            .font(.headline)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Current Stock")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(item.quantity)")
                                    .font(.title)
                                    .bold()
                            }
                            
                            Spacer()
                            
                            VStack(spacing: 12) {
                                Button {
                                    quickAdjustStock(change: 1)
                                } label: {
                                    Image(systemName: "plus")
                                        .frame(width: 40, height: 40)
                                }
                                .buttonStyle(.bordered)
                                
                                Button {
                                    if item.quantity > 0 {
                                        quickAdjustStock(change: -1)
                                    }
                                } label: {
                                    Image(systemName: "minus")
                                        .frame(width: 40, height: 40)
                                }
                                .buttonStyle(.bordered)
                                .disabled(item.quantity <= 0)
                            }
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(12)
                        
                        Button {
                            showingStockAdjustment = true
                        } label: {
                            Label("Custom Stock Adjustment", systemImage: "plus.forwardslash.minus")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    // Details
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Details")
                            .font(.headline)
                        
                        VStack(spacing: 0) {
                            InventoryDetailRow(label: "Part Number", value: item.partNumber ?? "—")
                            Divider()
                            InventoryDetailRow(label: "SKU", value: item.sku ?? "—")
                            Divider()
                            InventoryDetailRow(label: "Location", value: item.location ?? "—")
                            Divider()
                            InventoryDetailRow(label: "Min Quantity", value: "\(item.minQuantity)")
                            Divider()
                            InventoryDetailRow(label: "Max Quantity", value: "\(item.maxQuantity)")
                            Divider()
                            InventoryDetailRow(label: "Cost Price", value: String(format: "$%.2f", item.costPrice))
                            Divider()
                            InventoryDetailRow(label: "Selling Price", value: String(format: "$%.2f", item.sellingPrice))
                            if item.msrp > 0 {
                                Divider()
                                InventoryDetailRow(label: "MSRP", value: String(format: "$%.2f", item.msrp))
                            }
                        }
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(12)
                    }
                    
                    // Stock History
                    if !stockHistory.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Stock Changes")
                                .font(.headline)
                            
                            ForEach(stockHistory.prefix(5)) { adjustment in
                                StockAdjustmentRow(adjustment: adjustment)
                            }
                            
                            if stockHistory.count > 5 {
                                Button("View All History") {
                                    showingFullHistory = true
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(item.name ?? "Item Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .automatic) {
                    Button {
                        DymoPrintService.shared.printProductLabel(product: item)
                    } label: {
                        Label("Print Label", systemImage: "printer.fill")
                    }
                    .help("Print product label to Dymo printer")
                }
                
                ToolbarItem(placement: .automatic) {
                    Button {
                        showingEditView = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                }
            }
            .sheet(isPresented: $showingStockAdjustment) {
                StockAdjustmentSheet(item: item) {
                    loadStockHistory()
                }
            }
            .sheet(isPresented: $showingEditView) {
                EditInventoryItemView(item: item)
            }
            .sheet(isPresented: $showingFullHistory) {
                InventoryHistorySheet(item: item, history: stockHistory)
            }
            .onAppear {
                loadStockHistory()
            }
        }
        .frame(width: 700, height: 800)
    }
    
    private var categoryIcon: String {
        guard let category = item.category,
              let inventoryCategory = InventoryCategory(rawValue: category) else {
            return "shippingbox"
        }
        return inventoryCategory.icon
    }
    
    private func quickAdjustStock(change: Int) {
        InventoryService.shared.adjustStock(
            item: item,
            change: change,
            type: change > 0 ? .add : .remove,
            reason: "Quick adjustment"
        )
        loadStockHistory()
    }
    
    private func loadStockHistory() {
        stockHistory = InventoryService.shared.getStockHistory(for: item)
    }
}

// MARK: - Status Badge

struct InventoryStatusBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption)
            .bold()
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(6)
    }
}

// MARK: - Quick Stat Card

struct QuickStatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            Text(value)
                .font(.title3)
                .bold()
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Detail Row

struct InventoryDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .bold()
        }
        .padding()
    }
}

// MARK: - Stock Adjustment Row

struct StockAdjustmentRow: View {
    let adjustment: StockAdjustment
    
    var body: some View {
        HStack {
            Image(systemName: adjustmentIcon)
                .foregroundColor(adjustmentColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(adjustment.reason ?? "Stock adjustment")
                    .font(.subheadline)
                if let reference = adjustment.reference {
                    Text(reference)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(adjustment.quantityChange > 0 ? "+" : "")\(adjustment.quantityChange)")
                    .font(.headline)
                    .foregroundColor(adjustment.quantityChange > 0 ? .green : .red)
                if let date = adjustment.createdAt {
                    Text(date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var adjustmentIcon: String {
        guard let type = adjustment.type,
              let adjustmentType = StockAdjustmentType(rawValue: type) else {
            return "arrow.up.arrow.down"
        }
        return adjustmentType.icon
    }
    
    private var adjustmentColor: Color {
        guard let type = adjustment.type else { return .gray }
        switch type {
        case "add": return .green
        case "remove": return .red
        case "damaged": return .orange
        default: return .blue
        }
    }
}

// MARK: - Inventory History Sheet

struct InventoryHistorySheet: View {
    @Environment(\.dismiss) private var dismiss
    let item: InventoryItem
    let history: [StockAdjustment]
    
    @State private var searchText = ""
    @State private var filterType: String = "all"
    @State private var sortOrder: SortOrder = .dateDescending
    
    enum SortOrder: String, CaseIterable {
        case dateDescending = "Newest First"
        case dateAscending = "Oldest First"
        case quantityDescending = "Largest Change"
        case quantityAscending = "Smallest Change"
    }
    
    var filteredAndSortedHistory: [StockAdjustment] {
        var filtered = history
        
        // Filter by type
        if filterType != "all" {
            filtered = filtered.filter { $0.type == filterType }
        }
        
        // Search filter
        if !searchText.isEmpty {
            filtered = filtered.filter {
                ($0.reason?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                ($0.reference?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                ($0.performedBy?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Sort
        switch sortOrder {
        case .dateDescending:
            filtered.sort { ($0.createdAt ?? Date()) > ($1.createdAt ?? Date()) }
        case .dateAscending:
            filtered.sort { ($0.createdAt ?? Date()) < ($1.createdAt ?? Date()) }
        case .quantityDescending:
            filtered.sort { abs($0.quantityChange) > abs($1.quantityChange) }
        case .quantityAscending:
            filtered.sort { abs($0.quantityChange) < abs($1.quantityChange) }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filters and search
                VStack(spacing: 12) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search history...", text: $searchText)
                            .textFieldStyle(.plain)
                    }
                    .padding(10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    
                    // Filters
                    HStack {
                        // Type filter
                        Picker("Type", selection: $filterType) {
                            Text("All Types").tag("all")
                            Text("Added").tag("add")
                            Text("Removed").tag("remove")
                            Text("Damaged").tag("damaged")
                            Text("Set").tag("set")
                        }
                        .pickerStyle(.segmented)
                        
                        Spacer()
                        
                        // Sort order
                        Menu {
                            ForEach(SortOrder.allCases, id: \.self) { order in
                                Button(order.rawValue) {
                                    sortOrder = order
                                }
                            }
                        } label: {
                            Label(sortOrder.rawValue, systemImage: "arrow.up.arrow.down")
                        }
                    }
                }
                .padding()
                
                Divider()
                
                // History list
                if filteredAndSortedHistory.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No History Found")
                            .font(.headline)
                        Text(searchText.isEmpty ? "No stock adjustments have been made" : "No adjustments match your search")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredAndSortedHistory) { adjustment in
                                DetailedStockAdjustmentRow(adjustment: adjustment)
                            }
                        }
                        .padding()
                    }
                    
                    // Summary footer
                    VStack(spacing: 8) {
                        Divider()
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Total Adjustments")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(filteredAndSortedHistory.count)")
                                    .font(.headline)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Net Change")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                let netChange = filteredAndSortedHistory.reduce(0) { $0 + $1.quantityChange }
                                Text("\(netChange > 0 ? "+" : "")\(netChange)")
                                    .font(.headline)
                                    .foregroundColor(netChange > 0 ? .green : netChange < 0 ? .red : .primary)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("\(item.name ?? "Item") History")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .automatic) {
                    Button {
                        exportToCSV()
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    .disabled(filteredAndSortedHistory.isEmpty)
                }
            }
        }
        .frame(width: 700, height: 600)
    }
    
    private func exportToCSV() {
        let csvContent = generateCSV()
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.commaSeparatedText]
        savePanel.nameFieldStringValue = "\(item.name ?? "item")-history.csv"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                try? csvContent.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }
    
    private func generateCSV() -> String {
        var csv = "Date,Type,Reason,Reference,Quantity Before,Change,Quantity After,Performed By\n"
        
        for adjustment in filteredAndSortedHistory {
            let date = (adjustment.createdAt ?? Date()).formatted(date: .abbreviated, time: .shortened)
            let type = adjustment.type ?? ""
            let reason = (adjustment.reason ?? "").replacingOccurrences(of: ",", with: ";")
            let reference = (adjustment.reference ?? "").replacingOccurrences(of: ",", with: ";")
            let qtyBefore = adjustment.quantityBefore
            let change = adjustment.quantityChange
            let qtyAfter = adjustment.quantityAfter
            let performedBy = (adjustment.performedBy ?? "").replacingOccurrences(of: ",", with: ";")
            
            csv += "\(date),\(type),\(reason),\(reference),\(qtyBefore),\(change),\(qtyAfter),\(performedBy)\n"
        }
        
        return csv
    }
}

// MARK: - Detailed Stock Adjustment Row

struct DetailedStockAdjustmentRow: View {
    let adjustment: StockAdjustment
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: adjustmentIcon)
                    .foregroundColor(adjustmentColor)
                    .font(.title3)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(adjustment.reason ?? "Stock adjustment")
                        .font(.headline)
                    
                    if let reference = adjustment.reference, !reference.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "link")
                                .font(.caption2)
                            Text(reference)
                                .font(.subheadline)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    if let performedBy = adjustment.performedBy, !performedBy.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "person")
                                .font(.caption2)
                            Text(performedBy)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    // Change amount
                    Text("\(adjustment.quantityChange > 0 ? "+" : "")\(adjustment.quantityChange)")
                        .font(.title3)
                        .bold()
                        .foregroundColor(adjustment.quantityChange > 0 ? .green : .red)
                    
                    // Before → After
                    HStack(spacing: 4) {
                        Text("\(adjustment.quantityBefore)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(adjustment.quantityAfter)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Date
                    if let date = adjustment.createdAt {
                        Text(date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Notes if present
            if let notes = adjustment.notes, !notes.isEmpty {
                HStack {
                    Text("Note:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var adjustmentIcon: String {
        guard let type = adjustment.type,
              let adjustmentType = StockAdjustmentType(rawValue: type) else {
            return "arrow.up.arrow.down"
        }
        return adjustmentType.icon
    }
    
    private var adjustmentColor: Color {
        guard let type = adjustment.type else { return .gray }
        switch type {
        case "add": return .green
        case "remove": return .red
        case "damaged": return .orange
        default: return .blue
        }
    }
}
