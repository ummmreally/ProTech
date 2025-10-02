import SwiftUI
import AVFoundation

struct BarcodeScannerView: View {
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var scanner = BarcodeScanner()
    @State private var manualInput = ""
    @State private var foundTicket: Ticket?
    @State private var showingTicketDetail = false
    @State private var scanMode: ScanMode = .camera
    
    private let lookupService = BarcodeLookupService.shared
    private let barcodeGenerator = BarcodeGenerator.shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Mode selector
                Picker("Scan Mode", selection: $scanMode) {
                    Text("Camera").tag(ScanMode.camera)
                    Text("Manual Entry").tag(ScanMode.manual)
                    Text("USB Scanner").tag(ScanMode.usb)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content based on mode
                switch scanMode {
                case .camera:
                    cameraView
                case .manual:
                    manualEntryView
                case .usb:
                    usbScannerView
                }
                
                Spacer()
                
                // Results
                if let ticket = foundTicket {
                    ticketResultView(ticket)
                }
                
                if let error = scanner.error {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .navigationTitle("Scan Barcode")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        scanner.stopScanning()
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 700, height: 600)
        .onChange(of: scanner.scannedCode, initial: false) { _, newValue in
            if let barcode = newValue {
                processBarcode(barcode)
            }
        }
        .navigationDestination(isPresented: $showingTicketDetail) {
            if let ticket = foundTicket {
                TicketDetailView(ticket: ticket)
            }
        }
    }
    
    // MARK: - Camera View
    
    private var cameraView: some View {
        VStack {
            if scanner.isCameraAvailable() {
                if scanner.isScanning {
                    Text("Point camera at barcode")
                        .font(.headline)
                        .padding()
                    
                    // Camera preview would go here
                    // Note: In a real implementation, you'd use AVCaptureVideoPreviewLayer
                    Rectangle()
                        .fill(Color.black.opacity(0.8))
                        .frame(height: 300)
                        .overlay(
                            VStack {
                                Image(systemName: "barcode.viewfinder")
                                    .font(.system(size: 60))
                                    .foregroundColor(.white)
                                Text("Scanning...")
                                    .foregroundColor(.white)
                            }
                        )
                        .cornerRadius(12)
                    
                    Button(action: { scanner.stopScanning() }) {
                        Label("Stop Scanning", systemImage: "stop.circle.fill")
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "camera")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("Camera Ready")
                            .font(.headline)
                        
                        Button(action: startCameraScanning) {
                            Label("Start Scanning", systemImage: "camera.fill")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(height: 300)
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "camera.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text("Camera Not Available")
                        .font(.headline)
                    
                    Text("Please use manual entry or USB scanner")
                        .foregroundColor(.secondary)
                }
                .frame(height: 300)
            }
        }
        .padding()
    }
    
    // MARK: - Manual Entry View
    
    private var manualEntryView: some View {
        VStack(spacing: 20) {
            Image(systemName: "keyboard")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Enter Barcode Manually")
                .font(.headline)
            
            TextField("Ticket number or barcode", text: $manualInput)
                .textFieldStyle(.roundedBorder)
                .font(.system(.title3, design: .monospaced))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: processManualInput) {
                Label("Look Up", systemImage: "magnifyingglass")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .disabled(manualInput.isEmpty)
        }
        .frame(height: 300)
        .padding()
    }
    
    // MARK: - USB Scanner View
    
    private var usbScannerView: some View {
        VStack(spacing: 20) {
            Image(systemName: "barcode")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("USB Scanner Ready")
                .font(.headline)
            
            Text("Scan a barcode with your USB scanner")
                .foregroundColor(.secondary)
            
            TextField("Waiting for scan...", text: $manualInput)
                .textFieldStyle(.roundedBorder)
                .font(.system(.title3, design: .monospaced))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .disabled(true)
        }
        .frame(height: 300)
        .padding()
        .onReceive(NotificationCenter.default.publisher(for: NSControl.textDidChangeNotification)) { notification in
            if let textField = notification.object as? NSTextField {
                let input = textField.stringValue
                if input.hasSuffix("\n") || input.hasSuffix("\r") {
                    let cleanedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !cleanedInput.isEmpty {
                        scanner.processUSBScannerInput(cleanedInput)
                        textField.stringValue = ""
                    }
                }
            }
        }
    }
    
    // MARK: - Ticket Result View
    
    private func ticketResultView(_ ticket: Ticket) -> some View {
        let details = lookupService.getTicketDetails(ticket)
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title)
                
                Text("Ticket Found!")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                LabeledContent("Ticket #", value: String(details.ticketNumber))
                LabeledContent("Customer", value: details.customerName)
                LabeledContent("Device", value: "\(details.deviceType) \(details.deviceModel)")
                LabeledContent("Status", value: details.status.capitalized)
            }
            .font(.subheadline)
            
            HStack(spacing: 12) {
                Button(action: { showingTicketDetail = true }) {
                    Label("View Details", systemImage: "eye")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                Button(action: printLabel) {
                    Label("Print Label", systemImage: "printer")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Button(action: resetScan) {
                    Label("Scan Another", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
        .padding()
    }
    
    // MARK: - Actions
    
    private func startCameraScanning() {
        scanner.requestCameraPermission { granted in
            if granted {
                scanner.startScanning()
            } else {
                scanner.error = "Camera permission denied"
            }
        }
    }
    
    private func processManualInput() {
        if scanner.processManualBarcode(manualInput) {
            processBarcode(manualInput)
        }
    }
    
    private func processBarcode(_ barcode: String) {
        if let ticket = lookupService.findTicket(byBarcode: barcode) {
            foundTicket = ticket
            NSSound.beep()
        } else {
            scanner.error = "No ticket found for barcode: \(barcode)"
            foundTicket = nil
        }
    }
    
    private func printLabel() {
        guard let ticket = foundTicket else { return }
        let customer = ticket.customerId != nil ? CoreDataManager.shared.fetchCustomer(id: ticket.customerId!) : nil
        barcodeGenerator.printBarcodeLabel(for: ticket, customer: customer)
    }
    
    private func resetScan() {
        foundTicket = nil
        manualInput = ""
        scanner.scannedCode = nil
        scanner.error = nil
        
        if scanMode == .camera && !scanner.isScanning {
            startCameraScanning()
        }
    }
}

// MARK: - Scan Mode

enum ScanMode {
    case camera
    case manual
    case usb
}

// MARK: - Barcode Management View

struct BarcodeManagementView: View {
    @State private var showingScanner = false
    @State private var selectedTicket: Ticket?
    @State private var barcodeType: BarcodeType = .code128
    @State private var showingCustomerPicker = false
    @State private var showingInvoicePicker = false
    @State private var selectedCustomer: Customer?
    @State private var selectedInvoice: Invoice?

    private let barcodeGenerator = BarcodeGenerator.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Barcode System")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Scan and print barcodes for tickets")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { showingScanner = true }) {
                    Label("Scan Barcode", systemImage: "barcode.viewfinder")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            Divider()
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // Quick Actions
                    quickActionsView
                    
                    Divider()
                    
                    // Barcode Types Info
                    barcodeTypesInfo
                    
                    Divider()
                    
                    // Instructions
                    instructionsView
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingCustomerPicker) {
            CustomerPickerView(selectedCustomer: $selectedCustomer)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingInvoicePicker) {
            InvoicePickerView(customerId: selectedCustomer?.id, selectedInvoice: $selectedInvoice)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private var quickActionsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)

            VStack(spacing: 12) {
                ActionCard(
                    title: "Scan Barcode",
                    description: "Open the scanner interface",
                    icon: "barcode.viewfinder",
                    color: .blue,
                    action: { showingScanner = true }
                )

                ActionCard(
                    title: "Print Labels",
                    description: "Print barcode labels for tickets",
                    icon: "printer",
                    color: .green,
                    action: { showingCustomerPicker = true }
                )

                ActionCard(
                    title: "Generate QR",
                    description: "Create QR codes for tickets",
                    icon: "qrcode",
                    color: .purple,
                    action: { showingInvoicePicker = true }
                )
            }
        }
    }
    
    private var barcodeTypesInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Supported Barcode Types")
                .font(.headline)
            
            ForEach(BarcodeType.allCases, id: \.self) { type in
                HStack {
                    Image(systemName: type == .qrCode ? "qrcode" : "barcode")
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(type.rawValue)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text(type.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            }
        }
    }
    
    private var instructionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How to Use")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                InstructionRow(number: 1, text: "Print barcode labels when checking in tickets")
                InstructionRow(number: 2, text: "Attach labels to devices for easy identification")
                InstructionRow(number: 3, text: "Scan barcodes to quickly look up ticket information")
                InstructionRow(number: 4, text: "Use USB scanner or camera for scanning")
            }
        }
    }
}

// MARK: - Action Card

struct ActionCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(color.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Instruction Row

struct InstructionRow: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Color.blue)
                .clipShape(Circle())
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

struct BarcodeScannerView_Previews: PreviewProvider {
    static var previews: some View {
        BarcodeScannerView()
    }
}
