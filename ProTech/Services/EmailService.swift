//
//  EmailService.swift
//  ProTech
//
//  Email service for sending estimates, invoices, and notifications
//

import Foundation
import AppKit
import PDFKit

class EmailService {
    static let shared = EmailService()
    
    private init() {}
    
    // MARK: - Public API
    
    /// Send an email with optional PDF attachment using native Mail.app
    func sendEmail(
        to recipient: String,
        subject: String,
        body: String,
        pdfAttachment: PDFDocument? = nil,
        attachmentFileName: String? = nil
    ) -> Bool {
        return sendViaMailApp(
            to: recipient,
            subject: subject,
            body: body,
            pdfAttachment: pdfAttachment,
            attachmentFileName: attachmentFileName
        )
    }
    
    /// Send estimate via email
    func sendEstimate(
        estimate: Estimate,
        customer: Customer,
        pdfDocument: PDFDocument
    ) -> Bool {
        let estimateNumber = estimate.estimateNumber ?? "EST-\(estimate.id?.uuidString.prefix(8) ?? "")"
        let subject = "Estimate #\(estimateNumber) from \(Configuration.appName)"
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        let totalString = formatter.string(from: estimate.total as NSDecimalNumber) ?? "$0.00"
        
        let body = """
        Dear \(customer.displayName),
        
        Please find attached your estimate #\(estimateNumber).
        
        Estimate Total: \(totalString)
        
        If you have any questions or would like to proceed with this estimate, please contact us.
        
        Thank you for your business!
        
        Best regards,
        \(Configuration.appName)
        """
        
        guard let email = customer.email, !email.isEmpty else {
            print("❌ Customer has no email address")
            return false
        }
        
        return sendEmail(
            to: email,
            subject: subject,
            body: body,
            pdfAttachment: pdfDocument,
            attachmentFileName: "Estimate-\(estimateNumber).pdf"
        )
    }
    
    /// Send invoice via email
    func sendInvoice(
        invoice: Invoice,
        customer: Customer,
        pdfDocument: PDFDocument
    ) -> Bool {
        let invoiceNumber = invoice.invoiceNumber ?? "INV-\(invoice.id?.uuidString.prefix(8) ?? "")"
        let subject = "Invoice #\(invoiceNumber) from \(Configuration.appName)"
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        let totalString = formatter.string(from: invoice.total as NSDecimalNumber) ?? "$0.00"
        let balanceString = formatter.string(from: invoice.balance as NSDecimalNumber) ?? "$0.00"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let dueDateString = invoice.dueDate.map { dateFormatter.string(from: $0) } ?? "Upon receipt"
        
        let body = """
        Dear \(customer.displayName),
        
        Please find attached your invoice #\(invoiceNumber).
        
        Invoice Total: \(totalString)
        Balance Due: \(balanceString)
        Due Date: \(dueDateString)
        
        Please remit payment at your earliest convenience.
        
        Thank you for your business!
        
        Best regards,
        \(Configuration.appName)
        """
        
        guard let email = customer.email, !email.isEmpty else {
            print("❌ Customer has no email address")
            return false
        }
        
        return sendEmail(
            to: email,
            subject: subject,
            body: body,
            pdfAttachment: pdfDocument,
            attachmentFileName: "Invoice-\(invoiceNumber).pdf"
        )
    }
    
    /// Send recurring invoice via email
    func sendRecurringInvoice(
        invoice: Invoice,
        customer: Customer,
        pdfDocument: PDFDocument
    ) async throws {
        let success = sendInvoice(invoice: invoice, customer: customer, pdfDocument: pdfDocument)
        
        if !success {
            throw EmailError.sendFailed("Failed to send recurring invoice")
        }
    }
    
    /// Send admin notification for recurring invoice failures
    func notifyAdminOfFailure(
        recurringInvoice: RecurringInvoice,
        customer: Customer,
        error: Error
    ) {
        // In production, this should email the admin
        // For now, we'll log it prominently
        print("⚠️ ADMIN ALERT: Recurring invoice failed to send")
        print("   Customer: \(customer.displayName)")
        print("   Error: \(error.localizedDescription)")
        
        // TODO: Send actual admin notification email when admin email is configured
        // This could be sent to a configured admin email address from Settings
    }
    
    // MARK: - Private Implementation
    
    private func sendViaMailApp(
        to recipient: String,
        subject: String,
        body: String,
        pdfAttachment: PDFDocument?,
        attachmentFileName: String?
    ) -> Bool {
        // Create mailto URL with subject and body
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = recipient
        
        var queryItems: [URLQueryItem] = []
        queryItems.append(URLQueryItem(name: "subject", value: subject))
        queryItems.append(URLQueryItem(name: "body", value: body))
        components.queryItems = queryItems
        
        guard let mailtoURL = components.url else {
            print("❌ Failed to create mailto URL")
            return false
        }
        
        // If there's a PDF attachment, we need to use NSSharingService
        if let pdfDocument = pdfAttachment {
            return sendWithAttachment(
                to: recipient,
                subject: subject,
                body: body,
                pdfDocument: pdfDocument,
                fileName: attachmentFileName ?? "document.pdf"
            )
        } else {
            // No attachment, just open mailto URL
            NSWorkspace.shared.open(mailtoURL)
            return true
        }
    }
    
    private func sendWithAttachment(
        to recipient: String,
        subject: String,
        body: String,
        pdfDocument: PDFDocument,
        fileName: String
    ) -> Bool {
        // Save PDF to temporary location
        let tempDirectory = FileManager.default.temporaryDirectory
        let pdfURL = tempDirectory.appendingPathComponent(fileName)
        
        guard pdfDocument.write(to: pdfURL) else {
            print("❌ Failed to write PDF to temporary location")
            return false
        }
        
        // Create email content
        let emailContent = """
        To: \(recipient)
        Subject: \(subject)
        
        \(body)
        """
        
        // Use NSSharingService to send email with attachment
        guard let sharingService = NSSharingService(named: .composeEmail) else {
            print("❌ Email sharing service not available")
            // Fallback: just open the file and let user attach it manually
            NSWorkspace.shared.open(pdfURL)
            return false
        }
        
        // Set up the sharing service
        sharingService.recipients = [recipient]
        sharingService.subject = subject
        
        // Perform the share
        DispatchQueue.main.async {
            sharingService.perform(withItems: [pdfURL, emailContent])
        }
        
        return true
    }
    
    /// Send payment receipt via email
    func sendReceipt(
        payment: Payment,
        customer: Customer,
        pdfURL: URL,
        recipientEmail: String
    ) -> Bool {
        guard let pdfDocument = PDFDocument(url: pdfURL) else {
            return false
        }
        
        let receiptNumber = payment.formattedPaymentNumber
        let subject = "Payment Receipt #\(receiptNumber) from \(Configuration.appName)"
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        let amountString = formatter.string(from: payment.amount as NSDecimalNumber) ?? "$0.00"
        
        let body = """
        Dear \(customer.displayName),
        
        Thank you for your payment!
        
        Receipt #: \(receiptNumber)
        Amount Paid: \(amountString)
        Payment Method: \(payment.paymentMethodDisplayName)
        
        Please find your payment receipt attached.
        
        Thank you for your business!
        
        Best regards,
        \(Configuration.appName)
        """
        
        return sendEmail(
            to: recipientEmail,
            subject: subject,
            body: body,
            pdfAttachment: pdfDocument,
            attachmentFileName: "Receipt_\(receiptNumber).pdf"
        )
    }
}

// MARK: - Error Types

enum EmailError: LocalizedError {
    case sendFailed(String)
    case noRecipient
    case invalidAttachment
    
    var errorDescription: String? {
        switch self {
        case .sendFailed(let message):
            return "Email send failed: \(message)"
        case .noRecipient:
            return "No recipient email address provided"
        case .invalidAttachment:
            return "Invalid email attachment"
        }
    }
}

// MARK: - Helper Extensions
// Note: Customer.displayName is defined in Customer.swift model
