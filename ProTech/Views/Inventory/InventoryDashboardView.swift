//
//  InventoryDashboardView.swift
//  ProTech
//
//  Main inventory dashboard with stats and quick actions
//

import SwiftUI
import Charts

struct InventoryDashboardView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \InventoryItem.name, ascending: true)],
        predicate: NSPredicate(format: "isActive == true")
    ) var items: FetchedResults<InventoryItem>
    
    @FetchRequest(
        sortDescriptors: [],
        predicate: NSPredicate(format: "status IN %@", ["sent", "confirmed", "partially_received"])
    ) var pendingOrders: FetchedResults<PurchaseOrder>
    
    @State private var selectedTab = 0
    
    var lowStockItems: [InventoryItem] {
        items.filter { $0.isLowStock }
    }
    
    var outOfStockItems: [InventoryItem] {
        items.filter { $0.isOutOfStock }
    }
    
    var totalValue: Double {
        items.reduce(0) { $0 + $1.totalValue }
    }
    
    var categoryBreakdown: [(InventoryCategory, Int)] {
        Dictionary(grouping: items) { $0.inventoryCategory }
            .map { ($0.key, $0.value.count) }
            .sorted { $0.1 > $1.1 }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Stats Cards
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        InventoryStatCard(
                            title: "Total Items",
                            value: "\(items.count)",
                            color: .blue,
                            icon: "shippingbox.fill"
                        )
                        
                        InventoryStatCard(
                            title: "Total Value",
                            value: String(format: "$%.0f", totalValue),
                            color: .green,
                            icon: "dollarsign.circle.fill"
                        )
                        
                        InventoryStatCard(
                            title: "Low Stock",
                            value: "\(lowStockItems.count)",
                            color: .orange,
                            icon: "exclamationmark.triangle.fill"
                        )
                        
                        InventoryStatCard(
                            title: "Out of Stock",
                            value: "\(outOfStockItems.count)",
                            color: .red,
                            icon: "xmark.circle.fill"
                        )
                    }
                    .padding(.horizontal)
                    
                    // Alerts
                    if !lowStockItems.isEmpty || !outOfStockItems.isEmpty {
                        VStack(spacing: 12) {
                            if !outOfStockItems.isEmpty {
                                AlertBanner(
                                    title: "Out of Stock Alert",
                                    message: "\(outOfStockItems.count) item(s) are completely out of stock",
                                    icon: "xmark.circle.fill",
                                    color: .red
                                )
                            }
                            
                            if !lowStockItems.isEmpty {
                                AlertBanner(
                                    title: "Low Stock Warning",
                                    message: "\(lowStockItems.count) item(s) need restocking",
                                    icon: "exclamationmark.triangle.fill",
                                    color: .orange
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Category Chart
                    if !categoryBreakdown.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Inventory by Category")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            Chart {
                                ForEach(categoryBreakdown.prefix(8), id: \.0) { category, count in
                                    BarMark(
                                        x: .value("Count", count),
                                        y: .value("Category", category.displayName)
                                    )
                                    .foregroundStyle(Color.blue.gradient)
                                }
                            }
                            .frame(height: 300)
                            .padding()
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                    
                    // Quick Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            NavigationLink(destination: InventoryListView()) {
                                QuickActionCard(
                                    title: "Manage Inventory",
                                    icon: "shippingbox",
                                    color: .blue
                                )
                            }
                            .buttonStyle(.plain)
                            
                            NavigationLink(destination: PurchaseOrdersListView()) {
                                QuickActionCard(
                                    title: "Purchase Orders",
                                    icon: "doc.text",
                                    color: .purple,
                                    badge: pendingOrders.count > 0 ? "\(pendingOrders.count)" : nil
                                )
                            }
                            .buttonStyle(.plain)
                            
                            NavigationLink(destination: SuppliersListView()) {
                                QuickActionCard(
                                    title: "Suppliers",
                                    icon: "building.2",
                                    color: .green
                                )
                            }
                            .buttonStyle(.plain)
                            
                            NavigationLink(destination: StockAdjustmentsListView()) {
                                QuickActionCard(
                                    title: "Stock History",
                                    icon: "clock.arrow.circlepath",
                                    color: .orange
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Inventory Dashboard")
            .toolbar {
                ToolbarItem {
                    NavigationLink(destination: AddInventoryItemView()) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title)
                .bold()
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Alert Banner

struct InventoryStatCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct AlertBanner: View {
    let title: String
    let message: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(color)
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Quick Action Card

struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    var badge: String? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.headline)
            
            Spacer()
            
            if let badge = badge {
                Text(badge)
                    .font(.caption)
                    .bold()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.2))
                    .foregroundColor(color)
                    .cornerRadius(8)
            }
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}
