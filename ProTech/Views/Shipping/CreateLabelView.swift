//
//  CreateLabelView.swift
//  ProTech
//
//  Generate a new shipping label.
//

import SwiftUI
import CoreData

struct CreateLabelView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    // In a real app, we would fetch tickets to associate with.
    @State private var trackingNumber = ""
    @State private var carrier = "UPS"
    @State private var direction = "outbound"
    @State private var serviceLevel = "ground"
    @State private var weight = "1.0"
    
    let carriers = ["UPS", "FedEx", "USPS", "DHL"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Shipment Details") {
                    Picker("Direction", selection: $direction) {
                        Text("Outbound (To Customer)").tag("outbound")
                        Text("Inbound (Return Label)").tag("inbound")
                    }
                    
                    Picker("Carrier", selection: $carrier) {
                        ForEach(carriers, id: \.self) { carrier in
                            Text(carrier).tag(carrier)
                        }
                    }
                    
                    Picker("Service", selection: $serviceLevel) {
                        Text("Ground").tag("ground")
                        Text("Next Day Air").tag("next_day")
                        Text("2nd Day Air").tag("2nd_day")
                    }
                    
                    TextField("Weight (lbs)", text: $weight)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                }
                
                Section("Mock Generation") {
                    Button("Generate Label") {
                        generateLabel()
                    }
                }
            }
            .navigationTitle("New Shipment")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func generateLabel() {
        // Mock API Call
        let label = ShippingLabel(context: viewContext)
        label.id = UUID()
        label.carrier = carrier
        label.direction = direction
        // Generate mock tracking number
        let prefix = carrier == "UPS" ? "1Z" : "90"
        let random = Int.random(in: 10000000...99999999)
        label.trackingNumber = "\(prefix)\(random)"
        label.status = "created"
        label.createdAt = Date()
        label.estimatedDelivery = Calendar.current.date(byAdding: .day, value: 3, to: Date())
        
        try? viewContext.save()
        dismiss()
    }
}
