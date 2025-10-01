//
//  CheckInCustomerView.swift
//  ProTech
//
//  Check in a customer to the service queue
//

import SwiftUI
import CoreData

struct CheckInCustomerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Customer.lastName, ascending: true)]
    ) private var customers: FetchedResults<Customer>
    
    @State private var selectedCustomer: Customer?
    @State private var deviceType = ""
    @State private var deviceModel = ""
    @State private var issueDescription = ""
    @State private var priority: Priority = .normal
    @State private var estimatedCompletion: Date = Date().addingTimeInterval(3600 * 24) // 1 day
    @State private var searchText = ""
    @State private var showingNewCustomer = false
    
    private let deviceTypes = ["iPhone", "iPad", "Mac", "MacBook", "iMac", "Apple Watch", "AirPods", "Android Phone", "Android Tablet", "PC", "Other"]
    
    var filteredCustomers: [Customer] {
        if searchText.isEmpty {
            return Array(customers)
        } else {
            return customers.filter { customer in
                (customer.firstName?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (customer.lastName?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (customer.phone?.contains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Customer Selection
                Section("Customer") {
                    HStack {
                        TextField("Search customer...", text: $searchText)
                        
                        Button {
                            showingNewCustomer = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .buttonStyle(.borderless)
                    }
                    
                    if searchText.isEmpty && selectedCustomer == nil {
                        Text("Type to search for a customer")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    } else if !filteredCustomers.isEmpty {
                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(filteredCustomers.prefix(5)) { customer in
                                    Button {
                                        selectedCustomer = customer
                                        searchText = "\(customer.firstName ?? "") \(customer.lastName ?? "")"
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("\(customer.firstName ?? "") \(customer.lastName ?? "")")
                                                    .font(.body)
                                                if let phone = customer.phone {
                                                    Text(phone)
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            Spacer()
                                            if selectedCustomer?.id == customer.id {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.green)
                                            }
                                        }
                                        .padding(8)
                                        .background(selectedCustomer?.id == customer.id ? Color.blue.opacity(0.1) : Color.clear)
                                        .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                    }
                }
                
                // Device Information
                Section("Device Information") {
                    Picker("Device Type *", selection: $deviceType) {
                        Text("Select device").tag("")
                        ForEach(deviceTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    
                    TextField("Device Model", text: $deviceModel, prompt: Text("e.g., iPhone 14 Pro"))
                    
                    TextEditor(text: $issueDescription)
                        .frame(minHeight: 80)
                        .overlay(alignment: .topLeading) {
                            if issueDescription.isEmpty {
                                Text("Describe the issue... *")
                                    .foregroundColor(.secondary)
                                    .padding(8)
                                    .allowsHitTesting(false)
                            }
                        }
                }
                
                // Service Details
                Section("Service Details") {
                    Picker("Priority", selection: $priority) {
                        ForEach(Priority.allCases, id: \.self) { priority in
                            HStack {
                                Image(systemName: priority.icon)
                                Text(priority.displayName)
                            }
                            .tag(priority)
                        }
                    }
                    
                    DatePicker("Estimated Completion", selection: $estimatedCompletion, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Check In Customer")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Check In") {
                        checkInCustomer()
                    }
                    .disabled(!isValid)
                }
            }
        }
        .frame(width: 600, height: 700)
        .sheet(isPresented: $showingNewCustomer) {
            AddCustomerView()
        }
    }
    
    private var isValid: Bool {
        selectedCustomer != nil && !deviceType.isEmpty && !issueDescription.isEmpty
    }
    
    private func checkInCustomer() {
        guard let customer = selectedCustomer else { return }
        
        // Generate ticket number
        let ticketNumber = generateTicketNumber()
        
        // Create ticket
        let ticket = Ticket(context: viewContext)
        ticket.id = UUID()
        ticket.ticketNumber = ticketNumber
        ticket.customerId = customer.id
        ticket.deviceType = deviceType
        ticket.deviceModel = deviceModel.isEmpty ? nil : deviceModel
        ticket.issueDescription = issueDescription
        ticket.status = "waiting"
        ticket.priority = priority.rawValue
        ticket.checkedInAt = Date()
        ticket.estimatedCompletion = estimatedCompletion
        ticket.createdAt = Date()
        ticket.updatedAt = Date()
        
        // Save
        CoreDataManager.shared.save()
        
        // Dismiss
        dismiss()
    }
    
    private func generateTicketNumber() -> Int32 {
        let request: NSFetchRequest<Ticket> = Ticket.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Ticket.ticketNumber, ascending: false)]
        request.fetchLimit = 1

        if let lastTicket = try? viewContext.fetch(request).first {
            let lastNumber = lastTicket.ticketNumber
            if lastNumber >= 1001 {
                return lastNumber + 1
            }
        }

        return 1001 // Start from 1001
    }
}

// MARK: - Priority Enum

enum Priority: String, CaseIterable {
    case low = "low"
    case normal = "normal"
    case high = "high"
    case urgent = "urgent"
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "High"
        case .urgent: return "Urgent"
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "arrow.down.circle"
        case .normal: return "equal.circle"
        case .high: return "arrow.up.circle"
        case .urgent: return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .green
        case .normal: return .blue
        case .high: return .orange
        case .urgent: return .red
        }
    }
}
