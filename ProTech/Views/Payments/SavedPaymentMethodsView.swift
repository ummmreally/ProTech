//
//  SavedPaymentMethodsView.swift
//  ProTech
//
//  Manage saved payment methods (cards on file)
//

import SwiftUI

struct SavedPaymentMethodsView: View {
    let customer: Customer
    
    @State private var paymentMethods: [PaymentMethod] = []
    @State private var showingAddCard = false
    @State private var selectedMethod: PaymentMethod?
    @State private var showingDeleteConfirmation = false
    
    private let stripeService = StripeService.shared
    private let coreDataManager = CoreDataManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Saved Payment Methods")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(customer.firstName ?? "") \(customer.lastName ?? "")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    showingAddCard = true
                } label: {
                    Label("Add Card", systemImage: "plus.circle.fill")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            Divider()
            
            // Payment Methods List
            if paymentMethods.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(paymentMethods) { method in
                            PaymentMethodCard(paymentMethod: method)
                                .contextMenu {
                                    Button {
                                        setAsDefault(method)
                                    } label: {
                                        Label("Set as Default", systemImage: "star.fill")
                                    }
                                    .disabled(method.isDefault)
                                    
                                    Button(role: .destructive) {
                                        selectedMethod = method
                                        showingDeleteConfirmation = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            loadPaymentMethods()
        }
        .sheet(isPresented: $showingAddCard) {
            AddPaymentMethodView(customerId: customer.id ?? UUID())
                .onDisappear {
                    loadPaymentMethods()
                }
        }
        .alert("Delete Payment Method", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let method = selectedMethod {
                    deletePaymentMethod(method)
                }
            }
        } message: {
            Text("Are you sure you want to delete this payment method?")
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "creditcard")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Payment Methods")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add a credit card to process payments quickly")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                showingAddCard = true
            } label: {
                Label("Add Credit Card", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private func loadPaymentMethods() {
        guard let customerId = customer.id else { return }
        paymentMethods = PaymentMethod.fetchPaymentMethods(for: customerId, context: coreDataManager.viewContext)
    }
    
    private func setAsDefault(_ paymentMethod: PaymentMethod) {
        // Remove default from all others
        for method in paymentMethods {
            method.isDefault = false
        }
        
        // Set this one as default
        paymentMethod.isDefault = true
        
        try? coreDataManager.viewContext.save()
        loadPaymentMethods()
    }
    
    private func deletePaymentMethod(_ paymentMethod: PaymentMethod) {
        stripeService.deletePaymentMethod(paymentMethod)
        loadPaymentMethods()
    }
}

// MARK: - Payment Method Card

struct PaymentMethodCard: View {
    let paymentMethod: PaymentMethod
    
    var body: some View {
        HStack(spacing: 16) {
            // Card icon
            Image(systemName: paymentMethod.cardBrandIcon)
                .font(.system(size: 40))
                .foregroundColor(cardColor)
                .frame(width: 60, height: 40)
                .background(cardColor.opacity(0.1))
                .cornerRadius(8)
            
            // Card details
            VStack(alignment: .leading, spacing: 6) {
                Text(paymentMethod.displayName)
                    .font(.headline)
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                        Text("Exp: \(paymentMethod.displayExpiration)")
                            .font(.caption)
                    }
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
                }
            }
            
            Spacer()
            
            // Default badge
            if paymentMethod.isDefault {
                VStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("Default")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(paymentMethod.isDefault ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
    
    private var cardColor: Color {
        switch paymentMethod.cardBrand?.lowercased() {
        case "visa":
            return .blue
        case "mastercard":
            return .orange
        case "amex", "american express":
            return .green
        case "discover":
            return .purple
        default:
            return .gray
        }
    }
}

// MARK: - Preview

struct SavedPaymentMethodsView_Previews: PreviewProvider {
    static var previews: some View {
        let context = CoreDataManager.shared.viewContext
        let customer = Customer(context: context)
        customer.firstName = "John"
        customer.lastName = "Doe"
        customer.id = UUID()
        
        return SavedPaymentMethodsView(customer: customer)
    }
}
