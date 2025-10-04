import SwiftUI

struct InvoiceGeneratorView: View {
    @Environment(\.dismiss) var dismiss
    
    let invoice: Invoice?
    
    @State private var selectedCustomer: Customer?
    @State private var selectedTicket: Ticket?
    @State private var lineItems: [LineItemData] = []
    @State private var taxRate: String = "0"
    @State private var notes: String = ""
    @State private var terms: String = "Payment is due within 30 days of invoice date."
    @State private var dueDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    
    @State private var showingCustomerPicker = false
    @State private var showingTicketPicker = false
    @State private var showingSaveAlert = false
    @State private var savedInvoice: Invoice?
    
    private let invoiceService = InvoiceService.shared
    private let coreDataManager = CoreDataManager.shared
    
    var isEditing: Bool {
        invoice != nil
    }
    
    var subtotal: Decimal {
        lineItems.reduce(Decimal(0)) { $0 + $1.total }
    }
    
    var taxAmount: Decimal {
        let rate = Decimal(string: taxRate) ?? 0
        return subtotal * rate / 100
    }
    
    var total: Decimal {
        subtotal + taxAmount
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Customer Selection
                    customerSection
                    
                    Divider()
                    
                    // Ticket Selection (Optional)
                    ticketSection
                    
                    Divider()
                    
                    // Line Items
                    lineItemsSection
                    
                    Divider()
                    
                    // Totals
                    totalsSection
                    
                    Divider()
                    
                    // Notes and Terms
                    notesSection
                    
                    Divider()
                    
                    // Due Date
                    dueDateSection
                }
                .padding()
            }
            .navigationTitle(isEditing ? "Edit Invoice" : "New Invoice")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveInvoice()
                    }
                    .disabled(selectedCustomer == nil || lineItems.isEmpty)
                }
            }
        }
        .frame(width: 900, height: 700)
        .onAppear {
            loadInvoiceData()
        }
        .alert("Invoice Saved", isPresented: $showingSaveAlert) {
            Button("View Invoice") {
                // TODO: Navigate to invoice detail
                dismiss()
            }
            Button("Create Another") {
                resetForm()
            }
            Button("Close") {
                dismiss()
            }
        } message: {
            Text("Invoice has been saved successfully.")
        }
        .sheet(isPresented: $showingCustomerPicker) {
            CustomerPickerView(selectedCustomer: $selectedCustomer)
        }
        .sheet(isPresented: $showingTicketPicker) {
            TicketPickerView(customerId: selectedCustomer?.id, selectedTicket: $selectedTicket)
        }
    }
    
    // MARK: - Customer Section
    
    private var customerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Customer")
                .font(.headline)
            
            if let customer = selectedCustomer {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(customer.firstName ?? "") \(customer.lastName ?? "")")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        if let email = customer.email {
                            Text(email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if let phone = customer.phone {
                            Text(phone)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button("Change") {
                        showingCustomerPicker = true
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            } else {
                Button(action: { showingCustomerPicker = true }) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("Select Customer")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Ticket Section
    
    private var ticketSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ticket (Optional)")
                .font(.headline)
            
            if let ticket = selectedTicket {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ticket #\(ticket.ticketNumber)")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        if let device = ticket.deviceType {
                            Text("\(device) - \(ticket.deviceModel ?? "")")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if let issue = ticket.issueDescription {
                            Text(issue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                    
                    Spacer()
                    
                    Button("Change") {
                        showingTicketPicker = true
                    }
                    
                    Button("Remove") {
                        selectedTicket = nil
                    }
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            } else {
                Button(action: { showingTicketPicker = true }) {
                    HStack {
                        Image(systemName: "ticket")
                        Text("Link to Ticket")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(selectedCustomer == nil)
            }
        }
    }
    
    // MARK: - Line Items Section
    
    private var lineItemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Line Items")
                    .font(.headline)
                
                Spacer()
                
                Button(action: addLineItem) {
                    Label("Add Item", systemImage: "plus.circle.fill")
                }
            }
            
            if lineItems.isEmpty {
                Text("No items added yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            } else {
                VStack(spacing: 8) {
                    ForEach(lineItems.indices, id: \.self) { index in
                        LineItemRow(
                            item: lineItems[index],
                            onDelete: { deleteLineItem(at: index) },
                            onUpdate: { updated in
                                lineItems[index] = updated
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Totals Section
    
    private var totalsSection: some View {
        VStack(alignment: .trailing, spacing: 12) {
            HStack {
                Text("Subtotal:")
                    .font(.headline)
                Spacer()
                Text(formatCurrency(subtotal))
                    .font(.headline)
            }
            
            HStack {
                Text("Tax Rate:")
                TextField("0", text: $taxRate)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                    .multilineTextAlignment(.trailing)
                Text("%")
                
                Spacer()
                
                Text(formatCurrency(taxAmount))
            }
            
            Divider()
            
            HStack {
                Text("Total:")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Text(formatCurrency(total))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    // MARK: - Notes Section
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.headline)
            
            TextEditor(text: $notes)
                .frame(height: 80)
                .padding(4)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            
            Text("Terms & Conditions")
                .font(.headline)
            
            TextEditor(text: $terms)
                .frame(height: 80)
                .padding(4)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
        }
    }
    
    // MARK: - Due Date Section
    
    private var dueDateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Due Date")
                .font(.headline)
            
            DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                .datePickerStyle(.field)
        }
    }
    
    // MARK: - Actions
    
    private func loadInvoiceData() {
        if let invoice = invoice {
            // Load existing invoice data
            selectedCustomer = coreDataManager.fetchCustomer(id: invoice.customerId ?? UUID())
            taxRate = String(describing: invoice.taxRate)
            notes = invoice.notes ?? ""
            terms = invoice.terms ?? ""
            dueDate = invoice.dueDate ?? Date()
            
            // Load line items
            lineItems = invoice.lineItemsArray.map { item in
                LineItemData(
                    id: item.id ?? UUID(),
                    description: item.itemDescription ?? "",
                    quantity: item.quantity,
                    unitPrice: item.unitPrice,
                    total: item.total,
                    itemType: item.itemType ?? "service"
                )
            }
        } else {
            // Add default line item for new invoice
            addLineItem()
        }
    }
    
    private func addLineItem() {
        lineItems.append(
            LineItemData(
                description: "",
                quantity: Decimal(1),
                unitPrice: Decimal.zero,
                total: Decimal.zero,
                itemType: "service"
            )
        )
    }
    
    private func deleteLineItem(at index: Int) {
        lineItems.remove(at: index)
    }
    
    private func saveInvoice() {
        guard let customer = selectedCustomer else { return }
        
        let newInvoice: Invoice
        
        if let existingInvoice = invoice {
            // Update existing invoice
            newInvoice = existingInvoice
            
            // Remove old line items
            if let oldItems = existingInvoice.lineItems as? Set<InvoiceLineItem> {
                for item in oldItems {
                    invoiceService.deleteLineItem(item)
                }
            }
        } else {
            // Create new invoice
            newInvoice = invoiceService.createInvoice(
                customerId: customer.id ?? UUID(),
                ticketId: selectedTicket?.id,
                dueDate: dueDate,
                notes: notes.isEmpty ? nil : notes,
                terms: terms.isEmpty ? nil : terms
            )
        }
        
        // Add line items
        for (index, itemData) in lineItems.enumerated() {
            let lineItem = invoiceService.addLineItem(
                to: newInvoice,
                type: itemData.itemType,
                description: itemData.description,
                quantity: itemData.quantity,
                unitPrice: itemData.unitPrice
            )
            lineItem.order = Int16(index)
        }
        
        // Update tax rate
        let rate = Decimal(string: taxRate) ?? 0
        invoiceService.updateTaxRate(newInvoice, taxRate: rate)
        
        savedInvoice = newInvoice
        showingSaveAlert = true
    }
    
    private func resetForm() {
        selectedCustomer = nil
        selectedTicket = nil
        lineItems = []
        taxRate = "0"
        notes = ""
        terms = "Payment is due within 30 days of invoice date."
        dueDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        addLineItem()
    }
    
    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: value as NSDecimalNumber) ?? "$0.00"
    }
}

// MARK: - Line Item Row

struct LineItemRow: View {
    let item: LineItemData
    let onDelete: () -> Void
    let onUpdate: (LineItemData) -> Void
    
    @State private var itemType: String
    @State private var itemDescription: String
    @State private var itemQuantity: String
    @State private var itemUnitPrice: String
    
    init(item: LineItemData, onDelete: @escaping () -> Void, onUpdate: @escaping (LineItemData) -> Void) {
        self.item = item
        self.onDelete = onDelete
        self.onUpdate = onUpdate
        _itemType = State(initialValue: item.itemType)
        _itemDescription = State(initialValue: item.description)
        _itemQuantity = State(initialValue: NSDecimalNumber(decimal: item.quantity).stringValue)
        _itemUnitPrice = State(initialValue: NSDecimalNumber(decimal: item.unitPrice).stringValue)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Type picker
            Picker("", selection: $itemType) {
                Text("Service").tag("service")
                Text("Labor").tag("labor")
                Text("Part").tag("part")
                Text("Other").tag("other")
            }
            .pickerStyle(.menu)
            .frame(width: 100)
            
            // Description
            TextField("Description", text: $itemDescription)
                .textFieldStyle(.roundedBorder)
                .onChange(of: itemDescription) { _, newValue in
                    updateItem()
                }
            
            // Quantity
            TextField("Qty", text: $itemQuantity)
                .textFieldStyle(.roundedBorder)
                .frame(width: 60)
                .multilineTextAlignment(.trailing)
                .onChange(of: itemQuantity) { _, _ in
                    updateItem()
                }
            
            // Unit Price
            TextField("Price", text: $itemUnitPrice)
                .textFieldStyle(.roundedBorder)
                .frame(width: 100)
                .multilineTextAlignment(.trailing)
                .onChange(of: itemUnitPrice) { _, _ in
                    updateItem()
                }
            
            // Total
            Text(formatCurrency(calculateTotal()))
                .frame(width: 100, alignment: .trailing)
                .fontWeight(.semibold)
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(6)
        .onChange(of: itemType) { _, _ in
            updateItem()
        }
    }
    
    private func calculateTotal() -> Decimal {
        let qty = Decimal(string: itemQuantity) ?? 0
        let price = Decimal(string: itemUnitPrice) ?? 0
        return qty * price
    }
    
    private func updateItem() {
        let qty = Decimal(string: itemQuantity) ?? 0
        let price = Decimal(string: itemUnitPrice) ?? 0
        let total = qty * price

        let updated = LineItemData(
            id: item.id,
            description: itemDescription,
            quantity: qty,
            unitPrice: price,
            total: total,
            itemType: itemType
        )
        onUpdate(updated)
    }
    
    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: value as NSDecimalNumber) ?? "$0.00"
    }
}

// MARK: - Customer Picker View

struct CustomerPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedCustomer: Customer?
    
    @State private var customers: [Customer] = []
    @State private var searchText = ""
    
    private let coreDataManager = CoreDataManager.shared
    
    var filteredCustomers: [Customer] {
        if searchText.isEmpty {
            return customers
        }
        return customers.filter { customer in
            let name = "\(customer.firstName ?? "") \(customer.lastName ?? "")"
            return name.localizedCaseInsensitiveContains(searchText) ||
                   customer.email?.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Search customers...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding()
                
                Divider()
                
                // Walk-in option
                Button(action: {
                    selectedCustomer = nil
                    dismiss()
                }) {
                    HStack {
                        Circle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "person.fill.questionmark")
                                    .foregroundColor(.gray)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Walk-in Customer")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("No customer selected")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if selectedCustomer == nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    .padding()
                    .background(selectedCustomer == nil ? Color.green.opacity(0.1) : Color.clear)
                }
                .buttonStyle(.plain)
                
                Divider()
                
                // Customer list
                List(filteredCustomers) { customer in
                    Button(action: {
                        selectedCustomer = customer
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(customer.firstName ?? "") \(customer.lastName ?? "")")
                                    .font(.headline)
                                
                                if let email = customer.email {
                                    Text(email)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if selectedCustomer?.id == customer.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Customer")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 600, height: 500)
        .onAppear {
            customers = coreDataManager.fetchCustomers()
        }
    }
}

// MARK: - Ticket Picker View

struct TicketPickerView: View {
    @Environment(\.dismiss) var dismiss
    let customerId: UUID?
    @Binding var selectedTicket: Ticket?
    
    @State private var tickets: [Ticket] = []
    
    private let coreDataManager = CoreDataManager.shared
    
    var body: some View {
        NavigationStack {
            List(tickets) { ticket in
                Button(action: {
                    selectedTicket = ticket
                    dismiss()
                }) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ticket #\(ticket.ticketNumber)")
                            .font(.headline)
                        
                        if let device = ticket.deviceType {
                            Text("\(device) - \(ticket.deviceModel ?? "")")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if let status = ticket.status {
                            Text("Status: \(status)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Select Ticket")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 600, height: 500)
        .onAppear {
            loadTickets()
        }
    }
    
    private func loadTickets() {
        guard let customerId = customerId else { return }
        
        let request = Ticket.fetchRequest()
        request.predicate = NSPredicate(format: "customerId == %@", customerId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Ticket.createdAt, ascending: false)]
        
        tickets = (try? coreDataManager.viewContext.fetch(request)) ?? []
    }
}

// MARK: - Preview

struct InvoiceGeneratorView_Previews: PreviewProvider {
    static var previews: some View {
        InvoiceGeneratorView(invoice: nil)
    }
}
