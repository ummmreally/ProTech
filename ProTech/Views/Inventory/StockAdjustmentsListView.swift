//
//  StockAdjustmentsListView.swift
//  ProTech
//
//  Stock adjustment history
//

import SwiftUI

struct StockAdjustmentsListView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \StockAdjustment.createdAt, ascending: false)],
        animation: .default
    ) var adjustments: FetchedResults<StockAdjustment>
    
    @State private var searchText = ""
    @State private var filterType: String? = nil
    
    var filteredAdjustments: [StockAdjustment] {
        var filtered = Array(adjustments)
        
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.itemName?.localizedCaseInsensitiveContains(searchText) ?? false ||
                $0.reference?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
        
        if let type = filterType {
            filtered = filtered.filter { $0.type == type }
        }
        
        return filtered
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filters
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(10)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                Picker("Type", selection: $filterType) {
                    Text("All Types").tag(String?.none)
                    ForEach(StockAdjustmentType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(String?(type.rawValue))
                    }
                }
                .frame(width: 150)
                
                Text("\(filteredAdjustments.count) records")
                    .foregroundColor(.secondary)
            }
            .padding()
            
            Divider()
            
            // List
            if filteredAdjustments.isEmpty {
                emptyStateView
            } else {
                List {
                    ForEach(filteredAdjustments) { adjustment in
                        StockAdjustmentHistoryRow(adjustment: adjustment)
                    }
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle("Stock History")
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No Stock Adjustments")
                .font(.title2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct StockAdjustmentHistoryRow: View {
    let adjustment: StockAdjustment
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: adjustmentIcon)
                .font(.title3)
                .foregroundColor(adjustmentColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(adjustment.itemName ?? "Unknown Item")
                    .font(.headline)
                
                HStack(spacing: 8) {
                    Text(adjustment.reason ?? "Stock adjustment")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let reference = adjustment.reference {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(reference)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
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
        .padding(.vertical, 4)
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
        case "return": return .blue
        case "sale": return .purple
        case "usage": return .indigo
        default: return .gray
        }
    }
}
