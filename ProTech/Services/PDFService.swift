//
//  PDFService.swift
//  ProTech
//
//  Service for generating and printing specific PDF documents like agreements and pickup forms.
//

import Foundation
import PDFKit
import AppKit

class PDFService {
    static let shared = PDFService()
    
    private init() {}
    
    func generateAndPrintCheckInAgreement(ticket: Ticket, customer: Customer) {
        if let document = generateCheckInAgreement(ticket: ticket, customer: customer) {
            printPDF(document)
        }
    }
    
    func generateAndPrintPickupForm(ticket: Ticket, customer: Customer) {
        if let document = generatePickupForm(ticket: ticket, customer: customer) {
            printPDF(document)
        }
    }
    
    func printPDF(_ document: PDFDocument) {
        let printInfo = NSPrintInfo.shared
        printInfo.horizontalPagination = .fit
        printInfo.verticalPagination = .fit
        printInfo.topMargin = 36
        printInfo.bottomMargin = 36
        printInfo.leftMargin = 36
        printInfo.rightMargin = 36
        
        // This is a synchronous blocking call in some contexts, be careful.
        // For macOS app, this usually opens the print panel or prints immediately if configured.
        document.printOperation(for: printInfo, scalingMode: .pageScaleDownToFit, autoRotate: true)?.run()
    }
    
    // MARK: - Generators
    
    private func generateCheckInAgreement(ticket: Ticket, customer: Customer) -> PDFDocument? {
        let pdfData = NSMutableData()
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: nil, nil) else { return nil }
        
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter
        
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        context.beginPDFPage(nil)
        
        var yPos = pageRect.height - 50
        let leftMargin: CGFloat = 50
        
        // Title
        drawText("Check-In Agreement", at: CGPoint(x: leftMargin, y: yPos), fontSize: 24, isBold: true)
        yPos -= 50
        
        // Ticket Info
        drawText("Ticket #: \(ticket.ticketNumber)", at: CGPoint(x: leftMargin, y: yPos), fontSize: 14)
        yPos -= 20
        drawText("Date: \(Date().formatted())", at: CGPoint(x: leftMargin, y: yPos), fontSize: 14)
        yPos -= 40
        
        // Customer Info
        drawText("Customer: \(customer.firstName ?? "") \(customer.lastName ?? "")", at: CGPoint(x: leftMargin, y: yPos), fontSize: 14)
        yPos -= 20
        drawText("Device: \(ticket.deviceType ?? "") \(ticket.deviceModel ?? "")", at: CGPoint(x: leftMargin, y: yPos), fontSize: 14)
        yPos -= 20
        if let serial = ticket.deviceSerialNumber {
            drawText("Serial/IMEI: \(serial)", at: CGPoint(x: leftMargin, y: yPos), fontSize: 14)
            yPos -= 20
        }
        yPos -= 20
        
        // Terms
        drawText("Terms & Conditions", at: CGPoint(x: leftMargin, y: yPos), fontSize: 16, isBold: true)
        yPos -= 25
        
        let terms = """
        1. Authorization: You authorize ProTech to perform repairs on the device listed above.
        2. Data: We are not responsible for any data loss. Please backup your device.
        3. Warranty: Repairs include a 90-day warranty on parts and labor.
        4. Pickup: Devices not picked up within 30 days may be disposed of.
        """
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .paragraphStyle: paragraphStyle
        ]
        
        let termsRect = CGRect(x: leftMargin, y: yPos - 100, width: pageRect.width - 100, height: 100)
        terms.draw(in: termsRect, withAttributes: attrs)
        yPos -= 120
        
        // Signature Line
        yPos -= 50
        drawText("Customer Signature: _______________________", at: CGPoint(x: leftMargin, y: yPos), fontSize: 14)
        
        context.endPDFPage()
        context.closePDF()
        
        return PDFDocument(data: pdfData as Data)
    }
    
    private func generatePickupForm(ticket: Ticket, customer: Customer) -> PDFDocument? {
        let pdfData = NSMutableData()
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: nil, nil) else { return nil }
        
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        context.beginPDFPage(nil)
        
        var yPos = pageRect.height - 50
        let leftMargin: CGFloat = 50
        
        // Title
        drawText("Service Completion & Pickup", at: CGPoint(x: leftMargin, y: yPos), fontSize: 24, isBold: true)
        yPos -= 50
        
        // Ticket Info
        drawText("Ticket #: \(ticket.ticketNumber)", at: CGPoint(x: leftMargin, y: yPos), fontSize: 14)
        yPos -= 20
        drawText("Completion Date: \(ticket.completedAt?.formatted() ?? Date().formatted())", at: CGPoint(x: leftMargin, y: yPos), fontSize: 14)
        yPos -= 40
        
        // Device Info
        drawText("Device: \(ticket.deviceType ?? "") \(ticket.deviceModel ?? "")", at: CGPoint(x: leftMargin, y: yPos), fontSize: 14)
        yPos -= 40
        
        // Confirmation
        drawText("I acknowledge receipt of my device in good working order.", at: CGPoint(x: leftMargin, y: yPos), fontSize: 14)
        yPos -= 60
        
        // Signature Line
        drawText("Customer Signature: _______________________", at: CGPoint(x: leftMargin, y: yPos), fontSize: 14)
        
        context.endPDFPage()
        context.closePDF()
        
        return PDFDocument(data: pdfData as Data)
    }
    
    private func drawText(_ text: String, at point: CGPoint, fontSize: CGFloat, isBold: Bool = false) {
        let font = isBold ? NSFont.boldSystemFont(ofSize: fontSize) : NSFont.systemFont(ofSize: fontSize)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.black
        ]
        let size = text.size(withAttributes: attrs)
        text.draw(at: CGPoint(x: point.x, y: point.y - size.height), withAttributes: attrs)
    }
}
