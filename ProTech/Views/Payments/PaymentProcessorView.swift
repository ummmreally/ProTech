//
//  PaymentProcessorView.swift
//  ProTech
//
//  Credit card payment processing interface
//

import SwiftUI

struct PaymentProcessorView: View {
    @Environment(\.dismiss) var dismiss
    
    let invoice: Invoice
    let customer: Customer
    
    @State private var selectedPaymentMethod: PaymentMethod?
    @State private var showingNewCardForm = false
    @State private var paymentMethods: [PaymentMethod] = []
    @State private var isProcessing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccess = false
    
    private let stripeService = StripeService.shared
    private let coreDataManager = CoreDataManager.shared
    
    var amountDue: Decimal {
        return invoice.balance
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Amount Section
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Amount Due")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatCurrency(amountDue))
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.green)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                // Payment Method Selection
                Section("Payment Method") {
                    if paymentMethods.isEmpty {
                        Button {
                            showingNewCardForm = true
                        } label: {
                            Label("Add Credit Card", systemImage: "creditcard.fill")
                        }
                    } else {
                        ForEach(paymentMethods) { method in
                            PaymentMethodRow(
                                paymentMethod: method,
                                isSelected: selectedPaymentMethod?.id == method.id
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedPaymentMethod = method
                            }
                        }
                        
                        Button {
                            showingNewCardForm = true
                        } label: {
                            Label("Add New Card", systemImage: "plus.circle")
                        }
                    }
                }
                
                // Invoice Details
                Section("Invoice Details") {
                    LabeledContent("Invoice #", value: invoice.formattedInvoiceNumber)
                    LabeledContent("Customer", value: "\(customer.firstName ?? "") \(customer.lastName ?? "")")
                    if let dueDate = invoice.dueDate {
                        LabeledContent("Due Date", value: dueDate.formatted(date: .abbreviated, time: .omitted))
                    }
                }
                
                // Process Button
                Section {
                    Button {
                        processPayment()
                    } label: {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Processing...")
                            } else {
                                Image(systemName: "creditcard.fill")
                                Text("Process Payment")
                                Spacer()
                                Text(formatCurrency(amountDue))
                                    .fontWeight(.bold)
                            }
                        }
                    }
                    .disabled(selectedPaymentMethod == nil || isProcessing)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Process Payment")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 600, height: 650)
        .onAppear {
            loadPaymentMethods()
        }
        .sheet(isPresented: $showingNewCardForm) {
            AddPaymentMethodView(customerId: customer.id ?? UUID())
                .onDisappear {
                    loadPaymentMethods()
                }
        }
        .alert("Payment Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .alert("Payment Successful", isPresented: $showingSuccess) {
            Button("Done") {
                dismiss()
            }
        } message: {
            Text("Payment of \(formatCurrency(amountDue)) has been processed successfully.")
        }
    }
    
    private func loadPaymentMethods() {
        guard let customerId = customer.id else { return }
        paymentMethods = PaymentMethod.fetchPaymentMethods(for: customerId, context: coreDataManager.viewContext)
        
        // Auto-select default payment method
        if selectedPaymentMethod == nil {
            selectedPaymentMethod = paymentMethods.first { $0.isDefault } ?? paymentMethods.first
        }
    }
    
    private func processPayment() {
        guard let paymentMethod = selectedPaymentMethod,
              let customerId = customer.id,
              let invoiceId = invoice.id,
              let paymentMethodId = paymentMethod.paymentMethodId else {
            return
        }
        
        isProcessing = true
        
        Task {
            do {
                _ = try await stripeService.processPayment(
                    amount: amountDue,
                    currency: "USD",
                    customerId: customerId,
                    invoiceId: invoiceId,
                    paymentMethodId: paymentMethodId
                )
                
                await MainActor.run {
                    isProcessing = false
                    showingSuccess = true
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
    
    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: value as NSDecimalNumber) ?? "$0.00"
    }
}

// MARK: - Payment Method Row

struct PaymentMethodRow: View {
    let paymentMethod: PaymentMethod
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Image(systemName: paymentMethod.cardBrandIcon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(paymentMethod.displayName)
                    .font(.body)
                
                HStack(spacing: 8) {
                    Text("Expires \(paymentMethod.displayExpiration)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if paymentMethod.isExpired {
                        Text("EXPIRED")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .cornerRadius(4)
                    } else if paymentMethod.isExpiringSoon {
                        Text("EXPIRING SOON")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .cornerRadius(4)
                    }
                    
                    if paymentMethod.isDefault {
                        Text("DEFAULT")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .cornerRadius(4)
                    }
                }
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Payment Method View

struct AddPaymentMethodView: View {
    @Environment(\.dismiss) var dismiss
    
    let customerId: UUID
    
    @State private var cardNumber = ""
    @State private var cardholderName = ""
    @State private var expiryMonth = ""
    @State private var expiryYear = ""
    @State private var cvv = ""
    @State private var zipCode = ""
    @State private var setAsDefault = true
    @State private var isProcessing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private let stripeService = StripeService.shared
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Card Information") {
                    TextField("Card Number", text: $cardNumber)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Cardholder Name", text: $cardholderName)
                        .textFieldStyle(.roundedBorder)
                    
                    HStack(spacing: 12) {
                        TextField("MM", text: $expiryMonth)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                        
                        Text("/")
                        
                        TextField("YY", text: $expiryYear)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                        
                        Spacer()
                        
                        TextField("CVV", text: $cvv)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }
                }
                
                Section("Billing Information") {
                    TextField("ZIP Code", text: $zipCode)
                        .textFieldStyle(.roundedBorder)
                }
                
                Section {
                    Toggle("Set as default payment method", isOn: $setAsDefault)
                }
                
                Section {
                    Text("Your card information is securely processed by Stripe. We do not store your complete card details.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Add Payment Method")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePaymentMethod()
                    }
                    .disabled(!isFormValid || isProcessing)
                }
            }
        }
        .frame(width: 550, height: 550)
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var isFormValid: Bool {
        return !cardNumber.isEmpty &&
               !cardholderName.isEmpty &&
               !expiryMonth.isEmpty &&
               !expiryYear.isEmpty &&
               !cvv.isEmpty &&
               !zipCode.isEmpty
    }
    
    private func savePaymentMethod() {
        isProcessing = true
        
        // In a real app, you would:
        // 1. Tokenize the card with Stripe.js or Stripe iOS SDK
        // 2. Send the token to your backend
        // 3. Create a payment method on Stripe
        // 4. Save the payment method ID locally
        
        // For now, we'll simulate this
        Task {
            do {
                // Simulate API call
                try await Task.sleep(nanoseconds: 1_000_000_000)
                
                // Create mock payment method ID
                let mockPaymentMethodId = "pm_\(UUID().uuidString.prefix(24))"
                
                // Save to local database
                _ = try await stripeService.savePaymentMethod(
                    customerId: customerId,
                    paymentMethodId: mockPaymentMethodId
                )
                
                await MainActor.run {
                    isProcessing = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

// MARK: - Identifiable Extension

extension PaymentMethod: Identifiable {
    // Core Data already provides an id property via our model
}
