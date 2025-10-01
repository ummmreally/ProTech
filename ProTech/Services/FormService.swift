//
//  FormService.swift
//  TechStorePro
//
//  Form template management and PDF generation
//

import Foundation
import PDFKit
import AppKit

class FormService {
    static let shared = FormService()
    
    private init() {}
    
    // MARK: - Load Default Templates
    
    func loadDefaultTemplates() {
        let context = CoreDataManager.shared.viewContext
        
        // Check if templates already exist
        let fetchRequest = FormTemplate.fetchRequest()
        let count = (try? context.count(for: fetchRequest)) ?? 0
        if count > 0 { return }
        
        // Load default intake template
        if let intakeJSON = defaultIntakeFormJSON() {
            let template = FormTemplate(context: context)
            template.id = UUID()
            template.name = "Device Intake Form"
            template.type = "intake"
            template.templateJSON = intakeJSON
            template.isDefault = true
            template.createdAt = Date()
            template.updatedAt = Date()
        }
        
        // Load default pickup template
        if let pickupJSON = defaultPickupFormJSON() {
            let template = FormTemplate(context: context)
            template.id = UUID()
            template.name = "Service Completion Form"
            template.type = "pickup"
            template.templateJSON = pickupJSON
            template.isDefault = true
            template.createdAt = Date()
            template.updatedAt = Date()
        }
        
        CoreDataManager.shared.save()
    }
    
    // MARK: - Generate PDF
    
    func generatePDF(submission: FormSubmission, template: FormTemplate) -> PDFDocument? {
        guard let templateData = template.templateJSON?.data(using: .utf8),
              let formTemplate = try? JSONDecoder().decode(FormTemplateModel.self, from: templateData),
              let submissionData = submission.dataJSON?.data(using: .utf8),
              let answers = try? JSONDecoder().decode([String: String].self, from: submissionData) else {
            return nil
        }
        
        // Create PDF context
        let pdfMetaData = [
            kCGPDFContextTitle as String: formTemplate.name,
            kCGPDFContextCreator as String: Configuration.appName
        ]
        
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter 8.5" x 11"
        
        guard let pdfData = createPDFData(
            pageRect: pageRect,
            metaData: pdfMetaData,
            formTemplate: formTemplate,
            answers: answers,
            submission: submission
        ) else {
            return nil
        }
        
        return PDFDocument(data: pdfData)
    }
    
    private func createPDFData(
        pageRect: CGRect,
        metaData: [String: Any],
        formTemplate: FormTemplateModel,
        answers: [String: String],
        submission: FormSubmission
    ) -> Data? {
        
        let renderer = NSGraphicsContext.current
        let pdfData = NSMutableData()
        
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
              let pdfContext = CGContext(consumer: consumer, mediaBox: nil, metaData as CFDictionary) else {
            return nil
        }
        
        NSGraphicsContext.current = NSGraphicsContext(cgContext: pdfContext, flipped: false)
        
        let pageInfo: CFDictionary? = nil
        pdfContext.beginPDFPage(pageInfo)
        
        var yPosition: CGFloat = pageRect.height - 50
        let leftMargin: CGFloat = 50
        let rightMargin: CGFloat = pageRect.width - 50
        
        // Draw company name
        if let companyName = formTemplate.companyName {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: 24),
                .foregroundColor: NSColor.black
            ]
            let size = companyName.size(withAttributes: attrs)
            companyName.draw(at: CGPoint(x: leftMargin, y: yPosition - size.height), withAttributes: attrs)
            yPosition -= size.height + 20
        }
        
        // Draw header
        if let headerText = formTemplate.headerText {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 18),
                .foregroundColor: NSColor.darkGray
            ]
            let size = headerText.size(withAttributes: attrs)
            headerText.draw(at: CGPoint(x: leftMargin, y: yPosition - size.height), withAttributes: attrs)
            yPosition -= size.height + 15
        }
        
        // Draw date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        let dateString = "Date: \(dateFormatter.string(from: submission.submittedAt ?? Date()))"
        let dateAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: NSColor.gray
        ]
        let dateSize = dateString.size(withAttributes: dateAttrs)
        dateString.draw(at: CGPoint(x: leftMargin, y: yPosition - dateSize.height), withAttributes: dateAttrs)
        yPosition -= dateSize.height + 20
        
        // Draw separator line
        pdfContext.setStrokeColor(NSColor.lightGray.cgColor)
        pdfContext.setLineWidth(1)
        pdfContext.move(to: CGPoint(x: leftMargin, y: yPosition))
        pdfContext.addLine(to: CGPoint(x: rightMargin, y: yPosition))
        pdfContext.strokePath()
        yPosition -= 20
        
        // Draw fields
        for field in formTemplate.fields where field.type != "divider" && field.type != "header" {
            // Check if we need a new page
            if yPosition < 100 {
                pdfContext.endPDFPage()
                pdfContext.beginPDFPage(pageInfo)
                yPosition = pageRect.height - 50
            }
            
            // Field label
            let labelAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: 12),
                .foregroundColor: NSColor.black
            ]
            let labelSize = field.label.size(withAttributes: labelAttrs)
            field.label.draw(at: CGPoint(x: leftMargin, y: yPosition - labelSize.height), withAttributes: labelAttrs)
            yPosition -= labelSize.height + 8
            
            // Field value
            if field.type == "signature", let signatureData = submission.signatureData {
                if let signatureImage = NSImage(data: signatureData) {
                    let imageRect = CGRect(x: leftMargin, y: yPosition - 60, width: 200, height: 60)
                    signatureImage.draw(in: imageRect)
                    yPosition -= 70
                }
            } else {
                let value = answers[field.id] ?? "(No answer provided)"
                let valueAttrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: 11),
                    .foregroundColor: NSColor.darkGray
                ]
                
                let textRect = CGRect(x: leftMargin, y: yPosition - 50, width: rightMargin - leftMargin, height: 50)
                let attributedString = NSAttributedString(string: value, attributes: valueAttrs)
                attributedString.draw(in: textRect)
                yPosition -= 35
            }
            
            yPosition -= 10
        }
        
        // Draw footer
        if let footerText = formTemplate.footerText {
            let footerAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 9),
                .foregroundColor: NSColor.gray
            ]
            _ = footerText.size(withAttributes: footerAttrs)
            footerText.draw(at: CGPoint(x: leftMargin, y: 30), withAttributes: footerAttrs)
        }
        
        pdfContext.endPDFPage()
        pdfContext.closePDF()
        
        NSGraphicsContext.current = renderer
        
        return pdfData as Data
    }
    
    // MARK: - Print Form
    
    func printForm(pdfDocument: PDFDocument) {
        let printInfo = NSPrintInfo.shared
        printInfo.horizontalPagination = .fit
        printInfo.verticalPagination = .fit
        printInfo.topMargin = 36
        printInfo.bottomMargin = 36
        printInfo.leftMargin = 36
        printInfo.rightMargin = 36
        
        let printOperation = pdfDocument.printOperation(
            for: printInfo,
            scalingMode: .pageScaleDownToFit,
            autoRotate: true
        )
        
        printOperation?.run()
    }
    
    // MARK: - Save PDF
    
    func savePDF(pdfDocument: PDFDocument, to url: URL) -> Bool {
        return pdfDocument.write(to: url)
    }
    
    // MARK: - Default Templates
    
    private func defaultIntakeFormJSON() -> String? {
        let template = FormTemplateModel(
            id: "intake-default",
            name: "Device Intake Form",
            type: "intake",
            companyName: "Your Store Name",
            companyLogo: nil,
            headerText: "Device Repair Authorization Form",
            footerText: "Thank you for your business!",
            fields: [
                FormField(id: "customer_name", type: "text", label: "Customer Name", placeholder: "John Doe", required: true, defaultValue: nil, options: nil, rows: nil),
                FormField(id: "customer_phone", type: "text", label: "Phone Number", placeholder: "+1 (555) 123-4567", required: true, defaultValue: nil, options: nil, rows: nil),
                FormField(id: "customer_email", type: "text", label: "Email Address", placeholder: "john@example.com", required: false, defaultValue: nil, options: nil, rows: nil),
                FormField(id: "device_type", type: "dropdown", label: "Device Type", placeholder: nil, required: true, defaultValue: nil, options: ["iPhone", "iPad", "Mac", "Android Phone", "Android Tablet", "Other"], rows: nil),
                FormField(id: "device_model", type: "text", label: "Device Model", placeholder: "iPhone 14 Pro", required: false, defaultValue: nil, options: nil, rows: nil),
                FormField(id: "issue_description", type: "textarea", label: "Issue Description", placeholder: "Describe the problem...", required: true, defaultValue: nil, options: nil, rows: 4),
                FormField(id: "terms", type: "checkbox", label: "I authorize the repair and agree to the terms", placeholder: nil, required: true, defaultValue: nil, options: nil, rows: nil),
                FormField(id: "signature", type: "signature", label: "Customer Signature", placeholder: nil, required: true, defaultValue: nil, options: nil, rows: nil)
            ]
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(template),
              let json = String(data: data, encoding: .utf8) else {
            return nil
        }
        return json
    }
    
    private func defaultPickupFormJSON() -> String? {
        let template = FormTemplateModel(
            id: "pickup-default",
            name: "Service Completion Form",
            type: "pickup",
            companyName: "Your Store Name",
            companyLogo: nil,
            headerText: "Service Completion Certificate",
            footerText: "Thank you for your business!",
            fields: [
                FormField(id: "customer_name", type: "text", label: "Customer Name", placeholder: nil, required: true, defaultValue: nil, options: nil, rows: nil),
                FormField(id: "work_performed", type: "textarea", label: "Work Performed", placeholder: nil, required: true, defaultValue: nil, options: nil, rows: 4),
                FormField(id: "parts_used", type: "textarea", label: "Parts Used", placeholder: nil, required: false, defaultValue: nil, options: nil, rows: 3),
                FormField(id: "total_cost", type: "number", label: "Total Cost", placeholder: "0.00", required: true, defaultValue: nil, options: nil, rows: nil),
                FormField(id: "warranty", type: "dropdown", label: "Warranty Period", placeholder: nil, required: false, defaultValue: nil, options: ["No Warranty", "30 Days", "60 Days", "90 Days", "1 Year"], rows: nil),
                FormField(id: "signature", type: "signature", label: "Customer Signature", placeholder: nil, required: true, defaultValue: nil, options: nil, rows: nil)
            ]
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(template),
              let json = String(data: data, encoding: .utf8) else {
            return nil
        }
        return json
    }
}

// MARK: - Models

struct FormTemplateModel: Codable {
    let id: String
    let name: String
    let type: String
    let companyName: String?
    let companyLogo: String?
    let headerText: String?
    let footerText: String?
    let fields: [FormField]
}

struct FormField: Codable, Identifiable, Hashable {
    let id: String
    let type: String
    let label: String
    let placeholder: String?
    let required: Bool
    let defaultValue: String?
    let options: [String]?
    let rows: Int?
}
