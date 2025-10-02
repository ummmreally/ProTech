import Foundation
import PDFKit
import AppKit

class PDFGenerator {
    static let shared = PDFGenerator()
    
    private init() {}
    
    // MARK: - Invoice PDF Generation
    
    /// Generate PDF for an invoice
    func generateInvoicePDF(
        invoice: Invoice,
        customer: Customer,
        companyInfo: CompanyInfo
    ) -> PDFDocument? {
        // Create PDF data
        let pdfData = NSMutableData()
        
        // Create PDF context
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData) else {
            return nil
        }
        
        // Page size (US Letter: 612 x 792 points)
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        
        var mediaBox = pageRect
        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            return nil
        }
        
        // Begin PDF page
        context.beginPDFPage(nil)
        
        // Draw invoice content
        drawInvoiceContent(
            context: context,
            invoice: invoice,
            customer: customer,
            companyInfo: companyInfo,
            pageRect: pageRect
        )
        
        // End PDF page
        context.endPDFPage()
        context.closePDF()
        
        // Create PDF document from data
        return PDFDocument(data: pdfData as Data)
    }

    /// Generate PDF for an estimate
    func generateEstimatePDF(
        estimate: Estimate,
        customer: Customer,
        companyInfo: CompanyInfo
    ) -> PDFDocument? {
        let pdfData = NSMutableData()
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData) else {
            return nil
        }
        
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        var mediaBox = pageRect
        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            return nil
        }
        
        context.beginPDFPage(nil)
        
        let margin: CGFloat = 50
        var yPosition: CGFloat = pageRect.height - margin
        
        yPosition = drawCompanyHeader(
            context: context,
            companyInfo: companyInfo,
            startY: yPosition,
            pageWidth: pageRect.width,
            margin: margin
        )
        
        yPosition -= 30
        yPosition = drawText(
            context: context,
            text: "ESTIMATE",
            x: margin,
            y: yPosition,
            fontSize: 24,
            bold: true
        )
        
        yPosition -= 30
        yPosition = drawEstimateDetails(
            context: context,
            estimate: estimate,
            startY: yPosition,
            pageWidth: pageRect.width,
            margin: margin
        )
        
        yPosition -= 20
        yPosition = drawCustomerInfo(
            context: context,
            customer: customer,
            startY: yPosition,
            margin: margin
        )
        
        yPosition -= 30
        yPosition = drawEstimateLineItemsTable(
            context: context,
            estimate: estimate,
            startY: yPosition,
            pageWidth: pageRect.width,
            margin: margin
        )
        
        yPosition -= 30
        yPosition = drawEstimateTotals(
            context: context,
            estimate: estimate,
            startY: yPosition,
            pageWidth: pageRect.width,
            margin: margin
        )
        
        if let notes = estimate.notes, !notes.isEmpty {
            yPosition = drawSection(
                context: context,
                title: "Notes:",
                content: notes,
                startY: yPosition,
                margin: margin
            )
        }
        
        if let terms = estimate.terms, !terms.isEmpty {
            yPosition = drawSection(
                context: context,
                title: "Terms:",
                content: terms,
                startY: yPosition,
                margin: margin
            )
        }
        
        drawFooter(
            context: context,
            pageRect: pageRect,
            margin: margin
        )
        
        context.endPDFPage()
        context.closePDF()
        
        return PDFDocument(data: pdfData as Data)
    }
    
    // MARK: - Drawing Methods
    
    private func drawInvoiceContent(
        context: CGContext,
        invoice: Invoice,
        customer: Customer,
        companyInfo: CompanyInfo,
        pageRect: CGRect
    ) {
        let margin: CGFloat = 50
        var yPosition: CGFloat = pageRect.height - margin
        
        // Draw company header
        yPosition = drawCompanyHeader(
            context: context,
            companyInfo: companyInfo,
            startY: yPosition,
            pageWidth: pageRect.width,
            margin: margin
        )
        
        yPosition -= 30
        
        // Draw invoice title
        yPosition = drawText(
            context: context,
            text: "INVOICE",
            x: margin,
            y: yPosition,
            fontSize: 24,
            bold: true
        )
        
        yPosition -= 30
        
        // Draw invoice details
        yPosition = drawInvoiceDetails(
            context: context,
            invoice: invoice,
            startY: yPosition,
            pageWidth: pageRect.width,
            margin: margin
        )
        
        yPosition -= 20
        
        // Draw customer info
        yPosition = drawCustomerInfo(
            context: context,
            customer: customer,
            startY: yPosition,
            margin: margin
        )
        
        yPosition -= 30
        
        // Draw line items table
        yPosition = drawLineItemsTable(
            context: context,
            invoice: invoice,
            startY: yPosition,
            pageWidth: pageRect.width,
            margin: margin
        )
        
        yPosition -= 30
        
        // Draw totals
        yPosition = drawTotals(
            context: context,
            invoice: invoice,
            startY: yPosition,
            pageWidth: pageRect.width,
            margin: margin
        )
        
        yPosition -= 40
        
        // Draw notes and terms
        if let notes = invoice.notes, !notes.isEmpty {
            yPosition = drawSection(
                context: context,
                title: "Notes:",
                content: notes,
                startY: yPosition,
                margin: margin
            )
            yPosition -= 20
        }
        
        if let terms = invoice.terms, !terms.isEmpty {
            yPosition = drawSection(
                context: context,
                title: "Payment Terms:",
                content: terms,
                startY: yPosition,
                margin: margin
            )
        }
        
        // Draw footer
        drawFooter(
            context: context,
            pageRect: pageRect,
            margin: margin
        )
    }

    private func drawEstimateDetails(
        context: CGContext,
        estimate: Estimate,
        startY: CGFloat,
        pageWidth: CGFloat,
        margin: CGFloat
    ) -> CGFloat {
        var y = startY
        let rightColumnX = pageWidth - margin - 200
        
        y = drawText(
            context: context,
            text: "Estimate #: \(estimate.formattedEstimateNumber)",
            x: margin,
            y: y,
            fontSize: 11,
            bold: true
        )
        
        if let status = estimate.status?.capitalized {
            y = drawText(
                context: context,
                text: "Status: \(status)",
                x: margin,
                y: y,
                fontSize: 10
            )
            y -= 5
        } else {
            y -= 10
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        var rightY = startY
        if let issueDate = estimate.issueDate {
            rightY = drawText(
                context: context,
                text: "Issue Date: \(dateFormatter.string(from: issueDate))",
                x: rightColumnX,
                y: rightY,
                fontSize: 10
            )
            rightY -= 5
        }
        
        if let validUntil = estimate.validUntil {
            rightY = drawText(
                context: context,
                text: "Valid Until: \(dateFormatter.string(from: validUntil))",
                x: rightColumnX,
                y: rightY,
                fontSize: 10
            )
        }
        
        return min(y, rightY) - 15
    }
    
    private func drawCompanyHeader(
        context: CGContext,
        companyInfo: CompanyInfo,
        startY: CGFloat,
        pageWidth: CGFloat,
        margin: CGFloat
    ) -> CGFloat {
        var y = startY
        
        // Company name
        y = drawText(
            context: context,
            text: companyInfo.name,
            x: margin,
            y: y,
            fontSize: 20,
            bold: true
        )
        
        y -= 5
        
        // Company details
        if !companyInfo.address.isEmpty {
            y = drawText(context: context, text: companyInfo.address, x: margin, y: y, fontSize: 10)
            y -= 5
        }
        
        if !companyInfo.phone.isEmpty {
            y = drawText(context: context, text: "Phone: \(companyInfo.phone)", x: margin, y: y, fontSize: 10)
            y -= 5
        }
        
        if !companyInfo.email.isEmpty {
            y = drawText(context: context, text: "Email: \(companyInfo.email)", x: margin, y: y, fontSize: 10)
            y -= 5
        }
        
        // Draw horizontal line
        y -= 10
        context.setStrokeColor(NSColor.gray.cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: margin, y: y))
        context.addLine(to: CGPoint(x: pageWidth - margin, y: y))
        context.strokePath()
        
        return y - 10
    }
    
    private func drawInvoiceDetails(
        context: CGContext,
        invoice: Invoice,
        startY: CGFloat,
        pageWidth: CGFloat,
        margin: CGFloat
    ) -> CGFloat {
        var y = startY
        let rightColumnX = pageWidth - margin - 200
        
        // Left column
        y = drawText(context: context, text: "Invoice #: \(invoice.formattedInvoiceNumber)", x: margin, y: y, fontSize: 11, bold: true)
        
        // Right column - dates
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        var rightY = startY
        if let issueDate = invoice.issueDate {
            rightY = drawText(context: context, text: "Issue Date: \(dateFormatter.string(from: issueDate))", x: rightColumnX, y: rightY, fontSize: 10)
            rightY -= 5
        }
        
        if let dueDate = invoice.dueDate {
            rightY = drawText(context: context, text: "Due Date: \(dateFormatter.string(from: dueDate))", x: rightColumnX, y: rightY, fontSize: 10)
        }
        
        return min(y - 15, rightY - 15)
    }
    
    private func drawCustomerInfo(
        context: CGContext,
        customer: Customer,
        startY: CGFloat,
        margin: CGFloat
    ) -> CGFloat {
        var y = startY
        
        y = drawText(context: context, text: "Bill To:", x: margin, y: y, fontSize: 11, bold: true)
        y -= 5
        
        let customerName = "\(customer.firstName ?? "") \(customer.lastName ?? "")".trimmingCharacters(in: .whitespaces)
        if !customerName.isEmpty {
            y = drawText(context: context, text: customerName, x: margin, y: y, fontSize: 10)
            y -= 5
        }
        
        if let email = customer.email, !email.isEmpty {
            y = drawText(context: context, text: email, x: margin, y: y, fontSize: 10)
            y -= 5
        }
        
        if let phone = customer.phone, !phone.isEmpty {
            y = drawText(context: context, text: phone, x: margin, y: y, fontSize: 10)
            y -= 5
        }
        
        if let address = customer.address, !address.isEmpty {
            y = drawText(context: context, text: address, x: margin, y: y, fontSize: 10)
        }
        
        return y - 10
    }
    
    private func drawLineItemsTable(
        context: CGContext,
        invoice: Invoice,
        startY: CGFloat,
        pageWidth: CGFloat,
        margin: CGFloat
    ) -> CGFloat {
        var y = startY
        let tableWidth = pageWidth - (margin * 2)
        
        // Table header
        let headerHeight: CGFloat = 25
        let rowHeight: CGFloat = 20
        
        // Draw header background
        context.setFillColor(NSColor.lightGray.withAlphaComponent(0.3).cgColor)
        context.fill(CGRect(x: margin, y: y - headerHeight, width: tableWidth, height: headerHeight))
        
        // Header text
        let descX = margin + 5
        let qtyX = pageWidth - margin - 250
        let priceX = pageWidth - margin - 150
        let totalX = pageWidth - margin - 80
        
        y -= 18
        drawText(context: context, text: "Description", x: descX, y: y, fontSize: 10, bold: true)
        drawText(context: context, text: "Qty", x: qtyX, y: y, fontSize: 10, bold: true)
        drawText(context: context, text: "Unit Price", x: priceX, y: y, fontSize: 10, bold: true)
        drawText(context: context, text: "Total", x: totalX, y: y, fontSize: 10, bold: true)
        
        y -= 10
        
        // Draw header border
        context.setStrokeColor(NSColor.gray.cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: margin, y: y))
        context.addLine(to: CGPoint(x: pageWidth - margin, y: y))
        context.strokePath()
        
        y -= 5
        
        // Draw line items
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        
        for lineItem in invoice.lineItemsArray {
            y -= rowHeight
            
            let description = lineItem.itemDescription ?? ""
            drawText(context: context, text: description, x: descX, y: y, fontSize: 9)
            
            let qty = lineItem.formattedQuantity
            drawText(context: context, text: qty, x: qtyX, y: y, fontSize: 9)
            
            let price = lineItem.formattedUnitPrice
            drawText(context: context, text: price, x: priceX, y: y, fontSize: 9)
            
            let total = lineItem.formattedTotal
            drawText(context: context, text: total, x: totalX, y: y, fontSize: 9)
        }
        
        y -= 10
        
        // Draw bottom border
        context.setStrokeColor(NSColor.gray.cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: margin, y: y))
        context.addLine(to: CGPoint(x: pageWidth - margin, y: y))
        context.strokePath()
        
        return y - 10
    }

    private func drawEstimateLineItemsTable(
        context: CGContext,
        estimate: Estimate,
        startY: CGFloat,
        pageWidth: CGFloat,
        margin: CGFloat
    ) -> CGFloat {
        var y = startY
        let tableWidth = pageWidth - (margin * 2)
        let headerHeight: CGFloat = 25
        let rowHeight: CGFloat = 20
        
        context.setFillColor(NSColor.lightGray.withAlphaComponent(0.3).cgColor)
        context.fill(CGRect(x: margin, y: y - headerHeight, width: tableWidth, height: headerHeight))
        
        let descX = margin + 5
        let qtyX = pageWidth - margin - 250
        let priceX = pageWidth - margin - 150
        let totalX = pageWidth - margin - 80
        
        y -= 18
        drawText(context: context, text: "Description", x: descX, y: y, fontSize: 10, bold: true)
        drawText(context: context, text: "Qty", x: qtyX, y: y, fontSize: 10, bold: true)
        drawText(context: context, text: "Unit Price", x: priceX, y: y, fontSize: 10, bold: true)
        drawText(context: context, text: "Total", x: totalX, y: y, fontSize: 10, bold: true)
        
        y -= 10
        context.setStrokeColor(NSColor.gray.cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: margin, y: y))
        context.addLine(to: CGPoint(x: pageWidth - margin, y: y))
        context.strokePath()
        
        y -= 5
        
        for lineItem in estimate.lineItemsArray {
            y -= rowHeight
            
            let description = lineItem.itemDescription ?? ""
            drawText(context: context, text: description, x: descX, y: y, fontSize: 9)
            
            drawText(context: context, text: lineItem.formattedQuantity, x: qtyX, y: y, fontSize: 9)
            drawText(context: context, text: lineItem.formattedUnitPrice, x: priceX, y: y, fontSize: 9)
            drawText(context: context, text: lineItem.formattedTotal, x: totalX, y: y, fontSize: 9)
        }
        
        y -= 10
        context.setStrokeColor(NSColor.gray.cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: margin, y: y))
        context.addLine(to: CGPoint(x: pageWidth - margin, y: y))
        context.strokePath()
        
        return y - 10
    }
    
    private func drawTotals(
        context: CGContext,
        invoice: Invoice,
        startY: CGFloat,
        pageWidth: CGFloat,
        margin: CGFloat
    ) -> CGFloat {
        var y = startY
        let labelX = pageWidth - margin - 200
        let valueX = pageWidth - margin - 80
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        
        // Subtotal
        y = drawText(context: context, text: "Subtotal:", x: labelX, y: y, fontSize: 10)
        drawText(context: context, text: formatter.string(from: invoice.subtotal as NSDecimalNumber) ?? "$0.00", x: valueX, y: y, fontSize: 10)
        y -= 15
        
        // Tax
        if invoice.taxRate > 0 {
            let taxLabel = "Tax (\(invoice.taxRate)%):"
            y = drawText(context: context, text: taxLabel, x: labelX, y: y, fontSize: 10)
            drawText(context: context, text: formatter.string(from: invoice.taxAmount as NSDecimalNumber) ?? "$0.00", x: valueX, y: y, fontSize: 10)
            y -= 15
        }
        
        // Total
        y = drawText(context: context, text: "Total:", x: labelX, y: y, fontSize: 12, bold: true)
        drawText(context: context, text: formatter.string(from: invoice.total as NSDecimalNumber) ?? "$0.00", x: valueX, y: y, fontSize: 12, bold: true)
        y -= 20
        
        // Amount Paid
        if invoice.amountPaid > 0 {
            y = drawText(context: context, text: "Amount Paid:", x: labelX, y: y, fontSize: 10)
            drawText(context: context, text: formatter.string(from: invoice.amountPaid as NSDecimalNumber) ?? "$0.00", x: valueX, y: y, fontSize: 10)
            y -= 15
            
            // Balance Due
            y = drawText(context: context, text: "Balance Due:", x: labelX, y: y, fontSize: 11, bold: true)
            drawText(context: context, text: formatter.string(from: invoice.balance as NSDecimalNumber) ?? "$0.00", x: valueX, y: y, fontSize: 11, bold: true)
        }
        
        return y - 10
    }

    private func drawEstimateTotals(
        context: CGContext,
        estimate: Estimate,
        startY: CGFloat,
        pageWidth: CGFloat,
        margin: CGFloat
    ) -> CGFloat {
        var y = startY
        let labelX = pageWidth - margin - 200
        let valueX = pageWidth - margin - 80
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        
        y = drawText(context: context, text: "Subtotal:", x: labelX, y: y, fontSize: 10)
        drawText(context: context, text: formatter.string(from: estimate.subtotal as NSDecimalNumber) ?? "$0.00", x: valueX, y: y, fontSize: 10)
        y -= 15
        
        if estimate.taxRate > .zero {
            let taxValue = NSDecimalNumber(decimal: estimate.taxRate).doubleValue
            let taxLabel = String(format: "Tax (%.2f%%):", taxValue)
            y = drawText(context: context, text: taxLabel, x: labelX, y: y, fontSize: 10)
            drawText(context: context, text: formatter.string(from: estimate.taxAmount as NSDecimalNumber) ?? "$0.00", x: valueX, y: y, fontSize: 10)
            y -= 15
        }
        
        y = drawText(context: context, text: "Total:", x: labelX, y: y, fontSize: 12, bold: true)
        drawText(context: context, text: formatter.string(from: estimate.total as NSDecimalNumber) ?? "$0.00", x: valueX, y: y, fontSize: 12, bold: true)
        
        return y - 10
    }
    
    private func drawSection(
        context: CGContext,
        title: String,
        content: String,
        startY: CGFloat,
        margin: CGFloat
    ) -> CGFloat {
        var y = startY
        
        y = drawText(context: context, text: title, x: margin, y: y, fontSize: 10, bold: true)
        y -= 5
        y = drawText(context: context, text: content, x: margin, y: y, fontSize: 9)
        
        return y - 10
    }
    
    private func drawFooter(
        context: CGContext,
        pageRect: CGRect,
        margin: CGFloat
    ) {
        let footerY: CGFloat = 30
        let footerText = "Thank you for your business!"
        
        drawText(
            context: context,
            text: footerText,
            x: pageRect.width / 2 - 80,
            y: footerY,
            fontSize: 10,
            color: NSColor.gray
        )
    }
    
    // MARK: - Text Drawing Helper
    
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
        
        return y - fontSize - 5
    }
    
    // MARK: - Save PDF
    
    /// Save PDF to file
    func savePDF(_ pdfDocument: PDFDocument, to url: URL) -> Bool {
        return pdfDocument.write(to: url)
    }
    
    /// Get temporary PDF URL
    func getTemporaryPDFURL(for invoiceNumber: String) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "Invoice_\(invoiceNumber)_\(Date().timeIntervalSince1970).pdf"
        return tempDir.appendingPathComponent(fileName)
    }
}

// MARK: - Company Info Model

struct CompanyInfo {
    var name: String
    var address: String
    var phone: String
    var email: String
    var website: String
    
    static var `default`: CompanyInfo {
        CompanyInfo(
            name: "Your Company Name",
            address: "123 Main St, City, State 12345",
            phone: "(555) 123-4567",
            email: "info@yourcompany.com",
            website: "www.yourcompany.com"
        )
    }
}
