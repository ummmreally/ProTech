//
//  PickupFormView.swift
//  ProTech
//
//  Device pickup and completion form
//

import SwiftUI
import CoreData
import AppKit

struct PickupFormView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var ticket: Ticket
    @FetchRequest var customer: FetchedResults<Customer>
    
    @State private var repairCompleted = true
    @State private var technicianName = ""
    @State private var completionDate = Date()
    @State private var customerSignatureData: Data?
    @State private var showingSignaturePad = false
    @State private var serviceNotes = ""
    @State private var showingSuccess = false
    @State private var shouldPrint = false
    @State private var savedSubmission: FormSubmission?
    
    private let completionAgreement = """
    By signing this document customer agrees that Tech Medics has completed the service(s) listed for the device(s) above. Customer understands that Tech Medics is not responsible for any data loss that may have occurred while in possession of the device(s). Tech Medics will warranty work performed on the device(s) listed above for 30 days from the day of pickup. This warranty does not cover accidental damage caused by the customer to the serviced part or device listed.
    """
    
    init(ticket: Ticket) {
        self.ticket = ticket
        _customer = FetchRequest<Customer>(
            sortDescriptors: [],
            predicate: NSPredicate(format: "id == %@", ticket.customerId! as CVarArg)
        )
    }
    
    var body: some View {
        NavigationStack {
            Form {
                customerInfoSection
                completionDetailsSection
                notesSection
                agreementSection
                signatureSection
            }
            .formStyle(.grouped)
            .navigationTitle("Service Completion Form")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Menu {
                        Button("Complete Pickup") {
                            completePickup()
                        }
                        Button("Complete & Print") {
                            completeAndPrint()
                        }
                    } label: {
                        Label("Complete", systemImage: "checkmark.circle.fill")
                    }
                    .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showingSignaturePad) {
                SignaturePadView(signatureData: $customerSignatureData)
            }
            .alert("Pickup Complete", isPresented: $showingSuccess) {
                Button("OK") {
                    if shouldPrint, let submission = savedSubmission {
                        printForm(submission: submission)
                    }
                    dismiss()
                }
            } message: {
                Text("Device has been marked as picked up.")
            }
        }
        .frame(width: 650, height: 700)
        .onAppear {
            loadTicketData()
        }
    }
    
    // MARK: - Sections
    
    private var customerInfoSection: some View {
        Section("Customer Information") {
            if let customer = customer.first {
                LabeledContent("Name") {
                    Text("\(customer.firstName ?? "") \(customer.lastName ?? "")")
                }
                if let phone = customer.phone {
                    LabeledContent("Phone") {
                        Text(phone)
                    }
                }
            }
            
            if let device = ticket.deviceType {
                LabeledContent("Device") {
                    Text("\(device) - \(ticket.deviceModel ?? "")")
                }
            }
            
            if ticket.ticketNumber != 0 {
                LabeledContent("Ticket #") {
                    Text("\(ticket.ticketNumber)")
                        .bold()
                }
            }
        }
    }
    
    private var completionDetailsSection: some View {
        Section("Service Completion") {
            LabeledContent("Completion Date") {
                DatePicker("", selection: $completionDate, displayedComponents: .date)
                    .labelsHidden()
            }
            .padding(.top, 4)
            
            TextField("Technician Name", text: $technicianName)
            
            Toggle("Repair Completed Successfully", isOn: $repairCompleted)
        }
    }
    
    private var notesSection: some View {
        Section("Service Notes") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Details about service performed")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextEditor(text: $serviceNotes)
                    .frame(minHeight: 120)
                    .overlay(alignment: .topLeading) {
                        if serviceNotes.isEmpty {
                            Text("Enter notes about the repair and service performed...")
                                .foregroundColor(.secondary)
                                .padding(8)
                                .allowsHitTesting(false)
                        }
                    }
            }
        }
    }
    
    private var agreementSection: some View {
        Section("Agreement") {
            Text(completionAgreement)
                .font(.footnote)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 4)
        }
    }
    
    private var signatureSection: some View {
        Section("Customer Signature") {
            if let signatureData = customerSignatureData,
               let signature = NSImage(data: signatureData) {
                VStack(spacing: 8) {
                    Image(nsImage: signature)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    
                    Button("Clear Signature") {
                        customerSignatureData = nil
                    }
                    .foregroundColor(.red)
                    .buttonStyle(.borderless)
                }
            } else {
                Button {
                    showingSignaturePad = true
                } label: {
                    HStack {
                        Image(systemName: "signature")
                        Text("Capture Customer Signature *")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Validation & Methods
    
    private var isValid: Bool {
        !technicianName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !serviceNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        customerSignatureData != nil
    }
    
    private func loadTicketData() {
        completionDate = Date()
        // Pre-populate service notes from ticket issue
        if let issue = ticket.issueDescription {
            serviceNotes = "Repaired: \(issue)"
        }
    }
    
    private func completeAndPrint() {
        shouldPrint = true
        completePickup()
    }
    
    private func completePickup() {
        let trimmedTechnician = technicianName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = serviceNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Update ticket
        ticket.status = "picked_up"
        ticket.pickedUpAt = completionDate
        ticket.updatedAt = Date()
        
        // Add pickup notes
        var pickupNotes = "\n\n=== SERVICE COMPLETION FORM ===\n"
        pickupNotes += "Completion Date: \(completionDate.formatted(date: .long, time: .omitted))\n"
        pickupNotes += "Technician: \(trimmedTechnician)\n"
        pickupNotes += "Repair Completed: \(repairCompleted ? "Yes" : "No")\n"
        pickupNotes += "Service Notes: \(trimmedNotes)\n"
        pickupNotes += "Customer Signature: Captured\n"
        
        ticket.notes = (ticket.notes ?? "") + pickupNotes
        
        // Save signature and form submission
        if let signatureData = customerSignatureData {
            let submission = FormSubmission(context: CoreDataManager.shared.viewContext)
            submission.id = UUID()
            submission.formID = ticket.id
            submission.submittedAt = Date()
            submission.signatureData = signatureData
            
            let formData: [String: Any] = [
                "type": "pickup",
                "ticketId": ticket.id?.uuidString ?? "",
                "customerId": ticket.customerId?.uuidString ?? "",
                "completionDate": completionDate.timeIntervalSince1970,
                "technicianName": trimmedTechnician,
                "repairCompleted": repairCompleted,
                "serviceNotes": trimmedNotes,
                "agreementText": completionAgreement
            ]
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: formData, options: [.sortedKeys]),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                submission.dataJSON = jsonString
            }
            
            savedSubmission = submission
        }
        
        // Save
        CoreDataManager.shared.save()
        
        showingSuccess = true
    }
    
    private func printForm(submission: FormSubmission) {
        // Get default pickup template
        let fetchRequest = FormTemplate.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "type == %@ AND isDefault == true", "pickup")
        fetchRequest.fetchLimit = 1
        
        if let template = try? CoreDataManager.shared.viewContext.fetch(fetchRequest).first {
            FormService.shared.printFormDirectly(submission: submission, template: template)
        }
    }
}
