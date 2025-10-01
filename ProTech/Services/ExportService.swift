//
//  ExportService.swift
//  ProTech
//
//  Export customers and tickets to CSV
//

import Foundation
import CoreData

class ExportService {
    static let shared = ExportService()
    
    private init() {}
    
    // MARK: - Export Customers to CSV
    
    func exportCustomersToCSV() -> URL? {
        let context = CoreDataManager.shared.viewContext
        let request: NSFetchRequest<Customer> = Customer.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Customer.lastName, ascending: true)]
        
        guard let customers = try? context.fetch(request) else {
            return nil
        }
        
        var csvText = "First Name,Last Name,Email,Phone,Address,Created At,Updated At\n"
        
        for customer in customers {
            let firstName = escapeCSV(customer.firstName ?? "")
            let lastName = escapeCSV(customer.lastName ?? "")
            let email = escapeCSV(customer.email ?? "")
            let phone = escapeCSV(customer.phone ?? "")
            let address = escapeCSV(customer.address ?? "")
            let createdAt = customer.createdAt?.formatted(date: .abbreviated, time: .shortened) ?? ""
            let updatedAt = customer.updatedAt?.formatted(date: .abbreviated, time: .shortened) ?? ""
            
            let row = "\(firstName),\(lastName),\(email),\(phone),\(address),\(createdAt),\(updatedAt)\n"
            csvText.append(row)
        }
        
        return saveToFile(csvText, filename: "customers_export_\(dateString()).csv")
    }
    
    // MARK: - Export Tickets to CSV
    
    func exportTicketsToCSV() -> URL? {
        let context = CoreDataManager.shared.viewContext
        let request: NSFetchRequest<Ticket> = Ticket.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Ticket.checkedInAt, ascending: false)]
        
        guard let tickets = try? context.fetch(request) else {
            return nil
        }
        
        var csvText = "Ticket #,Customer,Device Type,Device Model,Issue,Status,Priority,Checked In,Completed,Turnaround (hours)\n"
        
        for ticket in tickets {
            let ticketNumber = ticket.ticketNumber != 0 ? "\(ticket.ticketNumber)" : ""
            let customerName = getCustomerName(for: ticket.customerId)
            let deviceType = escapeCSV(ticket.deviceType ?? "")
            let deviceModel = escapeCSV(ticket.deviceModel ?? "")
            let issue = escapeCSV(ticket.issueDescription ?? "")
            let status = escapeCSV(ticket.status ?? "")
            let priority = escapeCSV(ticket.priority ?? "")
            let checkedIn = ticket.checkedInAt?.formatted(date: .abbreviated, time: .shortened) ?? ""
            let completed = ticket.completedAt?.formatted(date: .abbreviated, time: .shortened) ?? ""
            
            var turnaround = ""
            if let completedAt = ticket.completedAt, let checkedInAt = ticket.checkedInAt {
                let hours = Int(completedAt.timeIntervalSince(checkedInAt) / 3600)
                turnaround = "\(hours)"
            }
            
            let row = "\(ticketNumber),\(customerName),\(deviceType),\(deviceModel),\(issue),\(status),\(priority),\(checkedIn),\(completed),\(turnaround)\n"
            csvText.append(row)
        }
        
        return saveToFile(csvText, filename: "tickets_export_\(dateString()).csv")
    }
    
    // MARK: - Export Queue Status
    
    func exportQueueStatusToCSV() -> URL? {
        let context = CoreDataManager.shared.viewContext
        let request: NSFetchRequest<Ticket> = Ticket.fetchRequest()
        request.predicate = NSPredicate(format: "status == %@ OR status == %@", "waiting", "in_progress")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Ticket.checkedInAt, ascending: true)]
        
        guard let tickets = try? context.fetch(request) else {
            return nil
        }
        
        var csvText = "Ticket #,Customer,Device,Issue,Status,Priority,Wait Time (minutes)\n"
        
        for ticket in tickets {
            let ticketNumber = ticket.ticketNumber != 0 ? "\(ticket.ticketNumber)" : ""
            let customerName = getCustomerName(for: ticket.customerId)
            let device = escapeCSV(ticket.deviceType ?? "")
            let issue = escapeCSV(ticket.issueDescription ?? "")
            let status = escapeCSV(ticket.status ?? "")
            let priority = escapeCSV(ticket.priority ?? "")
            
            var waitTime = ""
            if let checkedIn = ticket.checkedInAt {
                let minutes = Int(Date().timeIntervalSince(checkedIn) / 60)
                waitTime = "\(minutes)"
            }
            
            let row = "\(ticketNumber),\(customerName),\(device),\(issue),\(status),\(priority),\(waitTime)\n"
            csvText.append(row)
        }
        
        return saveToFile(csvText, filename: "queue_status_\(dateString()).csv")
    }
    
    // MARK: - Helper Methods
    
    private func escapeCSV(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }
    
    private func saveToFile(_ content: String, filename: String) -> URL? {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(filename)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error saving CSV: \(error)")
            return nil
        }
    }
    
    private func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        return formatter.string(from: Date())
    }
    
    private func getCustomerName(for customerId: UUID?) -> String {
        guard let customerId = customerId else { return "" }
        
        let context = CoreDataManager.shared.viewContext
        let request: NSFetchRequest<Customer> = Customer.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", customerId as CVarArg)
        request.fetchLimit = 1
        
        if let customer = try? context.fetch(request).first {
            let firstName = customer.firstName ?? ""
            let lastName = customer.lastName ?? ""
            return escapeCSV("\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces))
        }
        
        return ""
    }
}
