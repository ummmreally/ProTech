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

// MARK: - Create Purchase Order View

struct CreatePurchaseOrderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Supplier.name, ascending: true)],
        predicate: NSPredicate(format: "isActive == YES")
    ) private var suppliers: FetchedResults<Supplier>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \InventoryItem.name, ascending: true)],
        predicate: NSPredicate(format: "isActive == YES")
    ) private var inventoryItems: FetchedResults<InventoryItem>
    
    @State private var selectedSupplierId: UUID?
    @State private var expectedDeliveryDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var lineItems: [POLineItem] = []
    @State private var shippingCost: Double = 0.0
    @State private var taxRate: Double = 0.0
    @State private var notes: String = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Supplier") {
                    Picker("Select Supplier", selection: $selectedSupplierId) {
                        Text("Select a supplier").tag(UUID?.none)
                        ForEach(suppliers) { supplier in
                            if let id = supplier.id {
                                Text(supplier.name ?? "Unnamed").tag(UUID?.some(id))
                            }
                        }
                    }
                    
                    if suppliers.isEmpty {
                        Text("No suppliers found. Add suppliers in Settings.")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Section("Delivery") {
                    DatePicker("Expected Delivery", selection: $expectedDeliveryDate, displayedComponents: .date)
                }
                
                Section {
                    ForEach($lineItems) { $item in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Picker("Item", selection: $item.inventoryItemId) {
                                    Text("Select item").tag(UUID?.none)
                                    ForEach(inventoryItems) { invItem in
                                        if let id = invItem.id {
                                            Text(invItem.name ?? "Unnamed").tag(UUID?.some(id))
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                
                                Button(role: .destructive) {
                                    lineItems.removeAll { $0.id == item.id }
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.borderless)
                            }
                            
                            HStack {
                                Stepper("Qty: \(item.quantity)", value: $item.quantity, in: 1...10000)
                                    .frame(width: 140)
                                
                                Spacer()
                                
                                HStack(spacing: 4) {
                                    Text("$")
                                    TextField("Cost", value: $item.unitCost, format: .number)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 80)
                                        .multilineTextAlignment(.trailing)
                                }
                            }
                            
                            HStack {
                                Text("Line Total:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(formatCurrency(item.lineTotal))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    Button {
                        addLineItem()
                    } label: {
                        Label("Add Line Item", systemImage: "plus.circle")
                    }
                } header: {
                    HStack {
                        Text("Line Items")
                        Spacer()
                        if !lineItems.isEmpty {
                            Text("\(lineItems.count) item(s)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Costs") {
                    HStack {
                        Text("Subtotal")
                        Spacer()
                        Text(formatCurrency(subtotal))
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Shipping")
                        Spacer()
                        HStack(spacing: 4) {
                            Text("$")
                            TextField("0.00", value: $shippingCost, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    HStack {
                        Text("Tax Rate")
                        Spacer()
                        HStack(spacing: 4) {
                            TextField("0.0", value: $taxRate, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 60)
                                .multilineTextAlignment(.trailing)
                            Text("%")
                        }
                    }
                    
                    HStack {
                        Text("Tax")
                        Spacer()
                        Text(formatCurrency(taxAmount))
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Total")
                            .fontWeight(.bold)
                        Spacer()
                        Text(formatCurrency(total))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 60)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("New Purchase Order")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createPurchaseOrder()
                    }
                    .disabled(!isValid)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
        .frame(width: 800, height: 700)
        .onAppear {
            if lineItems.isEmpty {
                addLineItem()
            }
        }
    }
    
    private var subtotal: Double {
        lineItems.reduce(0) { $0 + $1.lineTotal }
    }
    
    private var taxAmount: Double {
        subtotal * (taxRate / 100.0)
    }
    
    private var total: Double {
        subtotal + taxAmount + shippingCost
    }
    
    private var isValid: Bool {
        selectedSupplierId != nil && 
        !lineItems.isEmpty && 
        lineItems.allSatisfy { $0.inventoryItemId != nil && $0.quantity > 0 && $0.unitCost > 0 }
    }
    
    private func addLineItem() {
        lineItems.append(POLineItem(quantity: 1, unitCost: 0))
    }
    
    private func createPurchaseOrder() {
        guard let supplierId = selectedSupplierId else { return }
        guard let supplier = suppliers.first(where: { $0.id == supplierId }) else { return }
        
        do {
            let po = PurchaseOrder(context: viewContext)
            po.id = UUID()
            po.orderNumber = generateOrderNumber()
            po.orderDate = Date()
            po.expectedDeliveryDate = expectedDeliveryDate
            po.status = "draft"
            po.supplierId = supplierId
            po.supplierName = supplier.name
            po.subtotal = subtotal
            po.tax = taxAmount
            po.shipping = shippingCost
            po.total = total
            po.notes = notes.isEmpty ? nil : notes
            po.createdAt = Date()
            po.updatedAt = Date()
            
            // Encode line items as JSON
            let encoder = JSONEncoder()
            let lineItemsData = try encoder.encode(lineItems)
            po.lineItemsJSON = String(data: lineItemsData, encoding: .utf8)
            
            try viewContext.save()
            dismiss()
        } catch {
            errorMessage = "Failed to create purchase order: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func generateOrderNumber() -> String {
        let request = PurchaseOrder.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PurchaseOrder.createdAt, ascending: false)]
        request.fetchLimit = 1
        
        if let lastPO = try? viewContext.fetch(request).first,
           let lastNumber = lastPO.orderNumber,
           let number = Int(lastNumber.replacingOccurrences(of: "PO-", with: "")) {
            return String(format: "PO-%04d", number + 1)
        }
        
        return "PO-0001"
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

// MARK: - Purchase Order Detail View

struct PurchaseOrderDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var order: PurchaseOrder
    
    @State private var showingReceiveSheet = false
    @State private var showingCancelConfirm = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var lineItems: [POLineItem] = []
    
    var statusColor: Color {
        switch order.status {
        case "draft": return .gray
        case "ordered": return .blue
        case "received": return .green
        case "cancelled": return .red
        default: return .gray
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with status
                    VStack(spacing: 8) {
                        HStack {
                            Text("PO #\(order.orderNumber ?? "N/A")")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Text(order.status?.uppercased() ?? "DRAFT")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(statusColor)
                                .cornerRadius(6)
                        }
                        
                        HStack {
                            Text("Order Date: \(order.orderDate?.formatted(date: .long, time: .omitted) ?? "N/A")")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    
                    // Supplier Info
                    GroupBox(label: Label("Supplier", systemImage: "building.2")) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(order.supplierName ?? "Unknown Supplier")
                                .font(.headline)
                            
                            if let supplier = fetchSupplier() {
                                if let contact = supplier.contactPerson {
                                    HStack {
                                        Image(systemName: "person")
                                        Text(contact)
                                    }
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                }
                                
                                if let email = supplier.email {
                                    HStack {
                                        Image(systemName: "envelope")
                                        Text(email)
                                    }
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                    }
                    
                    // Delivery Info
                    GroupBox(label: Label("Delivery", systemImage: "shippingbox")) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Expected:")
                                Spacer()
                                Text(order.expectedDeliveryDate?.formatted(date: .long, time: .omitted) ?? "Not set")
                                    .fontWeight(.medium)
                            }
                            
                            if let actualDate = order.actualDeliveryDate {
                                HStack {
                                    Text("Actual:")
                                    Spacer()
                                    Text(actualDate.formatted(date: .long, time: .omitted))
                                        .fontWeight(.medium)
                                        .foregroundColor(.green)
                                }
                            }
                            
                            if let tracking = order.trackingNumber, !tracking.isEmpty {
                                HStack {
                                    Text("Tracking:")
                                    Spacer()
                                    Text(tracking)
                                        .fontWeight(.medium)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .padding(8)
                    }
                    
                    // Line Items
                    GroupBox(label: Label("Items", systemImage: "list.bullet")) {
                        VStack(spacing: 12) {
                            ForEach(lineItems) { item in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        if let invItem = fetchInventoryItem(id: item.inventoryItemId) {
                                            Text(invItem.name ?? "Unknown Item")
                                                .fontWeight(.medium)
                                            if let partNum = invItem.partNumber {
                                                Text("Part #: \(partNum)")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        } else {
                                            Text("Unknown Item")
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("Qty: \(item.quantity)")
                                            .font(.caption)
                                        Text(formatCurrency(item.unitCost))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Text(formatCurrency(item.lineTotal))
                                        .fontWeight(.semibold)
                                        .frame(width: 80, alignment: .trailing)
                                }
                                .padding(.vertical, 4)
                                
                                if item.id != lineItems.last?.id {
                                    Divider()
                                }
                            }
                        }
                        .padding(8)
                    }
                    
                    // Totals
                    GroupBox(label: Label("Total", systemImage: "dollarsign.circle")) {
                        VStack(spacing: 8) {
                            HStack {
                                Text("Subtotal")
                                Spacer()
                                Text(formatCurrency(order.subtotal))
                            }
                            
                            HStack {
                                Text("Shipping")
                                Spacer()
                                Text(formatCurrency(order.shipping))
                            }
                            
                            HStack {
                                Text("Tax")
                                Spacer()
                                Text(formatCurrency(order.tax))
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Total")
                                    .fontWeight(.bold)
                                Spacer()
                                Text(formatCurrency(order.total))
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(8)
                    }
                    
                    // Notes
                    if let notes = order.notes, !notes.isEmpty {
                        GroupBox(label: Label("Notes", systemImage: "note.text")) {
                            Text(notes)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Purchase Order")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        if order.status == "draft" {
                            Button {
                                markAsOrdered()
                            } label: {
                                Label("Mark as Ordered", systemImage: "checkmark.circle")
                            }
                        }
                        
                        if order.status == "ordered" {
                            Button {
                                showingReceiveSheet = true
                            } label: {
                                Label("Mark as Received", systemImage: "shippingbox.fill")
                            }
                        }
                        
                        Divider()
                        
                        if order.status != "cancelled" && order.status != "received" {
                            Button(role: .destructive) {
                                showingCancelConfirm = true
                            } label: {
                                Label("Cancel Order", systemImage: "xmark.circle")
                            }
                        }
                    } label: {
                        Label("Actions", systemImage: "ellipsis.circle")
                    }
                }
            }
        }
        .frame(width: 800, height: 700)
        .sheet(isPresented: $showingReceiveSheet) {
            ReceivePurchaseOrderSheet(order: order, lineItems: lineItems)
        }
        .alert("Cancel Order", isPresented: $showingCancelConfirm) {
            Button("Cancel Order", role: .destructive) {
                cancelOrder()
            }
            Button("Keep Order", role: .cancel) {}
        } message: {
            Text("Are you sure you want to cancel this purchase order? This action cannot be undone.")
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            loadLineItems()
        }
    }
    
    private func loadLineItems() {
        guard let jsonString = order.lineItemsJSON,
              let jsonData = jsonString.data(using: .utf8) else {
            return
        }
        
        let decoder = JSONDecoder()
        if let items = try? decoder.decode([POLineItem].self, from: jsonData) {
            lineItems = items
        }
    }
    
    private func fetchSupplier() -> Supplier? {
        guard let supplierId = order.supplierId else { return nil }
        let request = Supplier.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", supplierId as CVarArg)
        request.fetchLimit = 1
        return try? viewContext.fetch(request).first
    }
    
    private func fetchInventoryItem(id: UUID?) -> InventoryItem? {
        guard let id = id else { return nil }
        let request = InventoryItem.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try? viewContext.fetch(request).first
    }
    
    private func markAsOrdered() {
        order.status = "ordered"
        order.updatedAt = Date()
        try? viewContext.save()
    }
    
    private func cancelOrder() {
        order.status = "cancelled"
        order.updatedAt = Date()
        try? viewContext.save()
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

// MARK: - Receive Purchase Order Sheet

struct ReceivePurchaseOrderSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var order: PurchaseOrder
    let lineItems: [POLineItem]
    
    @State private var actualDeliveryDate = Date()
    @State private var trackingNumber = ""
    @State private var notes = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Delivery Information") {
                    DatePicker("Received Date", selection: $actualDeliveryDate, displayedComponents: .date)
                    TextField("Tracking Number (Optional)", text: $trackingNumber)
                }
                
                Section("Items to Receive") {
                    ForEach(lineItems) { item in
                        HStack {
                            if let invItem = fetchInventoryItem(id: item.inventoryItemId) {
                                VStack(alignment: .leading) {
                                    Text(invItem.name ?? "Unknown")
                                        .fontWeight(.medium)
                                    Text("Qty: \(item.quantity)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 60)
                }
                
                Section {
                    Text("This will mark the order as received and update inventory quantities.")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Receive Purchase Order")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Receive Items") {
                        receiveOrder()
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
        .frame(width: 600, height: 500)
    }
    
    private func receiveOrder() {
        do {
            // Update order status
            order.status = "received"
            order.actualDeliveryDate = actualDeliveryDate
            order.trackingNumber = trackingNumber.isEmpty ? nil : trackingNumber
            if !notes.isEmpty {
                order.notes = (order.notes ?? "") + "\n\nReceiving Notes: \(notes)"
            }
            order.updatedAt = Date()
            
            // Update inventory for each line item
            for item in lineItems {
                if let invItem = fetchInventoryItem(id: item.inventoryItemId) {
                    let oldQuantity = Int(invItem.quantity)
                    invItem.quantity = Int32(oldQuantity + item.quantity)
                    invItem.updatedAt = Date()
                    
                    // Create stock adjustment record
                    let adjustment = StockAdjustment(context: viewContext)
                    adjustment.id = UUID()
                    adjustment.itemId = invItem.id
                    adjustment.itemName = invItem.name
                    adjustment.type = "add"
                    adjustment.quantityBefore = Int32(oldQuantity)
                    adjustment.quantityChange = Int32(item.quantity)
                    adjustment.quantityAfter = invItem.quantity
                    adjustment.reason = "Purchase Order Received"
                    adjustment.reference = "PO #\(order.orderNumber ?? "")"
                    adjustment.notes = "Received from \(order.supplierName ?? "supplier")"
                    adjustment.performedBy = "System"
                    adjustment.createdAt = Date()
                }
            }
            
            try viewContext.save()
            dismiss()
        } catch {
            errorMessage = "Failed to receive order: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func fetchInventoryItem(id: UUID?) -> InventoryItem? {
        guard let id = id else { return nil }
        let request = InventoryItem.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try? viewContext.fetch(request).first
    }
}

// MARK: - Purchase Order Line Item Model

struct POLineItem: Identifiable, Codable {
    var id = UUID()
    var inventoryItemId: UUID?
    var quantity: Int
    var unitCost: Double
    
    var lineTotal: Double {
        Double(quantity) * unitCost
    }
}
