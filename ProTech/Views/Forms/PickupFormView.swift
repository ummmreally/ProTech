//
//  PickupFormView.swift
//  ProTech
//
//  Device pickup and completion form
//

import SwiftUI
import CoreData

struct PickupFormView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var ticket: Ticket
    @FetchRequest var customer: FetchedResults<Customer>
    
    @State private var repairCompleted = true
    @State private var workPerformed = ""
    @State private var partsReplaced: [String] = []
    @State private var finalCost = ""
    @State private var paymentMethod = "Cash"
    @State private var paymentReceived = false
    @State private var deviceTested = false
    @State private var customerSatisfied = true
    @State private var warrantyPeriod = 30
    @State private var warrantyNotes = ""
    @State private var customerSignature: UIImage?
    @State private var showingSignaturePad = false
    @State private var additionalNotes = ""
    @State private var followUpRequired = false
    @State private var followUpDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var showingSuccess = false
    
    private let paymentMethods = ["Cash", "Credit Card", "Debit Card", "Check", "Venmo", "PayPal", "Zelle", "Other"]
    private let commonParts = ["Screen", "Battery", "Charging Port", "Camera", "Speaker", "Microphone", "Home Button", "Power Button", "Logic Board", "Back Glass"]
    
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
                // Customer Info
                customerInfoSection
                
                // Repair Summary
                repairSummarySection
                
                // Parts & Work
                partsWorkSection
                
                // Payment
                paymentSection
                
                // Quality Check
                qualityCheckSection
                
                // Warranty
                warrantySection
                
                // Follow-up
                followUpSection
                
                // Signature
                signatureSection
            }
            .formStyle(.grouped)
            .navigationTitle("Device Pickup Form")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Complete Pickup") {
                        completePickup()
                    }
                    .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showingSignaturePad) {
                SignaturePadView(signature: $customerSignature)
            }
            .alert("Pickup Complete", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Device has been marked as picked up.")
            }
        }
        .frame(width: 700, height: 800)
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
    
    private var repairSummarySection: some View {
        Section("Repair Summary") {
            Toggle("Repair Completed Successfully", isOn: $repairCompleted)
            
            if !repairCompleted {
                TextEditor(text: $additionalNotes)
                    .frame(minHeight: 60)
                    .overlay(alignment: .topLeading) {
                        if additionalNotes.isEmpty {
                            Text("Explain why repair was not completed...")
                                .foregroundColor(.secondary)
                                .padding(8)
                                .allowsHitTesting(false)
                        }
                    }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Work Performed:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextEditor(text: $workPerformed)
                    .frame(minHeight: 80)
                    .overlay(alignment: .topLeading) {
                        if workPerformed.isEmpty {
                            Text("Describe the work performed...")
                                .foregroundColor(.secondary)
                                .padding(8)
                                .allowsHitTesting(false)
                        }
                    }
            }
        }
    }
    
    private var partsWorkSection: some View {
        Section("Parts Replaced") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Select parts that were replaced:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(commonParts, id: \.self) { part in
                        Toggle(part, isOn: Binding(
                            get: { partsReplaced.contains(part) },
                            set: { isOn in
                                if isOn {
                                    partsReplaced.append(part)
                                } else {
                                    partsReplaced.removeAll { $0 == part }
                                }
                            }
                        ))
                        .toggleStyle(.checkbox)
                    }
                }
            }
            
            if !partsReplaced.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("\(partsReplaced.count) part(s) replaced")
                        .font(.caption)
                }
            }
        }
    }
    
    private var paymentSection: some View {
        Section("Payment") {
            TextField("Final Cost", text: $finalCost, prompt: Text("$0.00"))
                .help("Total amount charged")
            
            Picker("Payment Method", selection: $paymentMethod) {
                ForEach(paymentMethods, id: \.self) { method in
                    Text(method).tag(method)
                }
            }
            
            Toggle("Payment Received", isOn: $paymentReceived)
            
            if !paymentReceived {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Payment must be received before device pickup")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
    }
    
    private var qualityCheckSection: some View {
        Section("Quality Check") {
            Toggle("Device Tested & Working", isOn: $deviceTested)
            
            Toggle("Customer Satisfied", isOn: $customerSatisfied)
            
            if !customerSatisfied {
                TextEditor(text: $additionalNotes)
                    .frame(minHeight: 60)
                    .overlay(alignment: .topLeading) {
                        if additionalNotes.isEmpty {
                            Text("Note customer concerns...")
                                .foregroundColor(.secondary)
                                .padding(8)
                                .allowsHitTesting(false)
                        }
                    }
            }
        }
    }
    
    private var warrantySection: some View {
        Section("Warranty") {
            Stepper("Warranty Period: \(warrantyPeriod) days", value: $warrantyPeriod, in: 0...365, step: 30)
            
            if warrantyPeriod > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Warranty Expires:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let expiryDate = Calendar.current.date(byAdding: .day, value: warrantyPeriod, to: Date()) {
                        Text(expiryDate, format: .dateTime.month().day().year())
                            .font(.body)
                            .bold()
                    }
                }
            }
            
            TextEditor(text: $warrantyNotes)
                .frame(minHeight: 60)
                .overlay(alignment: .topLeading) {
                    if warrantyNotes.isEmpty {
                        Text("Warranty terms and conditions...")
                            .foregroundColor(.secondary)
                            .padding(8)
                            .allowsHitTesting(false)
                    }
                }
        }
    }
    
    private var followUpSection: some View {
        Section("Follow-up") {
            Toggle("Follow-up Required", isOn: $followUpRequired)
            
            if followUpRequired {
                DatePicker("Follow-up Date", selection: $followUpDate, in: Date()..., displayedComponents: .date)
                
                TextEditor(text: $additionalNotes)
                    .frame(minHeight: 60)
                    .overlay(alignment: .topLeading) {
                        if additionalNotes.isEmpty {
                            Text("Follow-up notes...")
                                .foregroundColor(.secondary)
                                .padding(8)
                                .allowsHitTesting(false)
                        }
                    }
            }
        }
    }
    
    private var signatureSection: some View {
        Section("Customer Signature") {
            if let signature = customerSignature {
                VStack(spacing: 8) {
                    Image(nsImage: signature)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    
                    Button("Clear Signature") {
                        customerSignature = nil
                    }
                    .foregroundColor(.red)
                }
            } else {
                Button {
                    showingSignaturePad = true
                } label: {
                    HStack {
                        Image(systemName: "signature")
                        Text("Customer Signature Required *")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            
            Text("By signing, customer acknowledges receipt of device in working condition and agrees to warranty terms.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Validation & Methods
    
    private var isValid: Bool {
        !workPerformed.isEmpty &&
        !finalCost.isEmpty &&
        paymentReceived &&
        deviceTested &&
        customerSignature != nil
    }
    
    private func loadTicketData() {
        // Pre-fill from ticket
        if let notes = ticket.notes {
            // Parse any existing data
        }
        
        // Set default work performed from issue
        if let issue = ticket.issueDescription {
            workPerformed = "Repaired: \(issue)"
        }
    }
    
    private func completePickup() {
        // Update ticket
        ticket.status = "picked_up"
        ticket.pickedUpAt = Date()
        ticket.updatedAt = Date()
        
        // Add pickup notes
        var pickupNotes = "\n\n=== PICKUP FORM ===\n"
        pickupNotes += "Completed: \(repairCompleted ? "Yes" : "No")\n"
        pickupNotes += "Work Performed: \(workPerformed)\n"
        if !partsReplaced.isEmpty {
            pickupNotes += "Parts Replaced: \(partsReplaced.joined(separator: ", "))\n"
        }
        pickupNotes += "Final Cost: \(finalCost)\n"
        pickupNotes += "Payment: \(paymentMethod) - \(paymentReceived ? "Received" : "Pending")\n"
        pickupNotes += "Device Tested: \(deviceTested ? "Yes" : "No")\n"
        pickupNotes += "Customer Satisfied: \(customerSatisfied ? "Yes" : "No")\n"
        pickupNotes += "Warranty: \(warrantyPeriod) days\n"
        if !warrantyNotes.isEmpty {
            pickupNotes += "Warranty Notes: \(warrantyNotes)\n"
        }
        if followUpRequired {
            pickupNotes += "Follow-up: \(followUpDate.formatted(date: .abbreviated, time: .omitted))\n"
        }
        if !additionalNotes.isEmpty {
            pickupNotes += "Additional Notes: \(additionalNotes)\n"
        }
        
        ticket.notes = (ticket.notes ?? "") + pickupNotes
        
        // Save signature as form submission
        if let signatureImage = customerSignature,
           let tiffData = signatureImage.tiffRepresentation {
            let submission = FormSubmission(context: CoreDataManager.shared.viewContext)
            submission.id = UUID()
            submission.templateId = UUID()
            submission.customerId = ticket.customerId
            submission.ticketId = ticket.id
            submission.submittedAt = Date()
            submission.signatureData = tiffData
            
            // Store pickup form data
            let formData: [String: Any] = [
                "type": "pickup",
                "repairCompleted": repairCompleted,
                "workPerformed": workPerformed,
                "partsReplaced": partsReplaced,
                "finalCost": finalCost,
                "paymentMethod": paymentMethod,
                "paymentReceived": paymentReceived,
                "deviceTested": deviceTested,
                "customerSatisfied": customerSatisfied,
                "warrantyPeriod": warrantyPeriod,
                "warrantyNotes": warrantyNotes,
                "followUpRequired": followUpRequired,
                "followUpDate": followUpDate.timeIntervalSince1970
            ]
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: formData),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                submission.dataJSON = jsonString
            }
        }
        
        // Save
        CoreDataManager.shared.save()
        
        showingSuccess = true
    }
}
