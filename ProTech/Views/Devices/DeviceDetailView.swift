//
//  DeviceDetailView.swift
//  ProTech
//
//  View details and repair procedures for a specific device model.
//

import SwiftUI
import CoreData

struct DeviceDetailView: View {
    @ObservedObject var device: DeviceModel
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest var procedures: FetchedResults<RepairProcedure>
    
    init(device: DeviceModel) {
        self.device = device
        _procedures = FetchRequest<RepairProcedure>(
            sortDescriptors: [NSSortDescriptor(keyPath: \RepairProcedure.name, ascending: true)],
            predicate: NSPredicate(format: "deviceModel == %@", device)
        )
    }
    
    @State private var showingAddProcedure = false
    @State private var newProcedureName = ""
    @State private var newProcedureCost = ""
    @State private var newProcedureDuration = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(spacing: 20) {
                    Image(systemName: device.imageSystemName ?? "iphone")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(15)
                    
                    VStack(alignment: .leading) {
                        Text(device.name ?? "Unknown")
                            .font(.largeTitle)
                            .bold()
                        
                        Text(device.identifier ?? "No ID")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        Text("Released: \(device.releaseYear)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                    
                    Spacer()
                }
                .padding()
                
                Divider()
                
                // Repair Procedures (Price List)
                VStack(alignment: .leading) {
                    HStack {
                        Text("Repair Price List")
                            .font(.title2)
                            .bold()
                        
                        Spacer()
                        
                        Button("Add Repair") {
                            showingAddProcedure = true
                        }
                    }
                    .padding(.horizontal)
                    
                    if procedures.isEmpty {
                        Text("No procedures listed.")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(procedures) { procedure in
                            RepairProcedureRow(procedure: procedure)
                        }
                    }
                }
            }
        }
        .navigationTitle(device.name ?? "Device Details")
        .sheet(isPresented: $showingAddProcedure) {
            NavigationStack {
                Form {
                    TextField("Repair Name (e.g. Screen)", text: $newProcedureName)
                    TextField("Cost ($)", text: $newProcedureCost)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                    TextField("Duration (Minutes)", text: $newProcedureDuration)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                }
                .navigationTitle("Add Procedure")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingAddProcedure = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            addProcedure()
                            showingAddProcedure = false
                        }
                        .disabled(newProcedureName.isEmpty)
                    }
                }
            }
        }
    }
    
    private func addProcedure() {
        let procedure = RepairProcedure(context: viewContext)
        procedure.id = UUID()
        procedure.name = newProcedureName
        procedure.estimatedDurationMinutes = Int16(newProcedureDuration) ?? 60
        procedure.baseCost = NSDecimalNumber(string: newProcedureCost)
        procedure.deviceModel = device
        
        try? viewContext.save()
        
        // Reset fields
        newProcedureName = ""
        newProcedureCost = ""
        newProcedureDuration = ""
    }
}

struct RepairProcedureRow: View {
    @ObservedObject var procedure: RepairProcedure
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(procedure.name ?? "Unknown Repair")
                    .font(.headline)
                Text("\(procedure.estimatedDurationMinutes) mins")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let cost = procedure.baseCost {
                Text(cost.decimalValue, format: .currency(code: "USD"))
                    .font(.headline)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}
