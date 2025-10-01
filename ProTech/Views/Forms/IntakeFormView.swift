//
//  IntakeFormView.swift
//  ProTech
//
//  Comprehensive device intake form with signature
//

import SwiftUI
import CoreData
import AppKit

struct IntakeFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    let customer: Customer
    let ticket: Ticket?
    
    @State private var deviceType = ""
    @State private var deviceBrand = ""
    @State private var deviceModel = ""
    @State private var serialNumber = ""
    @State private var imei = ""
    @State private var passcode = ""
    @State private var issueDescription = ""
    @State private var visualCondition = "Good"
    @State private var accessories: Set<String> = []
    @State private var estimatedCost = ""
    @State private var estimatedDays = 3
    @State private var priority: Priority = .normal
    @State private var warrantyStatus = "No Warranty"
    @State private var previousRepairs = false
    @State private var previousRepairDetails = ""
    @State private var dataBackedUp = false
    @State private var findMyDeviceDisabled = false
    @State private var customerSignature: NSImage?
    @State private var technicianNotes = ""
    @State private var agreedToTerms = false
    @State private var showingSignaturePad = false
    @State private var showingSuccess = false
    
    private let deviceTypes = ["iPhone", "iPad", "Mac", "MacBook", "iMac", "Apple Watch", "AirPods", "Android Phone", "Android Tablet", "PC Laptop", "PC Desktop", "Other"]
    private let conditions = ["Excellent", "Good", "Fair", "Poor", "Damaged"]
    private let warrantyOptions = ["No Warranty", "Apple Care", "Manufacturer Warranty", "Extended Warranty", "Unknown"]
    private let accessoryOptions = ["Charger", "Cable", "Case", "Screen Protector", "SIM Card", "Memory Card", "Stylus", "Keyboard", "Mouse"]
    
    var body: some View {
        NavigationStack {
            Form {
                // Device Information
                deviceInformationSection
                
                // Issue Details
                issueDetailsSection
                
                // Condition & Accessories
                conditionSection
                
                // Repair Details
                repairDetailsSection
                
                // Customer Checklist
                customerChecklistSection
                
                // Signature
                signatureSection
                
                // Terms & Agreement
                termsSection
            }
            .formStyle(.grouped)
            .navigationTitle("Device Intake Form")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        submitForm()
                    }
                    .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showingSignaturePad) {
                SignaturePadView(signature: $customerSignature)
            }
            .alert("Form Submitted", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Intake form has been saved successfully.")
            }
        }
        .frame(width: 700, height: 800)
    }
    
    // MARK: - Sections
    
    private var deviceInformationSection: some View {
        Section("Device Information") {
            Picker("Device Type *", selection: $deviceType) {
                Text("Select device").tag("")
                ForEach(deviceTypes, id: \.self) { type in
                    Text(type).tag(type)
                }
            }
            
            TextField("Brand", text: $deviceBrand, prompt: Text("Apple, Samsung, etc."))
            TextField("Model *", text: $deviceModel, prompt: Text("iPhone 14 Pro, Galaxy S23, etc."))
            TextField("Serial Number", text: $serialNumber)
            TextField("IMEI (if applicable)", text: $imei)
            SecureField("Passcode/PIN", text: $passcode)
                .help("Required to test device functionality")
        }
    }
    
    private var issueDetailsSection: some View {
        Section("Issue Description") {
            TextEditor(text: $issueDescription)
                .frame(minHeight: 100)
                .overlay(alignment: .topLeading) {
                    if issueDescription.isEmpty {
                        Text("Describe the problem in detail... *")
                            .foregroundColor(.secondary)
                            .padding(8)
                            .allowsHitTesting(false)
                    }
                }
            
            Toggle("Previous Repairs", isOn: $previousRepairs)
            
            if previousRepairs {
                TextEditor(text: $previousRepairDetails)
                    .frame(minHeight: 60)
                    .overlay(alignment: .topLeading) {
                        if previousRepairDetails.isEmpty {
                            Text("Describe previous repairs...")
                                .foregroundColor(.secondary)
                                .padding(8)
                                .allowsHitTesting(false)
                        }
                    }
            }
        }
    }
    
    private var conditionSection: some View {
        Section("Physical Condition") {
            Picker("Visual Condition", selection: $visualCondition) {
                ForEach(conditions, id: \.self) { condition in
                    Text(condition).tag(condition)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Included Accessories")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(accessoryOptions, id: \.self) { accessory in
                        Toggle(accessory, isOn: Binding(
                            get: { accessories.contains(accessory) },
                            set: { isOn in
                                if isOn {
                                    accessories.insert(accessory)
                                } else {
                                    accessories.remove(accessory)
                                }
                            }
                        ))
                        .toggleStyle(.checkbox)
                    }
                }
            }
        }
    }
    
    private var repairDetailsSection: some View {
        Section("Repair Information") {
            Picker("Priority", selection: $priority) {
                ForEach(Priority.allCases, id: \.self) { priority in
                    HStack {
                        Image(systemName: priority.icon)
                        Text(priority.displayName)
                    }
                    .tag(priority)
                }
            }
            
            TextField("Estimated Cost", text: $estimatedCost, prompt: Text("$0.00"))
                .help("Approximate repair cost")
            
            Stepper("Estimated Days: \(estimatedDays)", value: $estimatedDays, in: 1...30)
            
            Picker("Warranty Status", selection: $warrantyStatus) {
                ForEach(warrantyOptions, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            
            TextEditor(text: $technicianNotes)
                .frame(minHeight: 60)
                .overlay(alignment: .topLeading) {
                    if technicianNotes.isEmpty {
                        Text("Technician notes (internal)...")
                            .foregroundColor(.secondary)
                            .padding(8)
                            .allowsHitTesting(false)
                    }
                }
        }
    }
    
    private var customerChecklistSection: some View {
        Section("Customer Checklist") {
            Toggle("Data Backed Up", isOn: $dataBackedUp)
                .help("Customer confirms data is backed up")
            
            Toggle("Find My Device Disabled", isOn: $findMyDeviceDisabled)
                .help("Required for iOS/Mac devices")
            
            if !dataBackedUp {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Customer should back up data before repair")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            if deviceType.contains("iPhone") || deviceType.contains("iPad") || deviceType.contains("Mac") {
                if !findMyDeviceDisabled {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text("Find My must be disabled to proceed with repair")
                            .font(.caption)
                            .foregroundColor(.red)
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
                        Text("Add Customer Signature *")
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
    
    private var termsSection: some View {
        Section("Terms & Conditions") {
            VStack(alignment: .leading, spacing: 12) {
                Text("By signing this form, the customer agrees to:")
                    .font(.subheadline)
                    .bold()
                
                VStack(alignment: .leading, spacing: 6) {
                    BulletPoint(text: "Authorize the repair work described above")
                    BulletPoint(text: "Pay the estimated cost upon completion")
                    BulletPoint(text: "Accept that data loss may occur during repair")
                    BulletPoint(text: "Understand that parts may be replaced with equivalent parts")
                    BulletPoint(text: "Pick up device within 30 days or storage fees apply")
                }
                .font(.caption)
                
                Toggle("I agree to the terms and conditions *", isOn: $agreedToTerms)
                    .toggleStyle(.checkbox)
            }
        }
    }
    
    // MARK: - Validation & Submission
    
    private var isValid: Bool {
        !deviceType.isEmpty &&
        !deviceModel.isEmpty &&
        !issueDescription.isEmpty &&
        customerSignature != nil &&
        agreedToTerms
    }
    
    private func submitForm() {
        // Create or update ticket
        let newTicket: Ticket
        if let existingTicket = ticket {
            newTicket = existingTicket
        } else {
            newTicket = Ticket(context: viewContext)
            newTicket.id = UUID()
            newTicket.ticketNumber = generateTicketNumber()
            newTicket.customerId = customer.id
            newTicket.checkedInAt = Date()
            newTicket.createdAt = Date()
        }
        
        // Update ticket with form data
        newTicket.deviceType = deviceType
        newTicket.deviceModel = "\(deviceBrand) \(deviceModel)".trimmingCharacters(in: .whitespaces)
        newTicket.issueDescription = issueDescription
        newTicket.status = "waiting"
        newTicket.priority = priority.rawValue
        newTicket.estimatedCompletion = Calendar.current.date(byAdding: .day, value: estimatedDays, to: Date())
        newTicket.updatedAt = Date()
        
        // Create detailed notes
        var notes = "=== INTAKE FORM ===\n"
        notes += "Serial: \(serialNumber)\n"
        if !imei.isEmpty { notes += "IMEI: \(imei)\n" }
        notes += "Condition: \(visualCondition)\n"
        notes += "Warranty: \(warrantyStatus)\n"
        if !accessories.isEmpty {
            notes += "Accessories: \(accessories.joined(separator: ", "))\n"
        }
        if previousRepairs {
            notes += "Previous Repairs: \(previousRepairDetails)\n"
        }
        notes += "Data Backed Up: \(dataBackedUp ? "Yes" : "No")\n"
        notes += "Find My Disabled: \(findMyDeviceDisabled ? "Yes" : "No")\n"
        if !estimatedCost.isEmpty {
            notes += "Estimated Cost: \(estimatedCost)\n"
        }
        if !technicianNotes.isEmpty {
            notes += "\nTechnician Notes:\n\(technicianNotes)\n"
        }
        
        newTicket.notes = notes
        
        // Save signature and form submission
        if let signatureImage = customerSignature,
           let tiffData = signatureImage.tiffRepresentation {
            let submission = FormSubmission(context: viewContext)
            submission.id = UUID()
            submission.formID = newTicket.id
            submission.submittedAt = Date()
            submission.signatureData = tiffData
            
            let formData: [String: Any] = [
                "deviceType": deviceType,
                "deviceBrand": deviceBrand,
                "deviceModel": deviceModel,
                "serialNumber": serialNumber,
                "imei": imei,
                "issueDescription": issueDescription,
                "visualCondition": visualCondition,
                "accessories": Array(accessories),
                "estimatedCost": estimatedCost,
                "estimatedDays": estimatedDays,
                "priority": priority.rawValue,
                "warrantyStatus": warrantyStatus,
                "previousRepairs": previousRepairs,
                "previousRepairDetails": previousRepairDetails,
                "dataBackedUp": dataBackedUp,
                "findMyDeviceDisabled": findMyDeviceDisabled,
                "agreedToTerms": agreedToTerms,
                "customerId": customer.id?.uuidString ?? "",
                "ticketId": newTicket.id?.uuidString ?? ""
            ]
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: formData, options: [.sortedKeys]),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                submission.dataJSON = jsonString
            }
        }
        
        // Save
        CoreDataManager.shared.save()
        
        showingSuccess = true
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
        
        return 1001
    }
}

// MARK: - Bullet Point

struct BulletPoint: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            Text(text)
        }
    }
}

// MARK: - Signature Pad

struct SignaturePadView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var signature: NSImage?
    @State private var currentPath = Path()
    @State private var paths: [Path] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Customer Signature")
                    .font(.headline)
                Spacer()
                Button("Clear") {
                    paths.removeAll()
                    currentPath = Path()
                }
                .disabled(paths.isEmpty && currentPath.isEmpty)
            }
            .padding()
            
            Divider()
            
            // Canvas
            ZStack {
                Rectangle()
                    .fill(Color.white)
                    .border(Color.gray.opacity(0.3), width: 1)
                
                Canvas { context, size in
                    for path in paths {
                        context.stroke(path, with: .color(.black), lineWidth: 2)
                    }
                    context.stroke(currentPath, with: .color(.black), lineWidth: 2)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let point = value.location
                            if currentPath.isEmpty {
                                currentPath.move(to: point)
                            } else {
                                currentPath.addLine(to: point)
                            }
                        }
                        .onEnded { _ in
                            paths.append(currentPath)
                            currentPath = Path()
                        }
                )
                
                if paths.isEmpty && currentPath.isEmpty {
                    Text("Sign here")
                        .foregroundColor(.gray)
                        .allowsHitTesting(false)
                }
            }
            .frame(height: 300)
            .padding()
            
            Divider()
            
            // Footer
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                
                Spacer()
                
                Button("Save Signature") {
                    captureSignature()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(paths.isEmpty)
            }
            .padding()
        }
        .frame(width: 600, height: 450)
    }
    
    private func captureSignature() {
        let renderer = ImageRenderer(content: signatureCanvas)
        renderer.scale = 2.0
        
        if let nsImage = renderer.nsImage {
            signature = nsImage
        }
    }
    
    private var signatureCanvas: some View {
        Canvas { context, size in
            for path in paths {
                context.stroke(path, with: .color(.black), lineWidth: 2)
            }
        }
        .frame(width: 500, height: 250)
        .background(Color.white)
    }
}

extension NSImage {
    convenience init?(cgImage: CGImage) {
        self.init(cgImage: cgImage, size: .zero)
    }
}
