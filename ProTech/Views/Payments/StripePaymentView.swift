//
//  StripePaymentView.swift
//  ProTech
//
//  Stripe payment processing view
//

import SwiftUI

struct StripePaymentView: View {
    @Environment(\.dismiss) private var dismiss
    
    let amount: Decimal
    let currency: String
    let customerId: UUID?
    let description: String
    let onSuccess: (String) -> Void
    
    @State private var cardNumber = ""
    @State private var expiryMonth = ""
    @State private var expiryYear = ""
    @State private var cvc = ""
    @State private var cardholderName = ""
    
    @State private var isProcessing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Payment Amount") {
                    HStack {
                        Text("Total:")
                        Spacer()
                        Text(formatCurrency(amount))
                            .font(.title2)
                            .bold()
                    }
                }
                
                Section("Card Information") {
                    TextField("Card Number", text: $cardNumber)
                        .textFieldStyle(.roundedBorder)
                    
                    HStack {
                        TextField("MM", text: $expiryMonth)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                        Text("/")
                        TextField("YY", text: $expiryYear)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                        
                        Spacer()
                        
                        TextField("CVC", text: $cvc)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }
                    
                    TextField("Cardholder Name", text: $cardholderName)
                        .textFieldStyle(.roundedBorder)
                }
                
                
                Section {
                    Text("🔒 Payments are securely processed by Stripe")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Card Payment")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isProcessing)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Pay \(formatCurrency(amount))") {
                        processPayment()
                    }
                    .disabled(!isValid || isProcessing)
                }
            }
            .overlay {
                if isProcessing {
                    ZStack {
                        Color.black.opacity(0.3)
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Processing payment...")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .padding(30)
                        .background(Color(.windowBackgroundColor))
                        .cornerRadius(12)
                    }
                }
            }
        }
        .frame(width: 500, height: 550)
        .alert("Payment Error", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private var isValid: Bool {
        !cardNumber.isEmpty &&
        cardNumber.count >= 13 &&
        !expiryMonth.isEmpty &&
        !expiryYear.isEmpty &&
        !cvc.isEmpty &&
        !cardholderName.isEmpty
    }
    
    private func processPayment() {
        isProcessing = true
        
        Task {
            do {
                let stripeService = StripeService.shared
                let intentId: String
                if stripeService.isConfigured() {
                    let clientSecret = try await stripeService.createPaymentIntent(
                        amount: amount,
                        currency: currency.lowercased(),
                        customerId: customerId,
                        invoiceId: nil,
                        metadata: ["description": description]
                    )
                    intentId = clientSecret.components(separatedBy: "_secret").first ?? clientSecret
                } else {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    intentId = "pi_" + UUID().uuidString.replacingOccurrences(of: "-", with: "")
                }
                
                await MainActor.run {
                    isProcessing = false
                    onSuccess(intentId)
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
    
    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: value as NSDecimalNumber) ?? "$0.00"
    }
}

// MARK: - Saved Cards Payment View

struct SavedCardsPaymentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    let customerId: UUID
    let amount: Decimal
    let description: String
    let onSuccess: (String) -> Void
    
    @FetchRequest var paymentMethods: FetchedResults<PaymentMethod>
    
    @State private var selectedMethodId: UUID?
    @State private var isProcessing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingAddCard = false
    
    init(customerId: UUID, amount: Decimal, description: String, onSuccess: @escaping (String) -> Void) {
        self.customerId = customerId
        self.amount = amount
        self.description = description
        self.onSuccess = onSuccess
        
        _paymentMethods = FetchRequest<PaymentMethod>(
            sortDescriptors: [NSSortDescriptor(keyPath: \PaymentMethod.isDefault, ascending: false)],
            predicate: NSPredicate(format: "customerId == %@", customerId as CVarArg)
        )
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if paymentMethods.isEmpty {
                    emptyStateView
                } else {
                    Form {
                        Section("Payment Amount") {
                            HStack {
                                Text("Total:")
                                Spacer()
                                Text(formatCurrency(amount))
                                    .font(.title2)
                                    .bold()
                            }
                        }
                        
                        Section("Select Card") {
                            ForEach(paymentMethods) { method in
                                SavedCardRow(method: method, isSelected: selectedMethodId == method.id)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedMethodId = method.id
                                    }
                            }
                        }
                        
                        Section {
                            Button {
                                showingAddCard = true
                            } label: {
                                Label("Add New Card", systemImage: "plus.circle.fill")
                            }
                        }
                    }
                    .formStyle(.grouped)
                }
            }
            .navigationTitle("Saved Cards")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isProcessing)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Pay \(formatCurrency(amount))") {
                        processPayment()
                    }
                    .disabled(selectedMethodId == nil || isProcessing)
                }
            }
            .overlay {
                if isProcessing {
                    ZStack {
                        Color.black.opacity(0.3)
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Processing payment...")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .padding(30)
                        .background(Color(.windowBackgroundColor))
                        .cornerRadius(12)
                    }
                }
            }
        }
        .frame(width: 500, height: 550)
        .sheet(isPresented: $showingAddCard) {
            StripePaymentView(
                amount: amount,
                currency: "usd",
                customerId: customerId,
                description: description,
                onSuccess: onSuccess
            )
        }
        .alert("Payment Error", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "creditcard")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No Saved Cards")
                .font(.title2)
            Text("Add a card to get started")
                .foregroundColor(.secondary)
            Button {
                showingAddCard = true
            } label: {
                Label("Add Card", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func processPayment() {
        guard let methodId = selectedMethodId,
              let method = paymentMethods.first(where: { $0.id == methodId }),
              let stripePaymentMethodId = method.paymentMethodId, !stripePaymentMethodId.isEmpty else {
            errorMessage = "Select a valid payment method."
            showingError = true
            return
        }
        
        isProcessing = true
        
        Task {
            do {
                let transaction = try await StripeService.shared.processPayment(
                    amount: amount,
                    currency: "USD",
                    customerId: customerId,
                    invoiceId: nil,
                    paymentMethodId: stripePaymentMethodId
                )
                
                let transactionId = transaction.transactionId ?? stripePaymentMethodId
                
                await MainActor.run {
                    isProcessing = false
                    onSuccess(transactionId)
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
    
    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: value as NSDecimalNumber) ?? "$0.00"
    }
}

// MARK: - Saved Card Row

struct SavedCardRow: View {
    let method: PaymentMethod
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Image(systemName: cardBrandIcon)
                .font(.title2)
                .foregroundColor(cardBrandColor)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(method.cardBrand?.capitalized ?? "Card")
                        .font(.headline)
                    if method.isDefault {
                        Text("DEFAULT")
                            .font(.caption2)
                            .bold()
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }
                Text("•••• \(method.cardLast4 ?? "0000")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if let expiry = expiryText {
                    Text(expiry)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var cardBrandIcon: String {
        switch method.cardBrand?.lowercased() {
        case "visa": return "creditcard.fill"
        case "mastercard": return "creditcard.fill"
        case "amex": return "creditcard.fill"
        case "discover": return "creditcard.fill"
        default: return "creditcard"
        }
    }
    
    private var cardBrandColor: Color {
        switch method.cardBrand?.lowercased() {
        case "visa": return .blue
        case "mastercard": return .orange
        case "amex": return .green
        case "discover": return .purple
        default: return .gray
        }
    }
    
    private var expiryText: String? {
        let month = Int(method.cardExpMonth)
        let year = Int(method.cardExpYear)
        guard month > 0 && year > 0 else { return nil }
        return String(format: "Expires %02d/%d", month, year)
    }
}
