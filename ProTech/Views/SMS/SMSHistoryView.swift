//
//  SMSHistoryView.swift
//  ProTech
//
//  SMS message history view
//

import SwiftUI
import CoreData

struct SMSHistoryView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SMSMessage.sentAt, ascending: false)]
    ) var messages: FetchedResults<SMSMessage>
    
    var body: some View {
        VStack {
            if messages.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "message")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("No SMS Messages")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("Send your first SMS from a customer's detail page")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    if !TwilioService.shared.isConfigured {
                        Button {
                            NotificationCenter.default.post(name: .openTwilioSettings, object: nil)
                        } label: {
                            Label("Setup Twilio", systemImage: "gear")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(messages) { message in
                        SMSMessageRow(message: message)
                    }
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle("SMS History")
    }
}

struct SMSMessageRow: View {
    let message: SMSMessage
    @FetchRequest var customer: FetchedResults<Customer>
    
    init(message: SMSMessage) {
        self.message = message
        _customer = FetchRequest<Customer>(
            sortDescriptors: [],
            predicate: NSPredicate(format: "id == %@", message.customerId! as CVarArg)
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let customer = customer.first {
                    Text("\(customer.firstName ?? "") \(customer.lastName ?? "")")
                        .font(.headline)
                } else {
                    Text("Unknown Customer")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let sentAt = message.sentAt {
                    Text(sentAt, format: .dateTime.month().day().hour().minute())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(message.body ?? "")
                .font(.body)
                .lineLimit(2)
            
            HStack {
                StatusBadge(status: message.status ?? "unknown")
                
                if message.direction == "outbound" {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                } else {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct StatusBadge: View {
    let status: String
    
    var body: some View {
        Text(status.uppercased())
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(4)
    }
    
    var backgroundColor: Color {
        switch status.lowercased() {
        case "sent", "delivered":
            return .green
        case "failed":
            return .red
        case "queued", "sending":
            return .orange
        default:
            return .gray
        }
    }
}
