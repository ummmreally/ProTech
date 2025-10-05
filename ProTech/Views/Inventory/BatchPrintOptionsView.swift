//
//  BatchPrintOptionsView.swift
//  ProTech
//
//  Batch label printing options dialog
//

import SwiftUI

struct BatchPrintOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    
    let itemCount: Int
    let onPrint: (Int) -> Void
    
    @State private var copies = 1
    @State private var printerAvailable = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Printer status
                HStack(spacing: 12) {
                    Image(systemName: printerAvailable ? "printer.fill" : "printer.fill.and.paper.fill")
                        .font(.largeTitle)
                        .foregroundColor(printerAvailable ? .green : .orange)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(printerAvailable ? "Dymo Printer Found" : "No Dymo Printer Detected")
                            .font(.headline)
                        
                        if !printerAvailable {
                            Text("Labels will be sent to default printer")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                .background(printerAvailable ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                .cornerRadius(12)
                
                // Print summary
                VStack(alignment: .leading, spacing: 16) {
                    Text("Print Summary")
                        .font(.headline)
                    
                    HStack {
                        Image(systemName: "shippingbox.fill")
                            .foregroundColor(.blue)
                        Text("Products to print:")
                        Spacer()
                        Text("\(itemCount)")
                            .bold()
                    }
                    
                    Divider()
                    
                    // Copies selector
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "doc.on.doc.fill")
                                .foregroundColor(.purple)
                            Text("Copies per product:")
                            Spacer()
                        }
                        
                        HStack {
                            Stepper(value: $copies, in: 1...10) {
                                Text("\(copies)")
                                    .font(.title2)
                                    .bold()
                                    .frame(width: 60)
                            }
                        }
                    }
                    
                    Divider()
                    
                    HStack {
                        Image(systemName: "printer.fill")
                            .foregroundColor(.green)
                        Text("Total labels:")
                        Spacer()
                        Text("\(itemCount * copies)")
                            .font(.title3)
                            .bold()
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                
                // Label preview info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Label Size: 2.25\" × 1.25\" (Dymo Address Label)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Each label includes: Product name, SKU, Price, Stock, Barcode")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 12) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .keyboardShortcut(.cancelAction)
                    
                    Button {
                        onPrint(copies)
                        dismiss()
                    } label: {
                        Label("Print \(itemCount * copies) Label\(itemCount * copies == 1 ? "" : "s")", systemImage: "printer.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(24)
            .frame(width: 500, height: 450)
            .navigationTitle("Batch Print Labels")
        }
        .onAppear {
            printerAvailable = DymoPrintService.shared.isDymoPrinterAvailable()
        }
    }
}
