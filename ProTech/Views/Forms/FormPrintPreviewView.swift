//
//  FormPrintPreviewView.swift
//  ProTech
//
//  PDF preview and print dialog for forms
//

import SwiftUI
import PDFKit
import AppKit

struct FormPrintPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    
    let submission: FormSubmission
    let template: FormTemplate
    
    @State private var pdfDocument: PDFDocument?
    @State private var isGenerating = false
    @State private var numberOfCopies = 1
    @State private var showPrintDialog = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Toolbar
                HStack {
                    Stepper("Copies: \(numberOfCopies)", value: $numberOfCopies, in: 1...10)
                    
                    Spacer()
                    
                    Button {
                        quickPrint()
                    } label: {
                        Label("Quick Print", systemImage: "printer.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(pdfDocument == nil)
                    
                    Button {
                        showAdvancedPrintDialog()
                    } label: {
                        Label("Print Options", systemImage: "gearshape")
                    }
                    .disabled(pdfDocument == nil)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                
                Divider()
                
                // PDF Preview
                if let pdf = pdfDocument {
                    PDFViewWrapper(document: pdf)
                } else if isGenerating {
                    ProgressView("Generating preview...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text("Failed to generate preview")
                            .font(.headline)
                        Button("Retry") {
                            generatePDF()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Print Preview")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 700, height: 900)
        .onAppear {
            generatePDF()
        }
    }
    
    // MARK: - Methods
    
    private func generatePDF() {
        isGenerating = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let pdf = FormService.shared.generatePDF(submission: submission, template: template)
            
            DispatchQueue.main.async {
                isGenerating = false
                pdfDocument = pdf
            }
        }
    }
    
    private func quickPrint() {
        guard let pdf = pdfDocument else { return }
        
        let printInfo = NSPrintInfo.shared
        printInfo.horizontalPagination = .fit
        printInfo.verticalPagination = .fit
        
        let printOperation = pdf.printOperation(
            for: printInfo,
            scalingMode: .pageScaleDownToFit,
            autoRotate: true
        )
        
        // Print multiple copies
        printOperation?.jobTitle = template.name ?? "Form"
        
        for _ in 0..<numberOfCopies {
            printOperation?.run()
        }
    }
    
    private func showAdvancedPrintDialog() {
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
        
        printOperation?.jobTitle = template.name ?? "Form"
        printOperation?.showsPrintPanel = true
        printOperation?.showsProgressPanel = true
        
        printOperation?.runModal(
            for: NSApp.keyWindow!,
            delegate: nil,
            didRun: nil,
            contextInfo: nil
        )
    }
}

// MARK: - Quick Print Button

struct QuickPrintButton: View {
    let submission: FormSubmission
    let template: FormTemplate
    
    @State private var showingPreview = false
    @State private var isPrinting = false
    
    var body: some View {
        Button {
            showingPreview = true
        } label: {
            Label("Print", systemImage: "printer")
        }
        .disabled(isPrinting)
        .sheet(isPresented: $showingPreview) {
            FormPrintPreviewView(submission: submission, template: template)
        }
    }
}

// MARK: - Direct Print (No Preview)

extension FormService {
    /// Print form directly without preview
    func printFormDirectly(submission: FormSubmission, template: FormTemplate) {
        guard let pdf = generatePDF(submission: submission, template: template) else {
            print("Failed to generate PDF")
            return
        }
        
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
        
        printOperation?.jobTitle = template.name ?? "Form"
        printOperation?.run()
    }
}
