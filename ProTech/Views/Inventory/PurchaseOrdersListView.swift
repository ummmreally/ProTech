//
//  PurchaseOrdersListView.swift
//  ProTech
//
//  Purchase order management
//

import SwiftUI

struct PurchaseOrdersListView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PurchaseOrder.orderDate, ascending: false)]
    ) var orders: FetchedResults<PurchaseOrder>
    
    @State private var showingCreatePO = false
    @State private var selectedOrder: PurchaseOrder?
    @State private var filterStatus: String? = nil
    
    var filteredOrders: [PurchaseOrder] {
        if let status = filterStatus {
            return orders.filter { $0.status == status }
        }
        return Array(orders)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter
            HStack {
                Picker("Status", selection: $filterStatus) {
                    Text("All Orders").tag(String?.none)
                    Text("Draft").tag(String?("draft"))
                    Text("Sent").tag(String?("sent"))
                    Text("Partially Received").tag(String?("partially_received"))
                    Text("Received").tag(String?("received"))
                    Text("Cancelled").tag(String?("cancelled"))
                }
                .frame(width: 200)
                
                Spacer()
                
                Text("\(filteredOrders.count) orders")
                    .foregroundColor(.secondary)
            }
            .padding()
            
            Divider()
            
            // List
            if filteredOrders.isEmpty {
                emptyStateView
            } else {
                List {
                    ForEach(filteredOrders, id: \.id) { order in
                        PurchaseOrderRow(order: order)
                            .onTapGesture {
                                selectedOrder = order
                            }
                    }
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle("Purchase Orders")
        .toolbar {
            Button {
                showingCreatePO = true
            } label: {
                Label("Create PO", systemImage: "plus")
            }
        }
        .sheet(isPresented: $showingCreatePO) {
            CreatePurchaseOrderView()
        }
        .sheet(item: $selectedOrder) { order in
            PurchaseOrderDetailView(order: order)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No Purchase Orders")
                .font(.title2)
            Button {
                showingCreatePO = true
            } label: {
                Label("Create First PO", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PurchaseOrderRow: View {
    @ObservedObject var order: PurchaseOrder
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("PO #\(order.orderNumber ?? "Unknown")")
                    .font(.headline)
                if let supplier = order.supplierName {
                    Text(supplier)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                PurchaseOrderStatusBadge(text: statusText, color: statusColor)
                Text(String(format: "$%.2f", order.total))
                    .font(.subheadline)
                    .bold()
            }
        }
        .padding(.vertical, 8)
    }
    
    private var statusText: String {
        switch order.status {
        case "draft": return "Draft"
        case "sent": return "Sent"
        case "confirmed": return "Confirmed"
        case "partially_received": return "Partial"
        case "received": return "Received"
        case "cancelled": return "Cancelled"
        default: return "Unknown"
        }
    }
    
    private var statusColor: Color {
        switch order.status {
        case "draft": return .gray
        case "sent", "confirmed": return .blue
        case "partially_received": return .orange
        case "received": return .green
        case "cancelled": return .red
        default: return .gray
        }
    }
}

struct PurchaseOrderStatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(6)
    }
}

// Placeholder views - implement as needed
struct CreatePurchaseOrderView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        Text("Create PO - Coming Soon")
            .navigationTitle("New Purchase Order")
    }
}

struct PurchaseOrderDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let order: PurchaseOrder
    var body: some View {
        Text("PO Detail - Coming Soon")
            .navigationTitle("PO #\(order.orderNumber ?? "")")
    }
}
