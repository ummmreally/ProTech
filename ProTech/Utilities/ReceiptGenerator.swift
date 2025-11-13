import Foundation
import PDFKit
import AppKit

class ReceiptGenerator {
    static let shared = ReceiptGenerator()
    
    private init() {}
    
    // MARK: - Receipt PDF Generation
    
    /// Generate PDF receipt for a payment
    func generateReceiptPDF(
        payment: Payment,
        customer: Customer,
        invoice: Invoice?,
        companyInfo: CompanyInfo
    ) -> PDFDocument? {
        let pdfData = NSMutableData()
        
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData) else {
            return nil
        }
        
        // Receipt size (smaller than invoice - 4x6 inches: 288 x 432 points)
        let pageRect = CGRect(x: 0, y: 0, width: 288, height: 432)
        
        var mediaBox = pageRect
        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            return nil
        }
        
        context.beginPDFPage(nil)
        
        drawReceiptContent(
            context: context,
            payment: payment,
            customer: customer,
            invoice: invoice,
            companyInfo: companyInfo,
            pageRect: pageRect
        )
        
        context.endPDFPage()
        context.closePDF()
        
        return PDFDocument(data: pdfData as Data)
    }
    
    // MARK: - Drawing Methods
    
    private func drawReceiptContent(
        context: CGContext,
        payment: Payment,
        customer: Customer,
        invoice: Invoice?,
        companyInfo: CompanyInfo,
        pageRect: CGRect
    ) {
        let margin: CGFloat = 20
        var yPosition: CGFloat = pageRect.height - margin
        
        // Company header (centered)
        yPosition = drawCenteredText(
            context: context,
            text: companyInfo.name,
            y: yPosition,
            pageWidth: pageRect.width,
            fontSize: 16,
            bold: true
        )
        
        yPosition -= 5
        
        if !companyInfo.phone.isEmpty {
            yPosition = drawCenteredText(
                context: context,
                text: companyInfo.phone,
                y: yPosition,
                pageWidth: pageRect.width,
                fontSize: 9
            )
            yPosition -= 3
        }
        
        if !companyInfo.address.isEmpty {
            yPosition = drawCenteredText(
                context: context,
                text: companyInfo.address,
                y: yPosition,
                pageWidth: pageRect.width,
                fontSize: 8
            )
        }
        
        yPosition -= 15
        
        // Divider
        context.setStrokeColor(NSColor.gray.cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: margin, y: yPosition))
        context.addLine(to: CGPoint(x: pageRect.width - margin, y: yPosition))
        context.strokePath()
        
        yPosition -= 15
        
        // Receipt title
        yPosition = drawCenteredText(
            context: context,
            text: "PAYMENT RECEIPT",
            y: yPosition,
            pageWidth: pageRect.width,
            fontSize: 14,
            bold: true
        )
        
        yPosition -= 15
        
        // Receipt details
        yPosition = drawReceiptInfo(
            context: context,
            payment: payment,
            invoice: invoice,
            startY: yPosition,
            margin: margin
        )
        
        yPosition -= 10
        
        // Customer info
        yPosition = drawCustomerInfo(
            context: context,
            customer: customer,
            startY: yPosition,
            margin: margin
        )
        
        yPosition -= 15
        
        // Divider
        context.setStrokeColor(NSColor.gray.cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: margin, y: yPosition))
        context.addLine(to: CGPoint(x: pageRect.width - margin, y: yPosition))
        context.strokePath()
        
        yPosition -= 15
        
        // Payment details
        yPosition = drawPaymentDetails(
            context: context,
            payment: payment,
            startY: yPosition,
            pageWidth: pageRect.width,
            margin: margin
        )
        
        yPosition -= 15
        
        // Divider
        context.setStrokeColor(NSColor.gray.cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: margin, y: yPosition))
        context.addLine(to: CGPoint(x: pageRect.width - margin, y: yPosition))
        context.strokePath()
        
        yPosition -= 15
        
        // Notes
        if let notes = payment.notes, !notes.isEmpty {
            yPosition = drawText(
                context: context,
                text: "Notes: \(notes)",
                x: margin,
                y: yPosition,
                fontSize: 8
            )
            yPosition -= 10
        }
        
        // Footer
        drawCenteredText(
            context: context,
            text: "Thank you for your business!",
            y: 30,
            pageWidth: pageRect.width,
            fontSize: 9,
            color: NSColor.gray
        )
    }
    
    private func drawReceiptInfo(
        context: CGContext,
        payment: Payment,
        invoice: Invoice?,
        startY: CGFloat,
        margin: CGFloat
    ) -> CGFloat {
        var y = startY
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        y = drawText(
            context: context,
            text: "Receipt #: \(payment.formattedPaymentNumber)",
            x: margin,
            y: y,
            fontSize: 9,
            bold: true
        )
        
        if let paymentDate = payment.paymentDate {
            y = drawText(
                context: context,
                text: "Date: \(dateFormatter.string(from: paymentDate))",
                x: margin,
                y: y,
                fontSize: 9
            )
        }
        
        if let invoice = invoice {
            y = drawText(
                context: context,
                text: "Invoice: \(invoice.formattedInvoiceNumber)",
                x: margin,
                y: y,
                fontSize: 9
            )
        }
        
        return y - 5
    }
    
    private func drawCustomerInfo(
        context: CGContext,
        customer: Customer,
        startY: CGFloat,
        margin: CGFloat
    ) -> CGFloat {
        var y = startY
        
        y = drawText(
            context: context,
            text: "Customer:",
            x: margin,
            y: y,
            fontSize: 9,
            bold: true
        )
        
        let customerName = "\(customer.firstName ?? "") \(customer.lastName ?? "")".trimmingCharacters(in: .whitespaces)
        if !customerName.isEmpty {
            y = drawText(
                context: context,
                text: customerName,
                x: margin,
                y: y,
                fontSize: 9
            )
        }
        
        return y - 5
    }
    
    private func drawPaymentDetails(
        context: CGContext,
        payment: Payment,
        startY: CGFloat,
        pageWidth: CGFloat,
        margin: CGFloat
    ) -> CGFloat {
        var y = startY
        
        // Payment method
        y = drawText(
            context: context,
            text: "Payment Method:",
            x: margin,
            y: y,
            fontSize: 9,
            bold: true
        )
        
        y = drawText(
            context: context,
            text: payment.paymentMethodDisplayName,
            x: margin,
            y: y,
            fontSize: 9
        )
        
        // Reference number if available
        if let refNumber = payment.referenceNumber, !refNumber.isEmpty {
            y = drawText(
                context: context,
                text: "Reference: \(refNumber)",
                x: margin,
                y: y,
                fontSize: 8
            )
        }
        
        y -= 10
        
        // Amount (large and centered)
        y = drawCenteredText(
            context: context,
            text: "AMOUNT PAID",
            y: y,
            pageWidth: pageWidth,
            fontSize: 10,
            bold: true
        )
        
        y -= 5
        
        y = drawCenteredText(
            context: context,
            text: payment.formattedAmount,
            y: y,
            pageWidth: pageWidth,
            fontSize: 18,
            bold: true
        )
        
        return y - 5
    }
    
    // MARK: - Text Drawing Helpers
    
    @discardableResult
    private func drawText(
        context: CGContext,
        text: String,
        x: CGFloat,
        y: CGFloat,
        fontSize: CGFloat,
        bold: Bool = false,
        color: NSColor = .black
    ) -> CGFloat {
        let font = bold ? NSFont.boldSystemFont(ofSize: fontSize) : NSFont.systemFont(ofSize: fontSize)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let line = CTLineCreateWithAttributedString(attributedString)
        
        context.saveGState()
        context.textMatrix = .identity
        context.translateBy(x: x, y: y)
        context.scaleBy(x: 1, y: -1)
        
        CTLineDraw(line, context)
        
        context.restoreGState()
        
        return y - fontSize - 3
    }
    
    @discardableResult
    private func drawCenteredText(
        context: CGContext,
        text: String,
        y: CGFloat,
        pageWidth: CGFloat,
        fontSize: CGFloat,
        bold: Bool = false,
        color: NSColor = .black
    ) -> CGFloat {
        let font = bold ? NSFont.boldSystemFont(ofSize: fontSize) : NSFont.systemFont(ofSize: fontSize)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let line = CTLineCreateWithAttributedString(attributedString)
        let bounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
        
        let x = (pageWidth - bounds.width) / 2
        
        context.saveGState()
        context.textMatrix = .identity
        context.translateBy(x: x, y: y)
        context.scaleBy(x: 1, y: -1)
        
        CTLineDraw(line, context)
        
        context.restoreGState()
        
        return y - fontSize - 3
    }
    
    // MARK: - Save Receipt
    
    /// Save receipt PDF to file
    func saveReceipt(_ pdfDocument: PDFDocument, to url: URL) -> Bool {
        return pdfDocument.write(to: url)
    }
    
    /// Get temporary receipt URL
    func getTemporaryReceiptURL(for paymentNumber: String) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "Receipt_\(paymentNumber)_\(Date().timeIntervalSince1970).pdf"
        return tempDir.appendingPathComponent(fileName)
    }
    
    // MARK: - Print Receipt
    
    /// Print receipt PDF
    func printReceipt(_ pdfDocument: PDFDocument) {
        let printInfo = NSPrintInfo.shared
        printInfo.topMargin = 0
        printInfo.bottomMargin = 0
        printInfo.leftMargin = 0
        printInfo.rightMargin = 0
        printInfo.paperSize = NSSize(width: 288, height: 432) // 4x6 inches
        printInfo.orientation = .portrait
        
        let printOperation = pdfDocument.printOperation(for: printInfo, scalingMode: .pageScaleToFit, autoRotate: true)
        printOperation?.run()
    }
    
    // MARK: - Email Receipt
    
    /// Email receipt using EmailService
    func emailReceipt(
        pdfDocument: PDFDocument,
        payment: Payment,
        customer: Customer,
        customerEmail: String
    ) -> Bool {
        // Save PDF to temporary location
        let tempURL = getTemporaryReceiptURL(for: payment.formattedPaymentNumber)
        guard pdfDocument.write(to: tempURL) else {
            return false
        }
        
        // Use EmailService to send
        return EmailService.shared.sendReceipt(
            payment: payment,
            customer: customer,
            pdfURL: tempURL,
            recipientEmail: customerEmail
        )
    }
}
