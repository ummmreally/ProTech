//
//  SMSConfirmationModal.swift
//  ProTech
//
//  SMS confirmation modal with editable message
//

import SwiftUI

struct SMSConfirmationModal: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool
    
    let customer: Customer
    let defaultMessage: String
    let onSend: (String) -> Void
    
    @State private var messageBody: String
    @State private var isSending = false
    
    init(isPresented: Binding<Bool>, customer: Customer, defaultMessage: String, onSend: @escaping (String) -> Void) {
        self._isPresented = isPresented
        self.customer = customer
        self.defaultMessage = defaultMessage
        self.onSend = onSend
        self._messageBody = State(initialValue: defaultMessage)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Confirm SMS Message")
                        .font(.headline)
                    
                    if let phone = customer.phone {
                        Label(phone, systemImage: "phone.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            
            Divider()
            
            // Customer Info
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(customer.firstName ?? "") \(customer.lastName ?? "")")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if let phone = customer.phone {
                        Text(phone)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding()
            
            Divider()
            
            // Message Preview
            VStack(alignment: .leading, spacing: 8) {
                Text("Message Preview")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                TextEditor(text: $messageBody)
                    .font(.body)
                    .frame(minHeight: 120, maxHeight: 200)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.05))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                
                HStack {
                    Image(systemName: "info.circle.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text("\(messageBody.count) characters")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if messageBody.count > 160 {
                        Text("• \((messageBody.count / 160) + 1) SMS segments")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                    Spacer()
                }
            }
            .padding()
            
            Divider()
            
            // Actions
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                if isSending {
                    ProgressView()
                        .controlSize(.small)
                        .padding(.trailing, 8)
                }
                
                Button {
                    sendMessage()
                } label: {
                    Label("Send SMS", systemImage: "paperplane.fill")
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(messageBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending || customer.phone == nil)
            }
            .padding()
        }
        .frame(width: 500)
    }
    
    private func sendMessage() {
        guard !isSending else { return }
        isSending = true
        
        let trimmedMessage = messageBody.trimmingCharacters(in: .whitespacesAndNewlines)
        onSend(trimmedMessage)
        
        // Small delay for visual feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            dismiss()
        }
    }
}

// MARK: - Convenience Initializer for Ticket

extension SMSConfirmationModal {
    static func forTicket(isPresented: Binding<Bool>, ticket: Ticket, customer: Customer, message: String, onSend: @escaping (String) -> Void) -> SMSConfirmationModal {
        return SMSConfirmationModal(
            isPresented: isPresented,
            customer: customer,
            defaultMessage: message,
            onSend: onSend
        )
    }
}

// MARK: - Message Templates

extension SMSConfirmationModal {
    static func readyForPickupMessage(customerName: String, ticketNumber: Int32, deviceType: String) -> String {
        """
        Hi \(customerName), your \(deviceType) repair is complete and ready for pickup! Ticket #\(ticketNumber).
        
        Please bring this text or your ticket number when picking up. Thank you for choosing our service!
        """
    }
    
    static func repairStartedMessage(customerName: String, deviceType: String) -> String {
        """
        Hi \(customerName), we've started working on your \(deviceType). We'll notify you once it's ready for pickup. Thank you!
        """
    }
    
    static func estimateReadyMessage(customerName: String, deviceType: String) -> String {
        """
        Hi \(customerName), we've completed the assessment of your \(deviceType). Please call us to discuss the repair estimate. Thank you!
        """
    }
    
    static func delayedRepairMessage(customerName: String, deviceType: String) -> String {
        """
        Hi \(customerName), there's a slight delay with your \(deviceType) repair. We'll update you as soon as possible. We appreciate your patience!
        """
    }
}
