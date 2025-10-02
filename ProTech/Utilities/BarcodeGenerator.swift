import Foundation
import CoreImage
import AppKit

class BarcodeGenerator {
    static let shared = BarcodeGenerator()
    
    private init() {}
    
    // MARK: - Barcode Generation
    
    /// Generate barcode image from string
    func generateBarcode(from string: String, type: BarcodeType = .code128) -> NSImage? {
        guard let data = string.data(using: .ascii) else {
            return nil
        }
        
        let filterName: String
        switch type {
        case .code128:
            filterName = "CICode128BarcodeGenerator"
        case .qrCode:
            filterName = "CIQRCodeGenerator"
        case .aztec:
            filterName = "CIAztecCodeGenerator"
        }
        
        guard let filter = CIFilter(name: filterName) else {
            return nil
        }
        
        filter.setValue(data, forKey: "inputMessage")
        
        // For QR codes, set error correction
        if type == .qrCode {
            filter.setValue("M", forKey: "inputCorrectionLevel")
        }
        
        guard let outputImage = filter.outputImage else {
            return nil
        }
        
        // Scale up the barcode for better quality
        let scaleX = 200.0 / outputImage.extent.width
        let scaleY = 100.0 / outputImage.extent.height
        let scale = type == .qrCode ? min(scaleX, scaleY) : scaleX
        
        let transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        
        let rep = NSCIImageRep(ciImage: transformedImage)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)
        
        return nsImage
    }
    
    /// Generate barcode for a ticket
    func generateTicketBarcode(_ ticket: Ticket, type: BarcodeType = .code128) -> NSImage? {
        let barcodeString = "TKT\(String(format: "%06d", ticket.ticketNumber))"
        return generateBarcode(from: barcodeString, type: type)
    }
    
    /// Generate QR code for a ticket with full details
    func generateTicketQRCode(_ ticket: Ticket) -> NSImage? {
        let qrString = """
        TICKET:\(ticket.ticketNumber)
        ID:\(ticket.id?.uuidString ?? "")
        CUSTOMER:\(ticket.customerId?.uuidString ?? "")
        STATUS:\(ticket.status ?? "")
        """
        return generateBarcode(from: qrString, type: .qrCode)
    }
    
    // MARK: - Barcode Label Generation
    
    /// Generate a printable barcode label for a ticket
    func generateTicketLabel(for ticket: Ticket, customer: Customer?) -> NSImage? {
        let labelWidth: CGFloat = 288  // 4 inches at 72 DPI
        let labelHeight: CGFloat = 144 // 2 inches at 72 DPI
        
        let image = NSImage(size: NSSize(width: labelWidth, height: labelHeight))
        
        image.lockFocus()
        
        // Background
        NSColor.white.setFill()
        NSRect(x: 0, y: 0, width: labelWidth, height: labelHeight).fill()
        
        // Border
        NSColor.black.setStroke()
        let borderPath = NSBezierPath(rect: NSRect(x: 5, y: 5, width: labelWidth - 10, height: labelHeight - 10))
        borderPath.lineWidth = 2
        borderPath.stroke()
        
        // Ticket number (large)
        let ticketNumberText = "Ticket #\(ticket.ticketNumber)"
        let ticketNumberAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 20),
            .foregroundColor: NSColor.black
        ]
        ticketNumberText.draw(at: NSPoint(x: 15, y: labelHeight - 35), withAttributes: ticketNumberAttrs)
        
        // Customer name
        if let customer = customer {
            let customerName = "\(customer.firstName ?? "") \(customer.lastName ?? "")".trimmingCharacters(in: .whitespaces)
            let customerAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 12),
                .foregroundColor: NSColor.black
            ]
            customerName.draw(at: NSPoint(x: 15, y: labelHeight - 55), withAttributes: customerAttrs)
        }
        
        // Device info
        if let deviceType = ticket.deviceType {
            let deviceText = "\(deviceType) \(ticket.deviceModel ?? "")"
            let deviceAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 10),
                .foregroundColor: NSColor.darkGray
            ]
            deviceText.draw(at: NSPoint(x: 15, y: labelHeight - 75), withAttributes: deviceAttrs)
        }
        
        // Barcode
        if let barcode = generateTicketBarcode(ticket) {
            let barcodeRect = NSRect(x: 15, y: 15, width: labelWidth - 30, height: 50)
            barcode.draw(in: barcodeRect)
        }
        
        image.unlockFocus()
        
        return image
    }
    
    // MARK: - Barcode Printing
    
    /// Print barcode label
    func printBarcodeLabel(for ticket: Ticket, customer: Customer?) {
        guard let labelImage = generateTicketLabel(for: ticket, customer: customer) else {
            return
        }
        
        let printInfo = NSPrintInfo.shared
        printInfo.paperSize = NSSize(width: 288, height: 144) // 4x2 inches
        printInfo.topMargin = 0
        printInfo.bottomMargin = 0
        printInfo.leftMargin = 0
        printInfo.rightMargin = 0
        
        let imageView = NSImageView(frame: NSRect(x: 0, y: 0, width: 288, height: 144))
        imageView.image = labelImage
        
        let printOperation = NSPrintOperation(view: imageView, printInfo: printInfo)
        printOperation.showsPrintPanel = true
        printOperation.run()
    }
    
    // MARK: - Barcode Validation
    
    /// Validate barcode format
    func validateBarcodeFormat(_ barcode: String, type: BarcodeType) -> Bool {
        switch type {
        case .code128:
            // Code128 can encode any ASCII character
            return !barcode.isEmpty && barcode.count <= 80
        case .qrCode:
            // QR codes can hold up to ~4000 characters
            return !barcode.isEmpty && barcode.count <= 4000
        case .aztec:
            // Aztec codes similar to QR
            return !barcode.isEmpty && barcode.count <= 3000
        }
    }
    
    /// Extract ticket number from barcode string
    func extractTicketNumber(from barcode: String) -> Int32? {
        // Expected format: TKT000001
        guard barcode.hasPrefix("TKT"), barcode.count >= 4 else {
            return nil
        }
        
        let numberString = String(barcode.dropFirst(3))
        return Int32(numberString)
    }
    
    /// Parse QR code data
    func parseQRCodeData(_ qrString: String) -> [String: String] {
        var data: [String: String] = [:]
        
        let lines = qrString.components(separatedBy: "\n")
        for line in lines {
            let parts = line.components(separatedBy: ":")
            if parts.count == 2 {
                data[parts[0]] = parts[1]
            }
        }
        
        return data
    }
}

// MARK: - Barcode Types

enum BarcodeType: String, CaseIterable {
    case code128 = "Code 128"
    case qrCode = "QR Code"
    case aztec = "Aztec Code"
    
    var description: String {
        switch self {
        case .code128:
            return "Linear barcode, good for ticket numbers"
        case .qrCode:
            return "2D barcode, can store more data"
        case .aztec:
            return "2D barcode, compact format"
        }
    }
}
