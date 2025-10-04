//
//  ModernInventoryDashboardView.swift
//  ProTech
//
//  Modern inventory dashboard with POS-style design
//

import SwiftUI
import Charts

struct ModernInventoryDashboardView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \InventoryItem.name, ascending: true)],
        predicate: NSPredicate(format: "isActive == true")
    ) var items: FetchedResults<InventoryItem>
    
    @FetchRequest(
        sortDescriptors: [],
        predicate: NSPredicate(format: "status IN %@", ["sent", "confirmed", "partially_received"])
    ) var pendingOrders: FetchedResults<PurchaseOrder>
    
    @State private var searchText = ""
    @State private var selectedCategory: InventoryCategory?
    
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
        ScrollView {
            VStack(spacing: 0) {
                // Search Bar (like POS)
                searchBar
                    .padding()
                    .background(Color(hex: "F5F5F5"))
                
                // Main Content
                VStack(spacing: 20) {
                    // Stats Cards
                    statsSection
                    
                    // Alerts
                    if !lowStockItems.isEmpty || !outOfStockItems.isEmpty {
                        alertsSection
                    }
                    
                    // Quick Actions
                    quickActionsSection
                    
                    // Category Breakdown
                    if !categoryBreakdown.isEmpty {
                        categorySection
                    }
                }
                .padding()
                .background(Color(hex: "F5F5F5"))
            }
        }
        .background(Color(hex: "F5F5F5"))
        .navigationTitle("Inventory Dashboard")
        .toolbar {
            ToolbarItem {
                Button {
                    // Add item action
                } label: {
                    Label("Add Item", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "00C853"))
            }
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color(hex: "757575"))
            TextField("Search inventory...", text: $searchText)
                .textFieldStyle(.plain)
                .foregroundColor(Color(hex: "212121"))
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ModernStatCard(
                title: "Total Items",
                value: "\(items.count)",
                color: Color(hex: "2196F3"),
                icon: "shippingbox.fill"
            )
            
            ModernStatCard(
                title: "Total Value",
                value: String(format: "$%.0f", totalValue),
                color: Color(hex: "00C853"),
                icon: "dollarsign.circle.fill"
            )
            
            ModernStatCard(
                title: "Low Stock",
                value: "\(lowStockItems.count)",
                color: Color(hex: "FF9800"),
                icon: "exclamationmark.triangle.fill"
            )
            
            ModernStatCard(
                title: "Out of Stock",
                value: "\(outOfStockItems.count)",
                color: Color(hex: "F44336"),
                icon: "xmark.circle.fill"
            )
        }
    }
    
    // MARK: - Alerts Section
    
    private var alertsSection: some View {
        VStack(spacing: 12) {
            if !outOfStockItems.isEmpty {
                ModernAlertBanner(
                    title: "Out of Stock Alert",
                    message: "\(outOfStockItems.count) item(s) need immediate attention",
                    icon: "xmark.circle.fill",
                    color: Color(hex: "F44336")
                )
            }
            
            if !lowStockItems.isEmpty {
                ModernAlertBanner(
                    title: "Low Stock Warning",
                    message: "\(lowStockItems.count) item(s) running low - reorder soon",
                    icon: "exclamationmark.triangle.fill",
                    color: Color(hex: "FF9800")
                )
            }
        }
    }
    
    // MARK: - Quick Actions Section
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: "212121"))
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                NavigationLink(destination: InventoryListView()) {
                    ModernActionCard(
                        title: "Manage Inventory",
                        subtitle: "View and edit items",
                        icon: "shippingbox.fill",
                        color: Color(hex: "2196F3")
                    )
                }
                .buttonStyle(.plain)
                
                NavigationLink(destination: PurchaseOrdersListView()) {
                    ModernActionCard(
                        title: "Purchase Orders",
                        subtitle: "\(pendingOrders.count) pending",
                        icon: "doc.text.fill",
                        color: Color(hex: "9C27B0"),
                        badge: pendingOrders.count > 0 ? "\(pendingOrders.count)" : nil
                    )
                }
                .buttonStyle(.plain)
                
                NavigationLink(destination: SquareSyncDashboardView(context: CoreDataManager.shared.viewContext)) {
                    ModernActionCard(
                        title: "Square Sync",
                        subtitle: "Sync with Square",
                        icon: "arrow.triangle.2.circlepath",
                        color: Color(hex: "4CAF50")
                    )
                }
                .buttonStyle(.plain)
                
                NavigationLink(destination: SuppliersListView()) {
                    ModernActionCard(
                        title: "Suppliers",
                        subtitle: "Manage suppliers",
                        icon: "building.2.fill",
                        color: Color(hex: "00C853")
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Category Section
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Inventory by Category")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: "212121"))
            
            VStack(spacing: 12) {
                ForEach(categoryBreakdown.prefix(8), id: \.0) { category, count in
                    HStack {
                        // Category Name
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(hex: "00C853"))
                                .frame(width: 8, height: 8)
                            Text(category.displayName)
                                .font(.body)
                                .foregroundColor(Color(hex: "212121"))
                        }
                        
                        Spacer()
                        
                        // Count Badge
                        Text("\(count)")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "00C853"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(hex: "B9F6CA"))
                            .cornerRadius(20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(12)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Modern Stat Card

struct ModernStatCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                )
            
            // Value
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "212121"))
            
            // Title
            Text(title)
                .font(.caption)
                .foregroundColor(Color(hex: "757575"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Modern Alert Banner

struct ModernAlertBanner: View {
    let title: String
    let message: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                )
            
            // Text Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color(hex: "212121"))
                Text(message)
                    .font(.caption)
                    .foregroundColor(Color(hex: "757575"))
            }
            
            Spacer()
            
            // Arrow
            Image(systemName: "chevron.right")
                .foregroundColor(Color(hex: "757575"))
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Modern Action Card

struct ModernActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    var badge: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Icon and Badge
            HStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundColor(color)
                    )
                
                Spacer()
                
                if let badge = badge {
                    Text(badge)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(hex: "F44336"))
                        .cornerRadius(20)
                }
            }
            
            // Text Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "212121"))
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(Color(hex: "757575"))
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Preview

struct ModernInventoryDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ModernInventoryDashboardView()
        }
        .frame(width: 1200, height: 800)
    }
}
