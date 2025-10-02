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
                                    // TODO: Show full history
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
                        showingEditView = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                }
            }
            .sheet(isPresented: $showingStockAdjustment) {
                StockAdjustmentView(item: item)
            }
            .sheet(isPresented: $showingEditView) {
                EditInventoryItemView(item: item)
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
