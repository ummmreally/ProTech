//
//  DymoPrintService.swift
//  ProTech
//
//  Service for printing labels to Dymo label printers
//

import Foundation
import AppKit
import CoreData
import CoreImage

/// Custom view that renders label content with 90-degree rotation
/// This matches DYMO's Rotation90 behavior from the label XML specification
class RotatedLabelView: NSView {
    private let content: String
    private let barcodeData: String?
    private let labelWidth: CGFloat
    private let labelHeight: CGFloat
    
    init(frame: NSRect, content: String, barcodeData: String?, labelWidth: CGFloat, labelHeight: CGFloat) {
        self.content = content
        self.barcodeData = barcodeData
        self.labelWidth = labelWidth
        self.labelHeight = labelHeight
        super.init(frame: frame)
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.white.cgColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        // Save the graphics state
        context.saveGState()
        
        // Apply 90-degree rotation transformation
        // This rotates content clockwise so the long edge becomes vertical
        // Similar to DYMO's <Rotation>Rotation90</Rotation> in label XML
        context.translateBy(x: labelWidth, y: 0)
        context.rotate(by: .pi / 2) // 90 degrees clockwise
        
        // Now we're drawing in a rotated space where:
        // - Height becomes width (252pt becomes horizontal)
        // - Width becomes height (81pt becomes vertical)
        let rotatedWidth = labelHeight  // 252pt
        let rotatedHeight = labelWidth  // 81pt
        
        // Parse content lines
        let lines = content.split(separator: "\n").map(String.init)
        
        // Calculate layout sections
        let hasBarcode = barcodeData != nil
        let barcodeHeight: CGFloat = hasBarcode ? 25 : 0
        let topPadding: CGFloat = 4
        let barcodePadding: CGFloat = hasBarcode ? 6 : 4
        let bottomPadding: CGFloat = hasBarcode ? barcodeHeight + barcodePadding : barcodePadding
        let availableTextHeight = max(rotatedHeight - topPadding - bottomPadding, 1)
        
        // Draw text content
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineBreakMode = .byWordWrapping
        
        // Line spacing for better readability
        let lineHeight: CGFloat = availableTextHeight / CGFloat(max(lines.count, 1))
        var yOffset: CGFloat = rotatedHeight - topPadding
        
        for (index, line) in lines.enumerated() {
            let fontSize: CGFloat
            let isBold: Bool
            
            // First line is typically product name + price (bold, larger)
            if index == 0 {
                fontSize = min(10, lineHeight * 0.7)
                isBold = true
            } else {
                fontSize = min(8, lineHeight * 0.6)
                isBold = false
            }
            
            let font = isBold ? NSFont.boldSystemFont(ofSize: fontSize) : NSFont.systemFont(ofSize: fontSize)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.black,
                .paragraphStyle: paragraphStyle
            ]
            
            let attributedString = NSAttributedString(string: line, attributes: attributes)
            let textRect = NSRect(x: 5, y: yOffset - lineHeight, width: rotatedWidth - 10, height: lineHeight)
            attributedString.draw(in: textRect)
            yOffset -= lineHeight
        }

        // Draw barcode if provided
        if let barcodeData = barcodeData,
           let barcodeImage = DymoPrintService.shared.generateBarcode(from: barcodeData) {
            let horizontalMargin: CGFloat = 12
            let barcodeWidth = max(rotatedWidth - (horizontalMargin * 2), 1)
            let barcodeRect = NSRect(
                x: (rotatedWidth - barcodeWidth) / 2,
                y: 2,
                width: barcodeWidth,
                height: max(barcodeHeight - 4, 1)
            )
            barcodeImage.draw(in: barcodeRect)
        }
        
        // Restore the graphics state
        context.restoreGState()
    }
}

class DymoPrintService {
    static let shared = DymoPrintService()
    
    private init() {}
    
    // MARK: - Product Label Printing
    
    /// Print a product label for inventory items
    func printProductLabel(product: InventoryItem) {
        let labelContent = generateProductLabelContent(product: product)
        let barcodeData = product.sku ?? product.partNumber ?? "NO-SKU"
        printLabel(content: labelContent, labelType: .product, barcodeData: barcodeData)
    }
    
    /// Print multiple product labels
    func printProductLabels(products: [InventoryItem], copies: Int = 1) {
        for product in products {
            for _ in 0..<copies {
                printProductLabel(product: product)
            }
        }
    }
    
    // MARK: - Device Label Printing
    
    /// Print a device label for customer check-in
    func printDeviceLabel(ticket: Ticket, customer: Customer?) {
        let labelContent = generateDeviceLabelContent(ticket: ticket, customer: customer)
        let ticketNumber = String(format: "%05d", ticket.ticketNumber)
        printLabel(content: labelContent, labelType: .device, barcodeData: ticketNumber)
    }
    
    // MARK: - Form Printing
    
    /// Print a completed form submission
    func printForm(submission: FormSubmission, template: FormTemplate) {
        let formContent = generateFormContent(submission: submission, template: template)
        printDocument(content: formContent, title: template.name ?? "Form")
    }
    
    /// Print check-in agreement form
    func printCheckInAgreement(ticket: Ticket, customer: Customer) {
        let agreementContent = generateCheckInAgreementContent(ticket: ticket, customer: customer)
        printDocument(content: agreementContent, title: "Service Agreement")
    }
    
    /// Print pickup/completion form
    func printPickupForm(ticket: Ticket, customer: Customer) {
        let pickupContent = generatePickupFormContent(ticket: ticket, customer: customer)
        printDocument(content: pickupContent, title: "Pickup Form")
    }
    
    /// Print business report
    func printReport(title: String, dateRange: String, metrics: [String: String], details: String = "") {
        let reportContent = generateReportContent(title: title, dateRange: dateRange, metrics: metrics, details: details)
        printDocument(content: reportContent, title: title)
    }
    
    // MARK: - Label Generation
    
    private func generateProductLabelContent(product: InventoryItem) -> String {
        let name = product.name ?? "Product"
        // Truncate name if too long (max 30 chars)
        let displayName = name.count > 30 ? String(name.prefix(27)) + "..." : name
        let sku = product.sku ?? "N/A"
        let price = String(format: "$%.2f", product.sellingPrice)
        
        return """
        \(Configuration.appName) | \(price)
        \(displayName)
        SKU: \(sku)
        """
    }
    
    private func generateDeviceLabelContent(ticket: Ticket, customer: Customer?) -> String {
        let customerName = customer?.firstName ?? "Customer"
        let deviceType = ticket.deviceType ?? "Device"
        let deviceModel = ticket.deviceModel ?? ""
        let ticketNumber = String(format: "%05d", ticket.ticketNumber)
        let issue = ticket.issueDescription ?? "No description"
        // Truncate issue if too long
        let displayIssue = issue.count > 30 ? String(issue.prefix(27)) + "..." : issue
        
        return """
        \(Configuration.appName) - DEVICE TAG
        Ticket #\(ticketNumber) | \(customerName)
        \(deviceType) \(deviceModel)
        \(displayIssue)
        """
    }
    
    private func generateFormContent(submission: FormSubmission, template: FormTemplate) -> String {
        let customerName = submission.responseData?.submitterName ?? "N/A"
        let dateSubmitted = submission.submittedAt?.formatted(date: .long, time: .shortened) ?? "N/A"
        let formName = template.name ?? "Form"
        
        var content = """
        ═══════════════════════════════════
        \(Configuration.appName)
        \(formName)
        ═══════════════════════════════════
        
        Customer: \(customerName)
        Submitted: \(dateSubmitted)
        
        ───────────────────────────────────
        
        """
        
        // Parse and add form fields
        let responses = submission.responses
        for (key, value) in responses.sorted(by: { $0.key < $1.key }) {
            let formattedKey = key.replacingOccurrences(of: "_", with: " ").capitalized
            content += "\(formattedKey):\n"
            content += "  \(value)\n\n"
        }
        
        content += """
        ───────────────────────────────────
        Signature: _____________________
        
        Date: __________________________
        ═══════════════════════════════════
        """
        
        return content
    }
    
    private func generateCheckInAgreementContent(ticket: Ticket, customer: Customer) -> String {
        let customerName = "\(customer.firstName ?? "") \(customer.lastName ?? "")"
        let ticketNumber = String(format: "%05d", ticket.ticketNumber)
        let dateIn = ticket.checkedInAt?.formatted(date: .long, time: .shortened) ?? "N/A"
        let deviceModel = ticket.deviceModel ?? "Device"
        let issue = ticket.issueDescription ?? "No description"
        let hasBackup = ticket.hasDataBackup ? "Yes" : "No"
        let findMyStatus = ticket.findMyDisabled ? "Disabled" : "Not Disabled"
        
        var content = """
        ═══════════════════════════════════════════════════
        \(Configuration.appName)
        SERVICE REQUEST & AGREEMENT
        ═══════════════════════════════════════════════════
        
        Ticket Number: #\(ticketNumber)
        Date: \(dateIn)
        
        ───────────────────────────────────────────────────
        CUSTOMER INFORMATION
        ───────────────────────────────────────────────────
        
        Name: \(customerName)
        Phone: \(customer.phone ?? "N/A")
        Email: \(customer.email ?? "N/A")
        
        """
        
        if let altName = ticket.alternateContactName, !altName.isEmpty {
            content += """
            Alternate Contact: \(altName)
            Alt. Phone: \(ticket.alternateContactNumber ?? "N/A")
            
            """
        }
        
        content += """
        ───────────────────────────────────────────────────
        DEVICE INFORMATION
        ───────────────────────────────────────────────────
        
        Device: \(deviceModel)
        """
        
        if let serial = ticket.deviceSerialNumber, !serial.isEmpty {
            content += "\nSerial Number: \(serial)"
        }
        
        if let passcode = ticket.devicePasscode, !passcode.isEmpty {
            content += "\nDevice Passcode: \(passcode)"
        }
        
        content += """
        
        Data Backup: \(hasBackup)
        Find My iPhone: \(findMyStatus)
        
        ───────────────────────────────────────────────────
        ISSUE DESCRIPTION
        ───────────────────────────────────────────────────
        
        \(issue)
        
        """
        
        if let details = ticket.additionalRepairDetails, !details.isEmpty {
            content += """
            Additional Details:
            \(details)
            
            """
        }
        
        content += """
        ───────────────────────────────────────────────────
        TERMS AND CONDITIONS
        ───────────────────────────────────────────────────
        
        By signing this document customer agrees to allow 
        \(Configuration.appName) to perform service on listed device 
        above. Customer understands that \(Configuration.appName) is 
        not responsible for any data loss that may occur while in 
        possession of the device listed.
        
        \(Configuration.appName) will contact you 3 times within a 
        30 day period when the device is ready for pickup. After 
        the 31st day if full balance is unpaid the device will be 
        marked abandoned. \(Configuration.appName) will then take 
        ownership of the device or the device may be recycled.
        
        Customer agrees to these terms by signing below.
        
        ───────────────────────────────────────────────────
        
        Customer Signature: _________________________
        
        Date: _______________________________________
        
        Staff Signature: ____________________________
        
        ═══════════════════════════════════════════════════
        Keep this form for your records
        ═══════════════════════════════════════════════════
        """
        
        return content
    }
    
    private func generatePickupFormContent(ticket: Ticket, customer: Customer) -> String {
        let customerName = "\(customer.firstName ?? "") \(customer.lastName ?? "")"
        let ticketNumber = String(format: "%05d", ticket.ticketNumber)
        let dateIn = ticket.checkedInAt?.formatted(date: .abbreviated, time: .omitted) ?? "N/A"
        let dateCompleted = ticket.completedAt?.formatted(date: .long, time: .shortened) ?? Date().formatted(date: .long, time: .shortened)
        let deviceModel = ticket.deviceModel ?? "Device"
        
        var content = """
        ═══════════════════════════════════════════════════
        \(Configuration.appName)
        DEVICE PICKUP FORM
        ═══════════════════════════════════════════════════
        
        Ticket Number: #\(ticketNumber)
        Pickup Date: \(dateCompleted)
        
        ───────────────────────────────────────────────────
        CUSTOMER INFORMATION
        ───────────────────────────────────────────────────
        
        Name: \(customerName)
        Phone: \(customer.phone ?? "N/A")
        
        ───────────────────────────────────────────────────
        DEVICE INFORMATION
        ───────────────────────────────────────────────────
        
        Device: \(deviceModel)
        Check-In Date: \(dateIn)
        
        """
        
        if let serial = ticket.deviceSerialNumber, !serial.isEmpty {
            content += "Serial Number: \(serial)\n"
        }
        
        content += """
        
        ───────────────────────────────────────────────────
        SERVICE SUMMARY
        ───────────────────────────────────────────────────
        
        Original Issue:
        \(ticket.issueDescription ?? "No description")
        
        """
        
        // Extract resolution from notes if available
        if let notes = ticket.notes, !notes.isEmpty {
            // Look for resolution in notes
            let lines = notes.components(separatedBy: "\n")
            if let resolutionLine = lines.first(where: { $0.contains("Resolution:") || $0.contains("Completed:") }) {
                content += """
                Resolution:
                \(resolutionLine)
                
                """
            }
        }
        
        content += """
        ───────────────────────────────────────────────────
        PICKUP ACKNOWLEDGMENT
        ───────────────────────────────────────────────────
        
        I acknowledge receipt of my device in working order
        and agree that all services have been completed as
        described. I understand that warranty terms apply as
        discussed with staff.
        
        Any issues with the repair must be reported within
        7 days of pickup.
        
        ───────────────────────────────────────────────────
        
        Customer Signature: _________________________
        
        Date: _______________________________________
        
        Staff Member: _______________________________
        
        ═══════════════════════════════════════════════════
        Thank you for choosing \(Configuration.appName)!
        ═══════════════════════════════════════════════════
        """
        
        return content
    }
    
    private func generateReportContent(title: String, dateRange: String, metrics: [String: String], details: String) -> String {
        let currentDate = Date().formatted(date: .long, time: .shortened)
        
        var content = """
        ═══════════════════════════════════════════════════
        \(Configuration.appName)
        \(title.uppercased())
        ═══════════════════════════════════════════════════
        
        Generated: \(currentDate)
        Period: \(dateRange)
        
        ───────────────────────────────────────────────────
        KEY METRICS
        ───────────────────────────────────────────────────
        
        """
        
        // Add metrics
        for (key, value) in metrics.sorted(by: { $0.key < $1.key }) {
            content += "\(key): \(value)\n"
        }
        
        // Add details if provided
        if !details.isEmpty {
            content += """
            
            ───────────────────────────────────────────────────
            DETAILED BREAKDOWN
            ───────────────────────────────────────────────────
            
            \(details)
            """
        }
        
        content += """
        
        ═══════════════════════════════════════════════════
        Report generated by \(Configuration.appName)
        ═══════════════════════════════════════════════════
        """
        
        return content
    }
    
    private func generateBarcodeRepresentation(_ code: String) -> String {
        // Simple barcode representation for text-based printing
        let bars = code.map { char -> String in
            if char.isNumber {
                return "█"
            } else {
                return "▌"
            }
        }.joined()
        
        return """
        \(bars)
        \(code)
        """
    }
    
    // MARK: - Printing Methods
    
    private enum LabelType {
        case product  // 1.125" x 3.5" address label (DYMO 30252)
        case device   // 1.125" x 3.5" address label (DYMO 30252)
    }
    
    private func printLabel(content: String, labelType: LabelType, barcodeData: String? = nil) {
        // Ensure we're on the main thread
        DispatchQueue.main.async {
            // Dymo 30252 Address Label: 1.125" x 3.5" (81pt x 252pt at 72 DPI)
            // IMPORTANT: For correct DYMO printing, we need:
            // - Paper size: 1.125" x 3.5" (81pt x 252pt) in PORTRAIT orientation
            // - Content rotated 90° so long edge (3.5") appears vertical
            // - Zero margins for maximum printable area
            let labelWidth: CGFloat = 81   // 1.125" physical width
            let labelHeight: CGFloat = 252 // 3.5" physical height
            let margin: CGFloat = 0        // Zero margins as per DYMO spec
            
            // Create a copy of print info for label size
            let printInfo = NSPrintInfo()
            printInfo.topMargin = margin
            printInfo.bottomMargin = margin
            printInfo.leftMargin = margin
            printInfo.rightMargin = margin
            
            // Set paper size for Dymo labels - use actual dimensions with portrait orientation
            // The rotation will be handled by transforming the content, not the paper
            printInfo.paperSize = NSSize(width: labelWidth, height: labelHeight)
            printInfo.orientation = .portrait  // Changed from .landscape
            printInfo.horizontalPagination = .fit
            printInfo.verticalPagination = .fit
            printInfo.isHorizontallyCentered = true
            printInfo.isVerticallyCentered = true
            printInfo.scalingFactor = 1.0  // No scaling - native DPI
            
            // Create container view with full label dimensions
            let contentWidth = labelWidth - (margin * 2)
            let contentHeight = labelHeight - (margin * 2)
            
            // Create a rotated container - this is the key fix
            // We create the content in landscape (wide) but rotate it 90° to fit portrait label
            let rotatedContainerView = RotatedLabelView(
                frame: NSRect(x: 0, y: 0, width: contentWidth, height: contentHeight),
                content: content,
                barcodeData: barcodeData,
                labelWidth: contentWidth,
                labelHeight: contentHeight
            )
            
            // Print operation
            let printOperation = NSPrintOperation(view: rotatedContainerView, printInfo: printInfo)
            
            // Try to find and set Dymo printer as default
            if let dymoPrinter = self.findDymoPrinter() {
                printInfo.printer = dymoPrinter
            }
            
            // Always show print panel so user can verify/change printer
            printOperation.showsPrintPanel = true
            printOperation.showsProgressPanel = true
            
            // Run in modal window context
            if let window = NSApp.keyWindow {
                printOperation.runModal(for: window, delegate: nil, didRun: nil, contextInfo: nil)
            } else {
                printOperation.run()
            }
        }
    }
    
    private func printDocument(content: String, title: String) {
        // Ensure we're on the main thread
        DispatchQueue.main.async {
            // Create attributed string for full document
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 11),
                .foregroundColor: NSColor.black
            ]
            
            let attributedString = NSAttributedString(string: content, attributes: attributes)
            
            // Create a copy of print info for standard paper
            let printInfo = NSPrintInfo()
            printInfo.topMargin = 36  // 0.5 inch
            printInfo.bottomMargin = 36
            printInfo.leftMargin = 36
            printInfo.rightMargin = 36
            printInfo.paperSize = NSSize(width: 612, height: 792)  // Letter size (8.5" x 11")
            
            // Create text view for printing
            let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 540, height: 720))  // Adjusted for margins
            textView.textStorage?.setAttributedString(attributedString)
            textView.isEditable = false
            
            // Print operation
            let printOperation = NSPrintOperation(view: textView, printInfo: printInfo)
            printOperation.jobTitle = title
            printOperation.showsPrintPanel = true  // Always show panel for documents
            printOperation.showsProgressPanel = true
            
            // Run in modal window context
            if let window = NSApp.keyWindow {
                printOperation.runModal(for: window, delegate: nil, didRun: nil, contextInfo: nil)
            } else {
                printOperation.run()
            }
        }
    }
    
    // MARK: - Barcode Generation
    
    /// Generate a scannable barcode image from a string
    /// Made internal so RotatedLabelView can access it
    func generateBarcode(from string: String) -> NSImage? {
        // Use Code128 barcode format (widely supported and can encode alphanumeric)
        let data = string.data(using: .ascii)
        
        guard let filter = CIFilter(name: "CICode128BarcodeGenerator") else {
            print("Failed to create barcode filter")
            return nil
        }
        
        filter.setValue(data, forKey: "inputMessage")
        // Provide left/right quiet zone so outer bars do not ride the edge
        filter.setValue(4.0, forKey: "inputQuietSpace")
        
        guard let outputImage = filter.outputImage else {
            print("Failed to generate barcode image")
            return nil
        }
        
        // Scale up the barcode for better quality
        let scaleX = 200.0 / outputImage.extent.width
        let scaleY = 50.0 / outputImage.extent.height
        let transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        // Convert CIImage to NSImage
        let rep = NSCIImageRep(ciImage: transformedImage)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)
        
        return nsImage
    }
    
    private func findDymoPrinter() -> NSPrinter? {
        // Look for Dymo printer in available printers
        let printers = NSPrinter.printerNames
        
        // Common Dymo printer name patterns (case-insensitive)
        let dymoPatterns = ["dymo", "labelwriter", "label writer", "lw"]
        
        // First, try exact matches
        for printerName in printers {
            let nameLowercase = printerName.lowercased()
            for pattern in dymoPatterns {
                if nameLowercase.contains(pattern) {
                    print("Found Dymo printer: \(printerName)")
                    return NSPrinter(name: printerName)
                }
            }
        }
        
        print("No Dymo printer found. Available printers: \(printers.joined(separator: ", "))")
        return nil
    }
    
    // MARK: - Printer Status
    
    func isDymoPrinterAvailable() -> Bool {
        return findDymoPrinter() != nil
    }
    
    func getAvailablePrinters() -> [String] {
        return NSPrinter.printerNames
    }
}
