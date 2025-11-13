//
//  DiscountCodeManagerView.swift
//  ProTech
//
//  Manage promotional discount codes
//

import SwiftUI

struct DiscountCodeManagerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DiscountCode.createdAt, ascending: false)],
        animation: .default
    ) private var discountCodes: FetchedResults<DiscountCode>
    
    @State private var searchText = ""
    @State private var filterStatus: DiscountCodeFilter = .all
    @State private var showingEditor = false
    @State private var editingCode: DiscountCode?
    @State private var showDeleteAlert = false
    @State private var codeToDelete: DiscountCode?
    
    enum DiscountCodeFilter: String, CaseIterable {
        case all = "All"
        case active = "Active"
        case expired = "Expired"
        case inactive = "Inactive"
    }
    
    var filteredCodes: [DiscountCode] {
        var filtered = Array(discountCodes)
        
        // Search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { code in
                (code.code?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (code.description_?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Status filter
        switch filterStatus {
        case .all:
            break
        case .active:
            filtered = filtered.filter { $0.isValid }
        case .expired:
            let now = Date()
            filtered = filtered.filter { code in
                if let endDate = code.endDate {
                    return now > endDate
                }
                return false
            }
        case .inactive:
            filtered = filtered.filter { !$0.isActive }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search and filters
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search discount codes...", text: $searchText)
                            .textFieldStyle(.plain)
                    }
                    .padding(10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    
                    Picker("Filter", selection: $filterStatus) {
                        ForEach(DiscountCodeFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding()
                
                Divider()
                
                // Discount codes list
                if filteredCodes.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredCodes) { code in
                                DiscountCodeRow(code: code) {
                                    editingCode = code
                                    showingEditor = true
                                } onToggleActive: {
                                    toggleActive(code)
                                } onDelete: {
                                    codeToDelete = code
                                    showDeleteAlert = true
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Discount Codes")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .automatic) {
                    Button {
                        createNewCode()
                    } label: {
                        Label("New Code", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                if let code = editingCode {
                    DiscountCodeEditorView(discountCode: code)
                }
            }
            .alert("Delete Discount Code", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let code = codeToDelete {
                        deleteCode(code)
                    }
                }
            } message: {
                Text("Are you sure you want to delete '\(codeToDelete?.code ?? "this code")'? This action cannot be undone.")
            }
        }
        .frame(width: 900, height: 700)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tag")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(searchText.isEmpty ? "No Discount Codes" : "No Matching Codes")
                .font(.title2)
                .bold()
            
            Text(searchText.isEmpty ? "Create promotional discount codes for your customers" : "Try a different search term")
                .foregroundColor(.secondary)
            
            if searchText.isEmpty {
                Button {
                    createNewCode()
                } label: {
                    Label("Create Discount Code", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxHeight: .infinity)
    }
    
    private func createNewCode() {
        let code = DiscountCode(context: viewContext)
        code.id = UUID()
        code.code = ""
        code.type = DiscountType.percentage.rawValue
        code.value = 10
        code.usageLimit = 0
        code.usageCount = 0
        code.isActive = true
        code.createdAt = Date()
        code.updatedAt = Date()
        
        try? viewContext.save()
        editingCode = code
        showingEditor = true
    }
    
    private func toggleActive(_ code: DiscountCode) {
        if code.isActive {
            DiscountCodeService.shared.deactivateDiscountCode(code)
        } else {
            DiscountCodeService.shared.activateDiscountCode(code)
        }
    }
    
    private func deleteCode(_ code: DiscountCode) {
        DiscountCodeService.shared.deleteDiscountCode(code)
    }
}

// MARK: - Discount Code Row

struct DiscountCodeRow: View {
    @ObservedObject var code: DiscountCode
    let onEdit: () -> Void
    let onToggleActive: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(statusColor.opacity(0.1))
                    .frame(width: 50, height: 50)
                Image(systemName: code.discountType == .percentage ? "percent" : "dollarsign.circle")
                    .foregroundColor(statusColor)
                    .font(.title3)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(code.code ?? "N/A")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(code.formattedValue)
                        .font(.subheadline)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                    
                    Text(code.statusText)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(statusColor.opacity(0.2))
                        .foregroundColor(statusColor)
                        .cornerRadius(4)
                }
                
                if let description = code.description_, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack(spacing: 12) {
                    if code.usageLimit > 0 {
                        Label("\(code.usageCount)/\(code.usageLimit) uses", systemImage: "number")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Label("\(code.usageCount) uses", systemImage: "number")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let endDate = code.endDate {
                        Label(endDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if code.minimumPurchaseAmount > 0 {
                        Label("Min: \(formattedMinimumPurchase(code))", systemImage: "cart")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 8) {
                Button {
                    onToggleActive()
                } label: {
                    Image(systemName: code.isActive ? "pause.circle" : "play.circle")
                        .font(.title3)
                        .foregroundColor(code.isActive ? .orange : .green)
                }
                .buttonStyle(.borderless)
                .help(code.isActive ? "Deactivate" : "Activate")
                
                Button {
                    onEdit()
                } label: {
                    Image(systemName: "pencil.circle")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.borderless)
                
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.title3)
                        .foregroundColor(.red)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var statusColor: Color {
        switch code.statusText {
        case "Active": return .green
        case "Inactive": return .gray
        case "Expired", "Limit Reached", "Invalid": return .red
        default: return .gray
        }
    }
    
    private func formattedMinimumPurchase(_ code: DiscountCode) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: code.minimumPurchase ?? 0) ?? "$0"
    }
}

// MARK: - Discount Code Editor View

struct DiscountCodeEditorView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var discountCode: DiscountCode
    
    @State private var code: String
    @State private var type: DiscountType
    @State private var value: String
    @State private var description: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var hasEndDate: Bool
    @State private var usageLimit: String
    @State private var hasUsageLimit: Bool
    @State private var minimumPurchase: String
    @State private var hasMinimumPurchase: Bool
    @State private var maximumDiscount: String
    @State private var hasMaximumDiscount: Bool
    
    init(discountCode: DiscountCode) {
        self.discountCode = discountCode
        _code = State(initialValue: discountCode.code ?? "")
        _type = State(initialValue: discountCode.discountType)
        _value = State(initialValue: String(describing: discountCode.discountValue))
        _description = State(initialValue: discountCode.description_ ?? "")
        _startDate = State(initialValue: discountCode.startDate ?? Date())
        _endDate = State(initialValue: discountCode.endDate ?? Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date())
        _hasEndDate = State(initialValue: discountCode.endDate != nil)
        _usageLimit = State(initialValue: String(discountCode.usageLimit))
        _hasUsageLimit = State(initialValue: discountCode.usageLimit > 0)
        _minimumPurchase = State(initialValue: String(describing: discountCode.minimumPurchaseAmount))
        _hasMinimumPurchase = State(initialValue: discountCode.minimumPurchaseAmount > 0)
        _maximumDiscount = State(initialValue: discountCode.maximumDiscountAmount != nil ? String(describing: discountCode.maximumDiscountAmount!) : "")
        _hasMaximumDiscount = State(initialValue: discountCode.maximumDiscountAmount != nil)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Discount Code Details") {
                    TextField("Code (e.g., SAVE20)", text: $code)
                        .textFieldStyle(.roundedBorder)
                    
                    Picker("Type", selection: $type) {
                        ForEach(DiscountType.allCases, id: \.self) { discountType in
                            Text(discountType.displayName).tag(discountType)
                        }
                    }
                    
                    HStack {
                        TextField(type == .percentage ? "Percentage" : "Amount", text: $value)
                            .textFieldStyle(.roundedBorder)
                        if type == .percentage {
                            Text("%")
                                .foregroundColor(.secondary)
                        } else {
                            Text("$")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    TextField("Description (optional)", text: $description)
                        .textFieldStyle(.roundedBorder)
                }
                
                Section("Validity Period") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: [.date])
                    
                    Toggle("Set End Date", isOn: $hasEndDate)
                    
                    if hasEndDate {
                        DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: [.date])
                    }
                }
                
                Section("Usage Restrictions") {
                    Toggle("Set Usage Limit", isOn: $hasUsageLimit)
                    
                    if hasUsageLimit {
                        TextField("Maximum Uses", text: $usageLimit)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    Toggle("Set Minimum Purchase", isOn: $hasMinimumPurchase)
                    
                    if hasMinimumPurchase {
                        HStack {
                            Text("$")
                                .foregroundColor(.secondary)
                            TextField("Minimum Amount", text: $minimumPurchase)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    
                    if type == .percentage {
                        Toggle("Set Maximum Discount Cap", isOn: $hasMaximumDiscount)
                        
                        if hasMaximumDiscount {
                            HStack {
                                Text("$")
                                    .foregroundColor(.secondary)
                                TextField("Maximum Discount", text: $maximumDiscount)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                    }
                }
                
                Section("Statistics") {
                    LabeledContent("Times Used") {
                        Text("\(discountCode.usageCount)")
                            .bold()
                    }
                    
                    LabeledContent("Status") {
                        Text(discountCode.statusText)
                            .foregroundColor(statusColor)
                            .bold()
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Edit Discount Code")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveCode()
                    }
                    .disabled(code.isEmpty || value.isEmpty)
                }
            }
        }
        .frame(width: 600, height: 700)
    }
    
    private var statusColor: Color {
        switch discountCode.statusText {
        case "Active": return .green
        case "Inactive": return .gray
        case "Expired", "Limit Reached", "Invalid": return .red
        default: return .gray
        }
    }
    
    private func saveCode() {
        guard let valueDecimal = Decimal(string: value) else { return }
        
        DiscountCodeService.shared.updateDiscountCode(
            discountCode,
            code: code,
            type: type,
            value: valueDecimal,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            usageLimit: hasUsageLimit ? Int(usageLimit) ?? 0 : 0,
            minimumPurchase: hasMinimumPurchase ? Decimal(string: minimumPurchase) : nil,
            maximumDiscount: hasMaximumDiscount ? Decimal(string: maximumDiscount) : nil,
            description: description.isEmpty ? nil : description
        )
        
        dismiss()
    }
}
