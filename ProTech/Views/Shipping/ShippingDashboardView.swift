//
//  ShippingDashboardView.swift
//  ProTech
//
//  Manage inbound and outbound shipments.
//

import SwiftUI
import CoreData

struct ShippingDashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ShippingLabel.createdAt, ascending: false)],
        animation: .default
    ) private var labels: FetchedResults<ShippingLabel>
    
    @State private var showingCreateLabel = false
    @State private var selectedTab = "outbound" // inbound, outbound
    
    var filteredLabels: [ShippingLabel] {
        labels.filter { $0.direction == selectedTab }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab Selection
                Picker("Direction", selection: $selectedTab) {
                    Text("Outbound (To Customer)").tag("outbound")
                    Text("Inbound (From Customer)").tag("inbound")
                }
                .pickerStyle(.segmented)
                .padding()
                
                if filteredLabels.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "shippingbox")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No \(selectedTab) shipments found.")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(filteredLabels) { label in
                        HStack {
                            Image(systemName: carrierIcon(for: label.carrier))
                                .font(.title)
                                .frame(width: 40)
                            
                            VStack(alignment: .leading) {
                                Text(label.trackingNumber ?? "No Tracking")
                                    .font(.headline)
                                Text(label.carrier ?? "Unknown Carrier")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text(label.status?.capitalized ?? "Unknown")
                                    .font(.subheadline)
                                    .padding(4)
                                    .background(statusColor(for: label.status).opacity(0.1))
                                    .foregroundColor(statusColor(for: label.status))
                                    .cornerRadius(4)
                                
                                if let date = label.estimatedDelivery {
                                    Text("Est: \(date, style: .date)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Shipping & Logistics")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingCreateLabel = true }) {
                        Label("Create Label", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateLabel) {
                CreateLabelView()
            }
        }
    }
    
    func carrierIcon(for carrier: String?) -> String {
        switch carrier?.lowercased() {
        case "ups": return "truck.box"
        case "fedex": return "airplane"
        case "usps": return "envelope"
        default: return "shippingbox"
        }
    }
    
    func statusColor(for status: String?) -> Color {
        switch status {
        case "delivered": return .green
        case "shipped": return .blue
        case "created": return .orange
        default: return .gray
        }
    }
}
