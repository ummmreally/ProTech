//
//  CheckInPrintDialog.swift
//  ProTech
//
//  Post-check-in print options dialog
//

import SwiftUI

struct CheckInPrintDialog: View {
    let ticket: Ticket
    let customer: Customer
    let onDismiss: () -> Void
    
    @State private var printAgreement = true
    @State private var printDeviceTag = true
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Success message
                HStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Check-In Complete!")
                            .font(.title)
                            .bold()
                        
                        Text("Ticket #\(String(format: "%05d", ticket.ticketNumber))")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
                
                // Print options
                VStack(alignment: .leading, spacing: 16) {
                    Text("Print Documents")
                        .font(.headline)
                    
                    VStack(spacing: 12) {
                        Toggle(isOn: $printAgreement) {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                    .foregroundColor(.blue)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Service Agreement Form")
                                        .font(.subheadline)
                                    Text("Customer copy with terms & conditions")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .toggleStyle(.checkbox)
                        
                        Toggle(isOn: $printDeviceTag) {
                            HStack {
                                Image(systemName: "tag.fill")
                                    .foregroundColor(.orange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Device Tag Label")
                                        .font(.subheadline)
                                    Text("Dymo label to attach to device")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .toggleStyle(.checkbox)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                }
                
                // Info message
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text("Print documents now or access them later from ticket details")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 12) {
                    Button("Skip Printing") {
                        onDismiss()
                    }
                    .buttonStyle(.bordered)
                    
                    Button {
                        printDocuments()
                        onDismiss()
                    } label: {
                        Label("Print & Continue", systemImage: "printer.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!printAgreement && !printDeviceTag)
                }
            }
            .padding(24)
            .frame(width: 500, height: 450)
            .navigationTitle("Print Documents")
        }
    }
    
    private func printDocuments() {
        if printAgreement {
            DymoPrintService.shared.printCheckInAgreement(ticket: ticket, customer: customer)
        }
        
        if printDeviceTag {
            DymoPrintService.shared.printDeviceLabel(
                ticket: ticket,
                customer: customer
            )
        }
    }
}
