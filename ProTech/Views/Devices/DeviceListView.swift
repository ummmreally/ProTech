//
//  DeviceListView.swift
//  ProTech
//
//  Browse and manage device database (Apple Focus)
//

import SwiftUI
import CoreData

struct DeviceListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var selectedType: String = "iPhone"
    @State private var searchText = ""
    @State private var showingAddSheet = false
    
    let deviceTypes = ["iPhone", "iPad", "Mac", "Watch"]
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DeviceModel.releaseYear, ascending: false)],
        animation: .default
    ) private var allDevices: FetchedResults<DeviceModel>
    
    var filteredDevices: [DeviceModel] {
        let typeFiltered = allDevices.filter { $0.type == selectedType }
        if searchText.isEmpty {
            return typeFiltered
        } else {
            return typeFiltered.filter { $0.name?.localizedCaseInsensitiveContains(searchText) ?? false }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category Picker
                Picker("Type", selection: $selectedType) {
                    ForEach(deviceTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // List
                if filteredDevices.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "mag")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No devices found")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        if allDevices.isEmpty {
                            Button("Seed Apple Data") {
                                seedData()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(filteredDevices) { device in
                        NavigationLink(destination: DeviceDetailView(device: device)) {
                            HStack {
                                Image(systemName: device.imageSystemName ?? "iphone")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                    .frame(width: 40)
                                
                                VStack(alignment: .leading) {
                                    Text(device.name ?? "Unknown Device")
                                        .font(.headline)
                                    if let id = device.identifier {
                                        Text(id)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Text(String(device.releaseYear))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(6)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Device Database")
            .searchable(text: $searchText, prompt: "Search models...")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true // Implement Manual Add if needed
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
    
    private func seedData() {
        let seeder = DeviceSeeder(context: viewContext)
        seeder.seedAppleDevices()
    }
}

// MARK: - Simple Seeder
struct DeviceSeeder {
    let context: NSManagedObjectContext
    
    func seedAppleDevices() {
        // iPhones
        createDevice(name: "iPhone 15 Pro", identifier: "A3102", type: "iPhone", year: 2023)
        createDevice(name: "iPhone 14 Pro", identifier: "A2890", type: "iPhone", year: 2022)
        createDevice(name: "iPhone 13", identifier: "A2633", type: "iPhone", year: 2021)
        createDevice(name: "iPhone 12", identifier: "A2403", type: "iPhone", year: 2020)
        createDevice(name: "iPhone 11", identifier: "A2221", type: "iPhone", year: 2019)
        createDevice(name: "iPhone XR", identifier: "A2105", type: "iPhone", year: 2018)
        
        // iPads
        createDevice(name: "iPad Pro 12.9 (6th)", identifier: "A2436", type: "iPad", year: 2022)
        createDevice(name: "iPad Air (5th)", identifier: "A2588", type: "iPad", year: 2022)
        createDevice(name: "iPad (10th)", identifier: "A2696", type: "iPad", year: 2022)
        
        // Macs
        createDevice(name: "MacBook Pro 14 M3", identifier: "Mac15,3", type: "Mac", year: 2023)
        createDevice(name: "MacBook Air M2", identifier: "Mac14,2", type: "Mac", year: 2022)
        
        // Watch
        createDevice(name: "Apple Watch Ultra 2", identifier: "Watch7,5", type: "Watch", year: 2023)
        createDevice(name: "Apple Watch Series 9", identifier: "Watch7,4", type: "Watch", year: 2023)
        
        try? context.save()
    }
    
    private func createDevice(name: String, identifier: String, type: String, year: Int16) {
        let device = DeviceModel(context: context)
        device.id = UUID()
        device.name = name
        device.identifier = identifier
        device.type = type
        device.releaseYear = year
        
        switch type {
        case "iPhone": device.imageSystemName = "iphone"
        case "iPad": device.imageSystemName = "ipad"
        case "Mac": device.imageSystemName = "laptopcomputer"
        case "Watch": device.imageSystemName = "applewatch"
        default: device.imageSystemName = "questionmark.square"
        }
        
        // Seed default repair - Screen Swap
        let repair = RepairProcedure(context: context)
        repair.id = UUID()
        repair.name = "Screen Replacement"
        repair.baseCost = NSDecimalNumber(value: 129.99)
        repair.estimatedDurationMinutes = 60
        repair.deviceModel = device
        
        let battery = RepairProcedure(context: context)
        battery.id = UUID()
        battery.name = "Battery Replacement"
        battery.baseCost = NSDecimalNumber(value: 89.99)
        battery.estimatedDurationMinutes = 45
        battery.deviceModel = device
    }
}
