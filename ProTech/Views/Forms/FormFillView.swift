//
//  FormFillView.swift
//  ProTech
//
//  Fill out and submit forms with print support
//

import SwiftUI
import PDFKit

struct FormFillView: View {
    @Environment(\.dismiss) var dismiss
    
    let template: FormTemplate
    
    @State private var responses: [String: String] = [:]
    @State private var submitterName = ""
    @State private var submitterEmail = ""
    @State private var signatureData: Data?
    @State private var showingSignaturePad = false
    @State private var showingSaveSuccess = false
    @State private var savedSubmission: FormSubmission?
    
    private let formService = FormService.shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerView
                
                Divider()
                
                // Form
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Instructions
                        if let instructions = template.templateData?.instructions {
                            Text(instructions)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding()
                                .background(Color.blue.opacity(0.05))
                                .cornerRadius(8)
                        }
                        
                        // Submitter info
                        submitterInfoSection
                        
                        Divider()
                        
                        // Fields
                        ForEach(template.fields) { field in
                            fieldView(for: field)
                        }
                    }
                    .padding()
                }
                
                Divider()
                
                // Actions
                HStack(spacing: 12) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button {
                        printFilledForm()
                    } label: {
                        Label("Print", systemImage: "printer")
                    }
                    .buttonStyle(.bordered)
                    
                    Button {
                        exportFilledForm()
                    } label: {
                        Label("Export PDF", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Save Submission") {
                        saveSubmission()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isFormValid)
                }
                .padding()
            }
            .navigationTitle(template.name ?? "Form")
            .sheet(isPresented: $showingSignaturePad) {
                SignaturePadView(signatureData: $signatureData)
            }
            .alert("Form Saved", isPresented: $showingSaveSuccess) {
                Button("Print") {
                    if let submission = savedSubmission,
                       let pdf = formService.generateFormPDF(for: template, submission: submission) {
                        formService.printForm(pdfDocument: pdf)
                    }
                }
                Button("Done", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("Form submission saved successfully")
            }
        }
        .frame(width: 800, height: 700)
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(template.name ?? "Form")
                .font(.title)
                .fontWeight(.bold)
            
            if let description = template.templateData?.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
    
    private var submitterInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Submitter Information")
                .font(.headline)
            
            TextField("Name", text: $submitterName)
                .textFieldStyle(.roundedBorder)
            
            TextField("Email (optional)", text: $submitterEmail)
                .textFieldStyle(.roundedBorder)
        }
    }
    
    @ViewBuilder
    private func fieldView(for field: FormField) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(field.label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if field.isRequired {
                    Text("*")
                        .foregroundColor(.red)
                }
            }
            
            switch field.type {
            case .text, .email, .phone:
                TextField(field.placeholder ?? "", text: binding(for: field))
                    .textFieldStyle(.roundedBorder)
                
            case .multiline:
                TextEditor(text: binding(for: field))
                    .frame(height: 100)
                    .border(Color.gray.opacity(0.3))
                
            case .number:
                TextField(field.placeholder ?? "0", text: binding(for: field))
                    .textFieldStyle(.roundedBorder)
                
            case .date:
                DatePicker("", selection: Binding(
                    get: {
                        if let dateString = responses[field.id.uuidString],
                           let date = ISO8601DateFormatter().date(from: dateString) {
                            return date
                        }
                        return Date()
                    },
                    set: { newDate in
                        responses[field.id.uuidString] = ISO8601DateFormatter().string(from: newDate)
                    }
                ), displayedComponents: .date)
                .labelsHidden()
                
            case .dropdown:
                Picker("", selection: binding(for: field)) {
                    Text("Select...").tag("")
                    ForEach(field.options ?? [], id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.menu)
                
            case .radio:
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(field.options ?? [], id: \.self) { option in
                        Button {
                            responses[field.id.uuidString] = option
                        } label: {
                            HStack {
                                Image(systemName: responses[field.id.uuidString] == option ? "largecircle.fill.circle" : "circle")
                                Text(option)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                
            case .checkbox:
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(field.options ?? [], id: \.self) { option in
                        Toggle(option, isOn: Binding(
                            get: {
                                let selected = responses[field.id.uuidString]?.split(separator: ",").map(String.init) ?? []
                                return selected.contains(option)
                            },
                            set: { isSelected in
                                var selected = responses[field.id.uuidString]?.split(separator: ",").map(String.init) ?? []
                                if isSelected {
                                    selected.append(option)
                                } else {
                                    selected.removeAll { $0 == option }
                                }
                                responses[field.id.uuidString] = selected.joined(separator: ",")
                            }
                        ))
                    }
                }
                
            case .yesNo:
                Picker("", selection: binding(for: field)) {
                    Text("Select...").tag("")
                    Text("Yes").tag("Yes")
                    Text("No").tag("No")
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 200)
                
            case .signature:
                VStack(alignment: .leading, spacing: 8) {
                    if let data = signatureData, let image = NSImage(data: data) {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 80)
                            .border(Color.gray.opacity(0.3))
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 80)
                            .border(Color.gray.opacity(0.3))
                            .overlay(
                                Text("No signature")
                                    .foregroundColor(.secondary)
                            )
                    }
                    
                    HStack {
                        Button("Add Signature") {
                            showingSignaturePad = true
                        }
                        
                        if signatureData != nil {
                            Button("Clear") {
                                signatureData = nil
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
            }
        }
    }
    
    private func binding(for field: FormField) -> Binding<String> {
        Binding(
            get: { responses[field.id.uuidString] ?? "" },
            set: { responses[field.id.uuidString] = $0 }
        )
    }
    
    private var isFormValid: Bool {
        // Check all required fields are filled
        for field in template.fields where field.isRequired {
            let value = responses[field.id.uuidString]
            if value == nil || value?.isEmpty == true {
                if field.type == .signature && signatureData == nil {
                    return false
                } else if field.type != .signature {
                    return false
                }
            }
        }
        return !submitterName.isEmpty
    }
    
    private func saveSubmission() {
        savedSubmission = formService.createSubmission(
            for: template,
            responses: responses,
            submitterName: submitterName,
            submitterEmail: submitterEmail.isEmpty ? nil : submitterEmail,
            signatureData: signatureData
        )
        showingSaveSuccess = true
    }
    
    private func printFilledForm() {
        // Create temporary submission for preview
        let tempSubmission = FormSubmission(context: CoreDataManager.shared.viewContext)
        tempSubmission.id = UUID()
        tempSubmission.formID = template.id
        tempSubmission.setResponses(responses, submitterName: submitterName, submitterEmail: submitterEmail)
        tempSubmission.submittedAt = Date()
        tempSubmission.signatureData = signatureData
        
        if let pdf = formService.generateFormPDF(for: template, submission: tempSubmission) {
            formService.printForm(pdfDocument: pdf)
        }
        
        // Delete temporary submission
        CoreDataManager.shared.viewContext.delete(tempSubmission)
    }
    
    private func exportFilledForm() {
        // Create temporary submission for export
        let tempSubmission = FormSubmission(context: CoreDataManager.shared.viewContext)
        tempSubmission.id = UUID()
        tempSubmission.formID = template.id
        tempSubmission.setResponses(responses, submitterName: submitterName, submitterEmail: submitterEmail)
        tempSubmission.submittedAt = Date()
        tempSubmission.signatureData = signatureData
        
        guard let pdf = formService.generateFormPDF(for: template, submission: tempSubmission) else { return }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.pdf]
        savePanel.nameFieldStringValue = "\(template.name ?? "Form") - \(submitterName).pdf"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                _ = formService.savePDF(pdfDocument: pdf, to: url)
            }
        }
        
        // Delete temporary submission
        CoreDataManager.shared.viewContext.delete(tempSubmission)
    }
}

// MARK: - Signature Pad View

struct SignaturePadView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var signatureData: Data?
    
    @State private var currentPath = Path()
    @State private var paths: [Path] = []
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Sign below")
                    .font(.headline)
                    .padding()
                
                ZStack {
                    Rectangle()
                        .fill(Color.white)
                        .border(Color.gray)
                    
                    Canvas { context, size in
                        for path in paths {
                            context.stroke(path, with: .color(.black), lineWidth: 2)
                        }
                        context.stroke(currentPath, with: .color(.black), lineWidth: 2)
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let point = value.location
                                if currentPath.isEmpty {
                                    currentPath.move(to: point)
                                } else {
                                    currentPath.addLine(to: point)
                                }
                            }
                            .onEnded { _ in
                                paths.append(currentPath)
                                currentPath = Path()
                            }
                    )
                }
                .frame(height: 200)
                .padding()
                
                HStack {
                    Button("Clear") {
                        paths.removeAll()
                        currentPath = Path()
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Done") {
                        saveSignature()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(paths.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Signature")
        }
        .frame(width: 500, height: 400)
    }
    
    private func saveSignature() {
        let size = CGSize(width: 400, height: 150)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        // White background
        NSColor.white.setFill()
        NSRect(origin: .zero, size: size).fill()
        
        // Draw paths
        NSColor.black.setStroke()
        for path in paths {
            let nsPath = NSBezierPath()
            var isFirst = true
            path.forEach { element in
                switch element {
                case .move(to: let point):
                    nsPath.move(to: point)
                case .line(to: let point):
                    if isFirst {
                        nsPath.move(to: point)
                        isFirst = false
                    } else {
                        nsPath.line(to: point)
                    }
                default:
                    break
                }
            }
            nsPath.lineWidth = 2
            nsPath.stroke()
        }
        
        image.unlockFocus()
        
        signatureData = image.tiffRepresentation
    }
}
