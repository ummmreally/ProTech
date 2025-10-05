//
//  FormSubmissionView.swift
//  ProTech
//
//  View and print completed form submissions
//

import SwiftUI
import PDFKit
import AppKit

struct FormSubmissionView: View {
    @Environment(\.dismiss) private var dismiss
    
    let submission: FormSubmission
    let template: FormTemplate
    
    @State private var pdfDocument: PDFDocument?
    @State private var showingPrintDialog = false
    @State private var showingSavePanel = false
    @State private var isGeneratingPDF = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let pdfDoc = pdfDocument {
                    // PDF Preview
                    PDFViewWrapper(document: pdfDoc)
                } else if isGeneratingPDF {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Generating PDF...")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("Unable to generate PDF")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Form Submission")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItemGroup(placement: .automatic) {
                    Button {
                        exportPDF()
                    } label: {
                        Label("Export PDF", systemImage: "square.and.arrow.up")
                    }
                    .disabled(pdfDocument == nil)
                    
                    Menu {
                        Button {
                            printPDF()
                        } label: {
                            Label("Print PDF", systemImage: "doc.fill")
                        }
                        
                        Button {
                            printTextVersion()
                        } label: {
                            Label("Print Text Version", systemImage: "text.alignleft")
                        }
                    } label: {
                        Label("Print", systemImage: "printer")
                    }
                    .disabled(pdfDocument == nil)
                }
            }
        }
        .frame(width: 700, height: 900)
        .onAppear {
            generatePDF()
        }
        .alert("Export Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Methods
    
    private func generatePDF() {
        isGeneratingPDF = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let pdf = FormService.shared.generatePDF(submission: submission, template: template)
            
            DispatchQueue.main.async {
                isGeneratingPDF = false
                if let pdf = pdf {
                    pdfDocument = pdf
                } else {
                    errorMessage = "Failed to generate PDF from form data"
                }
            }
        }
    }
    
    private func printPDF() {
        guard let pdf = pdfDocument else { return }
        
        let printInfo = NSPrintInfo.shared
        printInfo.horizontalPagination = .fit
        printInfo.verticalPagination = .fit
        printInfo.topMargin = 36
        printInfo.bottomMargin = 36
        printInfo.leftMargin = 36
        printInfo.rightMargin = 36
        
        let printOperation = pdf.printOperation(
            for: printInfo,
            scalingMode: .pageScaleDownToFit,
            autoRotate: true
        )
        
        printOperation?.runModal(
            for: NSApp.keyWindow!,
            delegate: nil,
            didRun: nil,
            contextInfo: nil
        )
    }
    
    private func printTextVersion() {
        DymoPrintService.shared.printForm(submission: submission, template: template)
    }
    
    private func exportPDF() {
        guard let pdf = pdfDocument else { return }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.pdf]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.title = "Export Form PDF"
        savePanel.message = "Choose a location to save the PDF"
        savePanel.nameFieldStringValue = "\(template.name ?? "Form")_\(Date().formatted(date: .numeric, time: .omitted)).pdf"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                if FormService.shared.savePDF(pdfDocument: pdf, to: url) {
                    // Success
                } else {
                    errorMessage = "Failed to save PDF to \(url.path)"
                    showingError = true
                }
            }
        }
    }
}

// MARK: - PDF View Wrapper

struct PDFViewWrapper: NSViewRepresentable {
    let document: PDFDocument
    
    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        return pdfView
    }
    
    func updateNSView(_ nsView: PDFView, context: Context) {
        if nsView.document != document {
            nsView.document = document
        }
    }
}

// MARK: - Form Submissions List

struct FormSubmissionsListView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FormSubmission.submittedAt, ascending: false)]
    ) var submissions: FetchedResults<FormSubmission>
    
    @FetchRequest(
        sortDescriptors: []
    ) var templates: FetchedResults<FormTemplate>
    
    @State private var selectedSubmission: FormSubmission?
    @State private var showingSubmissionView = false
    
    var body: some View {
        VStack {
            if submissions.isEmpty {
                emptyStateView
            } else {
                List {
                    ForEach(submissions) { submission in
                        SubmissionRow(submission: submission, templates: Array(templates))
                            .onTapGesture {
                                selectedSubmission = submission
                                showingSubmissionView = true
                            }
                    }
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle("Form Submissions")
        .sheet(isPresented: $showingSubmissionView) {
            if let submission = selectedSubmission,
               let template = templates.first(where: { $0.id == submission.formID }) {
                FormSubmissionView(submission: submission, template: template)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No Form Submissions")
                .font(.title2)
                .foregroundColor(.secondary)
            Text("Completed forms will appear here")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SubmissionRow: View {
    let submission: FormSubmission
    let templates: [FormTemplate]
    
    var body: some View {
        HStack {
            Image(systemName: "doc.fill")
                .font(.title2)
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 4) {
                if let template = templates.first(where: { $0.id == submission.formID }) {
                    Text(template.name ?? "Form")
                        .font(.headline)
                } else {
                    Text("Unknown Form")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                if let date = submission.submittedAt {
                    Text("Submitted: \(date.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if submission.signatureData != nil {
                Image(systemName: "signature")
                    .foregroundColor(.blue)
                    .help("Includes signature")
            }
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}
