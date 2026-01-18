//
//  GlobalSearchView.swift
//  ProTech
//
//  Unified search interface for Tickets, Customers, and Inventory.
//

import SwiftUI
import CoreData

struct GlobalSearchView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var isPresented: Bool
    
    @State private var searchText = ""
    @State private var selectedTab = "all" // all, tickets, customers, devices
    
    // Fetch Requests with predicates updated dynamically could be complex here.
    // For specific search, we might just load top results or use specific fetch requests.
    // Simpler here to fetch all and filter in memory for "instant" feel if dataset is small, 
    // OR use @FetchRequest with NSPredicate binding.
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Ticket.updatedAt, ascending: false)],
        animation: .default
    ) private var allTickets: FetchedResults<Ticket>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Customer.lastName, ascending: true)],
        animation: .default
    ) private var allCustomers: FetchedResults<Customer>
    
    // DeviceModel fetch request
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DeviceModel.name, ascending: true)],
        animation: .default
    ) private var allDevices: FetchedResults<DeviceModel>
    
    var filteredTickets: [Ticket] {
        guard !searchText.isEmpty else { return [] }
        return allTickets.filter { ticket in
            let id = String(ticket.ticketNumber)
            let issue = ticket.issueDescription ?? ""
            let serial = ticket.deviceSerialNumber ?? ""
            return id.contains(searchText) || issue.localizedCaseInsensitiveContains(searchText) || serial.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var filteredCustomers: [Customer] {
        guard !searchText.isEmpty else { return [] }
        return allCustomers.filter { customer in
            let first = customer.firstName ?? ""
            let last = customer.lastName ?? ""
            let phone = customer.phone ?? ""
            let email = customer.email ?? ""
            return first.localizedCaseInsensitiveContains(searchText) ||
                   last.localizedCaseInsensitiveContains(searchText) ||
                   phone.contains(searchText) ||
                   email.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var filteredDevices: [DeviceModel] {
        guard !searchText.isEmpty else { return [] }
        return allDevices.filter { device in
            let name = device.name ?? ""
            let id = device.identifier ?? ""
            return name.localizedCaseInsensitiveContains(searchText) || id.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Search Field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search tickets, customers, devices...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.title2)
                        .padding(.vertical, 8)
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                
                Divider()
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        if searchText.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "magnifyingglass.circle")
                                    .font(.system(size: 48))
                                    .foregroundColor(.gray.opacity(0.3))
                                Text("Type to search")
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 50)
                        } else {
                            if !filteredTickets.isEmpty {
                                SectionView(title: "Tickets", icon: "ticket") {
                                    ForEach(filteredTickets.prefix(5)) { ticket in
                                        NavigationLink(destination: TicketDetailView(ticket: ticket)) {
                                            SearchResultRow(
                                                title: "Ticket #\(ticket.ticketNumber)",
                                                subtitle: ticket.issueDescription ?? "No Issue",
                                                detail: ticket.status?.capitalized
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            
                            if !filteredCustomers.isEmpty {
                                SectionView(title: "Customers", icon: "person.2") {
                                    ForEach(filteredCustomers.prefix(5)) { customer in
                                        NavigationLink(destination: CustomerDetailView(customer: customer)) {
                                            SearchResultRow(
                                                title: "\(customer.firstName ?? "") \(customer.lastName ?? "")",
                                                subtitle: customer.email ?? "",
                                                detail: customer.phone
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            
                            if !filteredDevices.isEmpty {
                                SectionView(title: "Devices", icon: "laptopcomputer") {
                                    ForEach(filteredDevices.prefix(5)) { device in
                                        NavigationLink(destination: DeviceDetailView(device: device)) {
                                            SearchResultRow(
                                                title: device.name ?? "Unknown Device",
                                                subtitle: device.identifier ?? "",
                                                detail: device.type
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Global Search")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { isPresented = false }
                }
            }
        }
        .frame(width: 600, height: 500)
    }
}

struct SectionView<Content: View>: View {
    let title: String
    let icon: String
    let content: () -> Content
    
    init(title: String, icon: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                Text(title).font(.headline)
            }
            .foregroundColor(.secondary)
            
            content()
        }
    }
}

struct SearchResultRow: View {
    let title: String
    let subtitle: String
    let detail: String?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.body)
                    .bold()
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if let detail = detail {
                Text(detail)
                    .font(.caption)
                    .padding(4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
        .contentShape(Rectangle()) // Hit testing
    }
}
