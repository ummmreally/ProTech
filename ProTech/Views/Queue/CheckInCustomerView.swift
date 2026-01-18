//
//  CheckInCustomerView.swift
//  ProTech
//
//  Check in a customer to the service queue
//

import SwiftUI
import CoreData
import AppKit

struct CheckInCustomerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Customer.lastName, ascending: true)]
    ) private var customers: FetchedResults<Customer>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DeviceModel.releaseYear, ascending: false)]
    ) private var deviceModels: FetchedResults<DeviceModel>
    
    @State private var selectedCustomer: Customer?
    @State private var checkInDate = Date()
    @State private var phoneNumber = ""
    @State private var emailAddress = ""
    @State private var streetAddress = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zipCode = ""
    @State private var deviceModel = ""
    @State private var deviceSerialNumber = ""
    @State private var issueDescription = ""
    @State private var additionalDetails = ""
    @State private var allowTextPromotions = false
    @State private var allowMailPromotions = false
    @State private var allowEmailPromotions = false
    @State private var hasDataBackup = false
    @State private var devicePasscode = ""
    @State private var findMyDisabled = false
    @State private var alternateContactName = ""
    @State private var alternateContactNumber = ""
    // Signature is now physical only
    @State private var searchText = ""
    @State private var showingNewCustomer = false
    @State private var showingPrintDialog = false
    @State private var createdTicket: Ticket?
    @State private var selectedDeviceFamily = "iPhone"

    private let deviceFamilies = ["iPhone", "iPad", "Mac", "Watch"]
    
    // Checklist State
    @State private var checklistScreenDamaged = false
    @State private var checklistWaterDamage = false
    @State private var checklistPowerButton = true
    @State private var checklistVolumeButtons = true
    @State private var checklistCamera = true
    @State private var checklistCharging = true
    @State private var checklistBiometrics = true
    
    private let agreementText = """
    By signing this document customer agrees to allow Tech Medics to perform service on listed device above. Customer understands that Tech Medics is not responsible for any data loss that may occur while in possession of the device listed. Tech Medics will contact you 3 times within a 30 day period when the device is ready for pickup. After the 31st day if full balance is unpaid the device will be marked abandoned. Tech Medics will then take ownership of the device or the device may be recycled. Please sign below agreeing to these terms.
    """
    
    var filteredCustomers: [Customer] {
        if searchText.isEmpty {
            return Array(customers)
        } else {
            return customers.filter { customer in
                (customer.firstName?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (customer.lastName?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (customer.phone?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (customer.email?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }

    private var filteredDeviceModels: [DeviceModel] {
        deviceModels.filter { $0.type == selectedDeviceFamily }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                customerSelectionSection
                
                if let selectedCustomer = selectedCustomer {
                    // Loyalty Program Widget
                    Section {
                        LoyaltyWidget(customer: selectedCustomer)
                    }
                    
                    customerInformationSection
                    deviceInformationSection
                    intakeChecklistSection
                    promotionsSection
                    dataSecuritySection
                    alternateContactSection
                    agreementSection
                } else {
                    Section {
                        Text("Select a customer to continue filling out the service request sheet.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Service Request Sheet")
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
        .frame(width: 650, height: 820)
        .sheet(isPresented: $showingNewCustomer) {
            AddCustomerView(
                onSave: { customer in
                    selectedCustomer = customer
                    searchText = "\(customer.firstName ?? "") \(customer.lastName ?? "")"
                    populateCustomerDetails(from: customer)
                },
                onCancel: {
                    showingNewCustomer = false
                }
            )
        }
        .sheet(isPresented: $showingPrintDialog) {
            if let ticket = createdTicket, let customer = selectedCustomer {
                CheckInPrintDialog(
                    ticket: ticket,
                    customer: customer,
                    onDismiss: {
                        showingPrintDialog = false
                        dismiss()
                    }
                )
            }
        }
        .onChange(of: selectedCustomer?.objectID) {
            if let customer = selectedCustomer {
                populateCustomerDetails(from: customer)
            }
        }
        .onAppear {
            checkInDate = Date()
        }
    }
    
    private var isValid: Bool {
        guard selectedCustomer != nil else { return false }
        return !deviceModel.trimmingCharacters(in: .whitespaces).isEmpty &&
            !issueDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Sections
    
    private var customerSelectionSection: some View {
        Section("Customer") {
            HStack {
                TextField("Search customer...", text: $searchText)
                
                Button {
                    showingNewCustomer = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .buttonStyle(.borderless)
                .help("Add a new customer")
            }
            
            if searchText.isEmpty && selectedCustomer == nil {
                Text("Type to search for a customer")
                    .foregroundColor(.secondary)
                    .font(.caption)
            } else if !filteredCustomers.isEmpty {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(filteredCustomers.prefix(6)) { customer in
                            Button {
                                selectedCustomer = customer
                                searchText = "\(customer.firstName ?? "") \(customer.lastName ?? "")"
                                populateCustomerDetails(from: customer)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(customer.firstName ?? "") \(customer.lastName ?? "")")
                                            .font(.body)
                                        if let phone = customer.phone, !phone.isEmpty {
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
                .frame(maxHeight: 220)
            } else if !searchText.isEmpty {
                Text("No customers match your search")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
    }
    
    private var customerInformationSection: some View {
        Section("Customer Information") {
            if let customer = selectedCustomer {
                LabeledContent("Full Name") {
                    Text("\(customer.firstName ?? "") \(customer.lastName ?? "")")
                }
            }
            
            LabeledContent("Date") {
                DatePicker("", selection: $checkInDate, displayedComponents: .date)
                    .disabled(true)
                    .labelsHidden()
            }
            .padding(.top, 4)
            
            TextField("Phone Number", text: $phoneNumber)
            TextField("Email", text: $emailAddress)
            TextField("Address", text: $streetAddress)
            HStack {
                TextField("City", text: $city)
                TextField("State", text: $state)
                    .frame(width: 60)
                TextField("Zip", text: $zipCode)
                    .frame(width: 80)
            }
        }
    }
    
    private var deviceInformationSection: some View {
        Section("Device Information") {
            Picker("Device Family", selection: $selectedDeviceFamily) {
                ForEach(deviceFamilies, id: \.self) { family in
                    Text(family).tag(family)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedDeviceFamily) {
                deviceModel = ""
            }

            Picker("Device Model", selection: $deviceModel) {
                Text("Select...").tag("")
                ForEach(filteredDeviceModels) { device in
                    Text(device.name ?? "Unknown Device")
                        .tag(device.name ?? "")
                }
            }
            .pickerStyle(.menu)

            TextField("Device Serial Number", text: $deviceSerialNumber)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Issue with device")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $issueDescription)
                        .frame(minHeight: 90)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .background(Color(nsColor: .textBackgroundColor))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    
                    if issueDescription.isEmpty {
                        Text("Describe the issue... *")
                            .foregroundColor(.secondary)
                            .padding(8)
                            .allowsHitTesting(false)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Additional Details About Repair")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $additionalDetails)
                        .frame(minHeight: 80)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .background(Color(nsColor: .textBackgroundColor))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    
                    if additionalDetails.isEmpty {
                        Text("Add any extra notes or observations")
                            .foregroundColor(.secondary)
                            .padding(8)
                            .allowsHitTesting(false)
                    }
                }
            }
            .padding(.top, 4)
        }
    }
    


    
    private var intakeChecklistSection: some View {
        Section("Intake Checklist") {
            Toggle("Screen Cracked / Damaged", isOn: $checklistScreenDamaged)
            Toggle("Water Damage Indicators", isOn: $checklistWaterDamage)
            Toggle("Power Button Functional", isOn: $checklistPowerButton)
            Toggle("Volume Buttons Functional", isOn: $checklistVolumeButtons)
            Toggle("Camera Functional", isOn: $checklistCamera)
            Toggle("Charging Port Functional", isOn: $checklistCharging)
            Toggle("Touch/Face ID Functional", isOn: $checklistBiometrics)
        }
    }
    
    private var promotionsSection: some View {
        Section("Promotions") {
            yesNoPicker(title: "Text Message Promotions", selection: $allowTextPromotions)
            yesNoPicker(title: "Mailing Promotions", selection: $allowMailPromotions)
            yesNoPicker(title: "Email Promotions", selection: $allowEmailPromotions)
        }
    }
    
    private var dataSecuritySection: some View {
        Section("Data & Security") {
            yesNoPicker(title: "Do you have a backup of your data?", selection: $hasDataBackup)
            TextField("Device passcode", text: $devicePasscode)
            yesNoPicker(title: "Have you disabled Find My iPhone?", selection: $findMyDisabled)
        }
    }
    
    private var alternateContactSection: some View {
        Section("Alternative Contact") {
            TextField("Contact Name", text: $alternateContactName)
            TextField("Contact Number", text: $alternateContactNumber)
        }
    }
    
    private var agreementSection: some View {
        Section("Agreement & Signature") {
            Text(agreementText)
                .font(.footnote)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 4)
            
            Text("Please print the service sheet for customer signature.")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
        }
    }
    
    private func checkInCustomer() {
        guard let customer = selectedCustomer else { return }
        
        // Generate ticket number
        let ticketNumber = generateTicketNumber()
        
        // Create ticket
        let ticket = Ticket(context: viewContext)
        ticket.id = UUID()
        ticket.ticketNumber = ticketNumber
        
        // Ensure we preserve the customer ID or generate a new one if somehow nil
        let customerId = customer.id ?? UUID()
        if customer.id == nil { customer.id = customerId }
        ticket.customerId = customerId
        ticket.deviceType = selectedDeviceFamily
        let trimmedModel = deviceModel.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSerial = deviceSerialNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedIssue = issueDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDetails = additionalDetails.trimmingCharacters(in: .whitespacesAndNewlines)
        ticket.deviceModel = trimmedModel.isEmpty ? nil : trimmedModel
        ticket.deviceSerialNumber = trimmedSerial.isEmpty ? nil : trimmedSerial
        ticket.issueDescription = trimmedIssue
        ticket.additionalRepairDetails = trimmedDetails.isEmpty ? nil : trimmedDetails
        ticket.status = "waiting"
        ticket.priority = Priority.normal.rawValue
        ticket.checkedInAt = checkInDate
        ticket.estimatedCompletion = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        ticket.createdAt = Date()
        ticket.updatedAt = Date()
        ticket.marketingOptInSMS = allowTextPromotions
        ticket.marketingOptInMail = allowMailPromotions
        ticket.marketingOptInEmail = allowEmailPromotions
        ticket.hasDataBackup = hasDataBackup
        let trimmedPasscode = devicePasscode.trimmingCharacters(in: .whitespacesAndNewlines)
        ticket.devicePasscode = trimmedPasscode.isEmpty ? nil : trimmedPasscode
        ticket.findMyDisabled = findMyDisabled
        let trimmedAltName = alternateContactName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAltNumber = alternateContactNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        ticket.alternateContactName = trimmedAltName.isEmpty ? nil : trimmedAltName
        ticket.alternateContactNumber = trimmedAltNumber.isEmpty ? nil : trimmedAltNumber
        ticket.checkInSignature = nil
        ticket.checkInAgreedAt = Date()
        
        // Update customer record with any new info
        let trimmedPhone = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = emailAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Construct full address
        var addressComponents: [String] = []
        let trimmedStreet = streetAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCity = city.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedState = state.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedZip = zipCode.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !trimmedStreet.isEmpty { addressComponents.append(trimmedStreet) }
        var cityStateZip = ""
        if !trimmedCity.isEmpty { cityStateZip += trimmedCity }
        if !trimmedState.isEmpty { cityStateZip += (cityStateZip.isEmpty ? "" : ", ") + trimmedState }
        if !trimmedZip.isEmpty { cityStateZip += (cityStateZip.isEmpty ? "" : " ") + trimmedZip }
        if !cityStateZip.isEmpty { addressComponents.append(cityStateZip) }
        
        let fullAddress = addressComponents.joined(separator: ", ")
        
        customer.phone = trimmedPhone.isEmpty ? nil : trimmedPhone
        customer.email = trimmedEmail.isEmpty ? nil : trimmedEmail
        customer.address = fullAddress.isEmpty ? nil : fullAddress
        customer.updatedAt = Date()
        
        // Append summary to ticket notes
        var intakeNotes = "\n\n=== SERVICE REQUEST SHEET ===\n"
        intakeNotes += "Device Model: \(deviceModel)\n"
        if !deviceSerialNumber.isEmpty {
            intakeNotes += "Serial Number: \(deviceSerialNumber)\n"
        }
        intakeNotes += "Issue: \(trimmedIssue)\n"
        if !trimmedDetails.isEmpty {
            intakeNotes += "Additional Details: \(trimmedDetails)\n"
        }
        intakeNotes += "Text Promotions: \(allowTextPromotions ? "Yes" : "No")\n"
        intakeNotes += "Mail Promotions: \(allowMailPromotions ? "Yes" : "No")\n"
        intakeNotes += "Email Promotions: \(allowEmailPromotions ? "Yes" : "No")\n"
        intakeNotes += "Has Data Backup: \(hasDataBackup ? "Yes" : "No")\n"
        intakeNotes += "Find My Disabled: \(findMyDisabled ? "Yes" : "No")\n"
        if !devicePasscode.isEmpty {
            intakeNotes += "Device Passcode: \(devicePasscode)\n"
        }
        if !alternateContactName.isEmpty {
            intakeNotes += "Alternate Contact: \(alternateContactName) - \(alternateContactNumber)\n"
        }
        ticket.notes = (ticket.notes ?? "") + intakeNotes
        
        // Persist form submission (without signature)
        let submission = FormSubmission(context: viewContext)
        submission.id = UUID()
        submission.formID = ticket.id
        submission.submittedAt = Date()
        submission.signatureData = nil
        
        let formData: [String: Any] = [
            "type": "checkin",
            "ticketId": ticket.id?.uuidString ?? "",
            "customerId": ticket.customerId?.uuidString ?? "",
            "fullName": "\(customer.firstName ?? "") \(customer.lastName ?? "")",
            "date": checkInDate.timeIntervalSince1970,
            "phoneNumber": trimmedPhone,
            "email": trimmedEmail,
            "address": fullAddress,
            "deviceModel": trimmedModel,
            "deviceSerialNumber": trimmedSerial,
            "issueDescription": trimmedIssue,
            "additionalDetails": trimmedDetails,
            "textPromotions": allowTextPromotions,
            "mailPromotions": allowMailPromotions,
            "emailPromotions": allowEmailPromotions,
            "hasDataBackup": hasDataBackup,
            "devicePasscode": trimmedPasscode,
            "findMyDisabled": findMyDisabled,
            "alternateContactName": trimmedAltName,
            "alternateContactNumber": trimmedAltNumber,
            "agreementText": agreementText,
            "isPhysicalSignature": true
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: formData, options: [.sortedKeys]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            submission.dataJSON = jsonString
        }
        
        // Save Checklist Responses
        let checklistItems: [(String, Bool)] = [
            ("Screen Cracked", checklistScreenDamaged), // True = Damage
            ("Water Damage", checklistWaterDamage),     // True = Damage
            ("Power Button", checklistPowerButton),     // True = Functional
            ("Volume Buttons", checklistVolumeButtons), // True = Functional
            ("Camera", checklistCamera),                 // True = Functional
            ("Charging Port", checklistCharging),        // True = Functional
            ("Biometrics", checklistBiometrics)          // True = Functional
        ]
        
        for (item, value) in checklistItems {
            let response = ChecklistResponse(context: viewContext)
            response.id = UUID()
            response.ticketId = ticket.id
            response.category = "intake"
            response.item = item
            response.isPassed = value // Note: Meaning depends on question (Good vs Bad)
            response.createdAt = Date()
            response.checkedBy = "Intake"
        }
        
        // Save
        CoreDataManager.shared.save()
        
        // Store ticket for printing
        createdTicket = ticket
        
        // Show print dialog
        showingPrintDialog = true
    }
    
    private func populateCustomerDetails(from customer: Customer) {
        phoneNumber = customer.phone ?? ""
        emailAddress = customer.email ?? ""
        streetAddress = customer.address ?? "" // Basic fallback for now
        city = ""
        state = ""
        zipCode = ""
    }
    
    private func yesNoPicker(title: String, selection: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
            Picker(title, selection: selection) {
                Text("Yes").tag(true)
                Text("No").tag(false)
            }
            .pickerStyle(.segmented)
        }
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
