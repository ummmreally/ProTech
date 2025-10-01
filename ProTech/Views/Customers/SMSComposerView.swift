//
//  SMSComposerView.swift
//  ProTech
//
//  SMS composer for sending messages to customers
//

import SwiftUI

struct SMSComposerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var messageBody: String = ""
    @State private var isSending = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
    let customer: Customer
    let predefinedMessage: String?
    
    init(customer: Customer, predefinedMessage: String? = nil) {
        self.customer = customer
        self.predefinedMessage = predefinedMessage
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Send SMS to \(customer.firstName ?? "") \(customer.lastName ?? "")")
                        .font(.headline)
                    
                    if let phone = customer.phone {
                        Label(phone, systemImage: "phone.fill")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                
                Divider()
                
                // Message Editor
                TextEditor(text: $messageBody)
                    .font(.body)
                    .frame(minHeight: 150)
                    .padding()
                    .scrollContentBackground(.hidden)
                    .background(Color.gray.opacity(0.05))
                
                // Character count
                HStack {
                    Spacer()
                    Text("\(messageBody.count) characters")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if messageBody.count > 160 {
                        Text("• \(messageSegments) SMS")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 4)
                
                // Quick Templates
                if messageBody.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quick Templates")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(smsTemplates, id: \.self) { template in
                                    Button(template) {
                                        messageBody = template
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Divider()
                
                // Buttons
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                    
                    Spacer()
                    
                    if isSending {
                        ProgressView()
                            .controlSize(.small)
                    }
                    
                    Button {
                        sendSMS()
                    } label: {
                        Label("Send SMS", systemImage: "paperplane.fill")
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(messageBody.isEmpty || isSending || customer.phone == nil)
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
        .frame(width: 500, height: 500)
        .onAppear {
            if let predefined = predefinedMessage {
                messageBody = predefined
            }
        }
        .alert("Error Sending SMS", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("SMS Sent!", isPresented: $showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your message was sent successfully to \(customer.firstName ?? "").")
        }
    }
    
    private var messageSegments: Int {
        return (messageBody.count / 160) + 1
    }
    
    private var smsTemplates: [String] {
        [
            "Your device is ready for pickup!",
            "We've received your device and will update you soon.",
            "Your repair is complete. Total: $XX.XX",
            "Reminder: Please pick up your device by end of day."
        ]
    }
    
    private func sendSMS() {
        guard let phone = customer.phone else { return }
        
        // Check Twilio configuration
        guard TwilioService.shared.isConfigured else {
            errorMessage = "Twilio is not configured. Please set up your Twilio credentials in Settings → SMS."
            showError = true
            return
        }
        
        isSending = true
        
        Task {
            do {
                let result = try await TwilioService.shared.sendSMS(to: phone, body: messageBody)
                
                // Save to Core Data
                await saveSMSToDatabase(result: result)
                
                await MainActor.run {
                    isSending = false
                    showSuccess = true
                }
            } catch let error as TwilioError {
                await MainActor.run {
                    isSending = false
                    errorMessage = error.errorDescription ?? "Unknown error"
                    showError = true
                }
            } catch {
                await MainActor.run {
                    isSending = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func saveSMSToDatabase(result: SMSResult) async {
        let context = CoreDataManager.shared.viewContext
        
        await context.perform {
            let smsMessage = SMSMessage(context: context)
            smsMessage.id = UUID()
            smsMessage.customerId = customer.id
            smsMessage.direction = "outbound"
            smsMessage.body = result.body
            smsMessage.status = result.status
            smsMessage.twilioSid = result.sid
            smsMessage.sentAt = Date()
            
            try? context.save()
        }
    }
}
