//
//  FormService.swift
//  ProTech
//
//  Form template management and PDF generation with print support
//

import Foundation
import PDFKit
import AppKit
import CoreData

class FormService {
    static let shared = FormService()
    private let coreDataManager = CoreDataManager.shared
    
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

        // Load default estimate template
        if let estimateJSON = defaultEstimateFormJSON() {
            let template = FormTemplate(context: context)
            template.id = UUID()
            template.name = "Repair Estimate Form"
            template.type = "estimate"
            template.templateJSON = estimateJSON
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
        for field in formTemplate.fields {
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
            if field.type == .signature, let signatureData = submission.signatureData {
                if let signatureImage = NSImage(data: signatureData) {
                    let imageRect = CGRect(x: leftMargin, y: yPosition - 60, width: 200, height: 60)
                    signatureImage.draw(in: imageRect)
                    yPosition -= 70
                }
            } else {
                let value = answers[field.id.uuidString] ?? "(No answer provided)"
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
                FormField(id: UUID(), type: .text, label: "Customer Name", placeholder: "John Doe", isRequired: true, options: nil, defaultValue: nil, order: 0),
                FormField(id: UUID(), type: .phone, label: "Phone Number", placeholder: "+1 (555) 123-4567", isRequired: true, options: nil, defaultValue: nil, order: 1),
                FormField(id: UUID(), type: .email, label: "Email Address", placeholder: "john@example.com", isRequired: false, options: nil, defaultValue: nil, order: 2),
                FormField(id: UUID(), type: .dropdown, label: "Device Type", placeholder: nil, isRequired: true, options: ["iPhone", "iPad", "Mac", "Android Phone", "Android Tablet", "Other"], defaultValue: nil, order: 3),
                FormField(id: UUID(), type: .text, label: "Device Model", placeholder: "iPhone 14 Pro", isRequired: false, options: nil, defaultValue: nil, order: 4),
                FormField(id: UUID(), type: .multiline, label: "Issue Description", placeholder: "Describe the problem...", isRequired: true, options: nil, defaultValue: nil, order: 5),
                FormField(id: UUID(), type: .checkbox, label: "Repair Authorization", placeholder: nil, isRequired: true, options: ["I authorize the repair and agree to the terms"], defaultValue: nil, order: 6),
                FormField(id: UUID(), type: .signature, label: "Customer Signature", placeholder: nil, isRequired: true, options: nil, defaultValue: nil, order: 7)
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
                FormField(id: UUID(), type: .text, label: "Customer Name", placeholder: nil, isRequired: true, options: nil, defaultValue: nil, order: 0),
                FormField(id: UUID(), type: .multiline, label: "Work Performed", placeholder: nil, isRequired: true, options: nil, defaultValue: nil, order: 1),
                FormField(id: UUID(), type: .multiline, label: "Parts Used", placeholder: nil, isRequired: false, options: nil, defaultValue: nil, order: 2),
                FormField(id: UUID(), type: .number, label: "Total Cost", placeholder: "0.00", isRequired: true, options: nil, defaultValue: nil, order: 3),
                FormField(id: UUID(), type: .dropdown, label: "Warranty Period", placeholder: nil, isRequired: false, options: ["No Warranty", "30 Days", "60 Days", "90 Days", "1 Year"], defaultValue: nil, order: 4),
                FormField(id: UUID(), type: .signature, label: "Customer Signature", placeholder: nil, isRequired: true, options: nil, defaultValue: nil, order: 5)
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

    private func defaultEstimateFormJSON() -> String? {
        let template = FormTemplateModel(
            id: "estimate-default",
            name: "Repair Estimate Form",
            type: "estimate",
            companyName: "Your Store Name",
            companyLogo: nil,
            headerText: "Repair Estimate",
            footerText: "Please approve the estimate to proceed with the repair.",
            fields: [
                FormField(id: UUID(), type: .text, label: "Customer Name", placeholder: "John Doe", isRequired: true, options: nil, defaultValue: nil, order: 0),
                FormField(id: UUID(), type: .text, label: "Device", placeholder: "Device make/model", isRequired: true, options: nil, defaultValue: nil, order: 1),
                FormField(id: UUID(), type: .multiline, label: "Issues Found", placeholder: "Summary of issues", isRequired: true, options: nil, defaultValue: nil, order: 2),
                FormField(id: UUID(), type: .multiline, label: "Recommended Repairs", placeholder: "List recommended repairs", isRequired: true, options: nil, defaultValue: nil, order: 3),
                FormField(id: UUID(), type: .number, label: "Parts Cost", placeholder: "0.00", isRequired: true, options: nil, defaultValue: nil, order: 4),
                FormField(id: UUID(), type: .number, label: "Labor Cost", placeholder: "0.00", isRequired: true, options: nil, defaultValue: nil, order: 5),
                FormField(id: UUID(), type: .number, label: "Estimated Total", placeholder: "0.00", isRequired: true, options: nil, defaultValue: nil, order: 6),
                FormField(id: UUID(), type: .dropdown, label: "Customer Decision", placeholder: nil, isRequired: false, options: ["Pending", "Approved", "Declined"], defaultValue: "Pending", order: 7),
                FormField(id: UUID(), type: .signature, label: "Customer Signature", placeholder: nil, isRequired: false, options: nil, defaultValue: nil, order: 8)
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

struct FormFieldOld: Codable, Identifiable, Hashable {
    let id: String
    let type: String
    let label: String
    let placeholder: String?
    let required: Bool
    let defaultValue: String?
    let options: [String]?
    let rows: Int?
}

// MARK: - CRUD Operations

extension FormService {
    func createTemplate(name: String, type: String, fields: [FormField], description: String? = nil, instructions: String? = nil) -> FormTemplate {
        let context = coreDataManager.viewContext
        let template = FormTemplate(context: context)
        template.id = UUID()
        template.name = name
        template.type = type
        template.setFields(fields, description: description, instructions: instructions)
        template.isDefault = false
        template.createdAt = Date()
        template.updatedAt = Date()
        
        coreDataManager.save()
        return template
    }
    
    func updateTemplate(_ template: FormTemplate, name: String? = nil, fields: [FormField]? = nil, description: String? = nil, instructions: String? = nil) {
        if let name = name {
            template.name = name
        }
        if let fields = fields {
            template.setFields(fields, description: description, instructions: instructions)
        }
        template.updatedAt = Date()
        coreDataManager.save()
    }
    
    func deleteTemplate(_ template: FormTemplate) {
        coreDataManager.viewContext.delete(template)
        coreDataManager.save()
    }
    
    func createSubmission(for template: FormTemplate, responses: [String: String], submitterName: String? = nil, submitterEmail: String? = nil, signatureData: Data? = nil) -> FormSubmission {
        let context = coreDataManager.viewContext
        let submission = FormSubmission(context: context)
        submission.id = UUID()
        submission.formID = template.id
        submission.setResponses(responses, submitterName: submitterName, submitterEmail: submitterEmail)
        submission.submittedAt = Date()
        submission.signatureData = signatureData
        
        coreDataManager.save()
        return submission
    }
    
    // MARK: - PDF Generation with New Models
    
    func generateFormPDF(for template: FormTemplate, submission: FormSubmission? = nil) -> PDFDocument? {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter
        
        let pdfMetaData = [
            kCGPDFContextTitle as String: template.name ?? "Form",
            kCGPDFContextCreator as String: "ProTech"
        ]
        
        guard let pdfData = createFormPDF(
            pageRect: pageRect,
            metaData: pdfMetaData,
            template: template,
            submission: submission
        ) else {
            return nil
        }
        
        return PDFDocument(data: pdfData)
    }
    
    private func createFormPDF(pageRect: CGRect, metaData: [String: Any], template: FormTemplate, submission: FormSubmission?) -> Data? {
        let pdfData = NSMutableData()
        
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
              let pdfContext = CGContext(consumer: consumer, mediaBox: nil, metaData as CFDictionary) else {
            return nil
        }
        
        let pageInfo: CFDictionary? = nil
        pdfContext.beginPDFPage(pageInfo)
        
        var yPosition: CGFloat = pageRect.height - 50
        let leftMargin: CGFloat = 50
        let rightMargin: CGFloat = pageRect.width - 50
        
        // Draw header
        if let name = template.name {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: 20),
                .foregroundColor: NSColor.black
            ]
            let size = name.size(withAttributes: attrs)
            name.draw(at: CGPoint(x: leftMargin, y: yPosition - size.height), withAttributes: attrs)
            yPosition -= size.height + 20
        }
        
        // Draw description if available
        if let description = template.templateData?.description {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 12),
                .foregroundColor: NSColor.darkGray
            ]
            let size = description.size(withAttributes: attrs)
            description.draw(at: CGPoint(x: leftMargin, y: yPosition - size.height), withAttributes: attrs)
            yPosition -= size.height + 15
        }
        
        // Draw date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        let dateString = "Date: \(dateFormatter.string(from: submission?.submittedAt ?? Date()))"
        let dateAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10),
            .foregroundColor: NSColor.gray
        ]
        let dateSize = dateString.size(withAttributes: dateAttrs)
        dateString.draw(at: CGPoint(x: leftMargin, y: yPosition - dateSize.height), withAttributes: dateAttrs)
        yPosition -= dateSize.height + 20
        
        // Draw separator
        pdfContext.setStrokeColor(NSColor.lightGray.cgColor)
        pdfContext.setLineWidth(1)
        pdfContext.move(to: CGPoint(x: leftMargin, y: yPosition))
        pdfContext.addLine(to: CGPoint(x: rightMargin, y: yPosition))
        pdfContext.strokePath()
        yPosition -= 25
        
        // Draw fields
        let fields = template.fields
        let responses = submission?.responses ?? [:]
        
        for field in fields {
            // Check if we need a new page
            if yPosition < 100 {
                pdfContext.endPDFPage()
                pdfContext.beginPDFPage(pageInfo)
                yPosition = pageRect.height - 50
            }
            
            // Field label
            let labelText = field.label + (field.isRequired ? " *" : "")
            let labelAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: 11),
                .foregroundColor: NSColor.black
            ]
            let labelSize = labelText.size(withAttributes: labelAttrs)
            labelText.draw(at: CGPoint(x: leftMargin, y: yPosition - labelSize.height), withAttributes: labelAttrs)
            yPosition -= labelSize.height + 8
            
            // Field value or input area
            if let submission = submission {
                if field.type == .signature, let signatureData = submission.signatureData {
                    if let signatureImage = NSImage(data: signatureData) {
                        let imageRect = CGRect(x: leftMargin, y: yPosition - 50, width: 200, height: 50)
                        signatureImage.draw(in: imageRect)
                        yPosition -= 60
                    }
                } else {
                    let value = responses[field.id.uuidString] ?? "(No answer provided)"
                    let valueAttrs: [NSAttributedString.Key: Any] = [
                        .font: NSFont.systemFont(ofSize: 10),
                        .foregroundColor: NSColor.darkGray
                    ]
                    let textRect = CGRect(x: leftMargin, y: yPosition - 40, width: rightMargin - leftMargin, height: 40)
                    value.draw(in: textRect, withAttributes: valueAttrs)
                    yPosition -= 50
                }
            } else {
                // Draw empty field for blank form
                pdfContext.setStrokeColor(NSColor.lightGray.cgColor)
                pdfContext.setLineWidth(0.5)
                let lineY = yPosition - 5
                pdfContext.move(to: CGPoint(x: leftMargin, y: lineY))
                pdfContext.addLine(to: CGPoint(x: rightMargin, y: lineY))
                pdfContext.strokePath()
                yPosition -= 30
            }
            
            yPosition -= 10
        }
        
        // Draw footer
        let footerText = "Generated by ProTech - \(Date().formatted())"
        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 8),
            .foregroundColor: NSColor.gray
        ]
        footerText.draw(at: CGPoint(x: leftMargin, y: 30), withAttributes: footerAttrs)
        
        pdfContext.endPDFPage()
        pdfContext.closePDF()
        
        return pdfData as Data
    }
}
