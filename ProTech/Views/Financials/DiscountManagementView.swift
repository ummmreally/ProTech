//
//  DiscountManagementView.swift
//  ProTech
//
//  Manage discount codes and rules.
//

import SwiftUI
import CoreData

struct DiscountManagementView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DiscountRule.name, ascending: true)],
        animation: .default
    ) private var discounts: FetchedResults<DiscountRule>
    
    @State private var showingAddSheet = false
    @State private var newName = ""
    @State private var newCode = ""
    @State private var newType = "percentage"
    @State private var newValue = ""
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(discounts) { discount in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(discount.name ?? "Unknown")
                                .font(.headline)
                            Text(discount.code ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .monospaced()
                                .padding(2)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                        
                        Text(discount.formattedValue)
                            .bold()
                            .foregroundColor(discount.activeColor)
                        
                        Toggle("", isOn: Binding(
                            get: { discount.isActive },
                            set: { newValue in
                                discount.isActive = newValue
                                try? viewContext.save()
                            }
                        ))
                        .labelsHidden()
                    }
                }
                .onDelete(perform: deleteDiscounts)
            }
            .navigationTitle("Discounts & Pricing")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddSheet = true }) {
                        Label("Add Discount", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                NavigationStack {
                    Form {
                        Section("Rule Details") {
                            TextField("Name (e.g. Summer Sale)", text: $newName)
                            TextField("Code (e.g. SAVE20)", text: $newCode)
                                #if os(iOS)
                                .textInputAutocapitalization(.characters)
                                #endif
                        }
                        
                        Section("Value") {
                            Picker("Type", selection: $newType) {
                                Text("Percentage (%)").tag("percentage")
                                Text("Fixed Amount ($)").tag("fixed")
                            }
                            .pickerStyle(.segmented)
                            
                            TextField("Amount", text: $newValue)
                                #if os(iOS)
                                .keyboardType(.decimalPad)
                                #endif
                        }
                    }
                    .navigationTitle("New Discount")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showingAddSheet = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                addDiscount()
                                showingAddSheet = false
                            }
                            .disabled(newName.isEmpty || newValue.isEmpty)
                        }
                    }
                }
            }
        }
    }
    
    private func addDiscount() {
        let discount = DiscountRule(context: viewContext)
        discount.id = UUID()
        discount.name = newName
        discount.code = newCode.uppercased()
        discount.type = newType
        discount.value = NSDecimalNumber(string: newValue)
        discount.isActive = true
        discount.createdAt = Date()
        
        try? viewContext.save()
        
        newName = ""
        newCode = ""
        newValue = ""
    }
    
    private func deleteDiscounts(offsets: IndexSet) {
        withAnimation {
            offsets.map { discounts[$0] }.forEach(viewContext.delete)
            try? viewContext.save()
        }
    }
}

extension DiscountRule {
    var activeColor: Color {
        isActive ? .green : .gray
    }
}
