//
//  FormsManagerView.swift
//  ProTech
//
//  Manage form templates and submissions
//

import SwiftUI
import PDFKit

struct FormsManagerView: View {
    @State private var templates: [FormTemplate] = []
    @State private var selectedTemplate: FormTemplate?
    @State private var showingBuilder = false
    @State private var showingFillForm = false
    @State private var searchText = ""
    
    private let formService = FormService.shared
    private let coreDataManager = CoreDataManager.shared
    
    var filteredTemplates: [FormTemplate] {
        if searchText.isEmpty {
            return templates
        }
        return templates.filter { template in
            template.name?.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerView
                
                Divider()
                
                // Search
                searchBar
                
                Divider()
                
                // List
                if filteredTemplates.isEmpty {
                    emptyStateView
                } else {
                    templatesListView
                }
            }
            .onAppear {
                loadData()
            }
            .sheet(isPresented: $showingBuilder) {
                FormBuilderView(template: selectedTemplate)
                    .onDisappear {
                        selectedTemplate = nil
                        loadData()
                    }
            }
            .sheet(isPresented: $showingFillForm) {
                if let template = selectedTemplate {
                    FormFillView(template: template)
                        .onDisappear {
                            selectedTemplate = nil
                        }
                }
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Form Templates")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("\(filteredTemplates.count) templates")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button {
                selectedTemplate = nil
                showingBuilder = true
            } label: {
                Label("New Template", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search templates...", text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .padding()
    }
    
    private var templatesListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredTemplates, id: \.id) { template in
                    FormTemplateRow(template: template)
                        .contentShape(Rectangle())
                        .contextMenu {
                            contextMenu(for: template)
                        }
                }
            }
            .padding()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Form Templates")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create custom forms for intake, service agreements, and more")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                showingBuilder = true
            } label: {
                Label("Create Template", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func contextMenu(for template: FormTemplate) -> some View {
        Button {
            selectedTemplate = template
            showingFillForm = true
        } label: {
            Label("Fill Form", systemImage: "pencil")
        }
        
        Button {
            printBlankForm(template)
        } label: {
            Label("Print Blank", systemImage: "printer")
        }
        
        Button {
            exportBlankForm(template)
        } label: {
            Label("Export Blank PDF", systemImage: "square.and.arrow.up")
        }
        
        Divider()
        
        Button {
            selectedTemplate = template
            showingBuilder = true
        } label: {
            Label("Edit", systemImage: "pencil.circle")
        }
        
        Button {
            duplicateTemplate(template)
        } label: {
            Label("Duplicate", systemImage: "doc.on.doc")
        }
        
        Divider()
        
        Button(role: .destructive) {
            deleteTemplate(template)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    
    private func loadData() {
        templates = FormTemplate.fetchAllTemplates(context: coreDataManager.viewContext)
    }
    
    private func printBlankForm(_ template: FormTemplate) {
        if let pdf = formService.generateFormPDF(for: template, submission: nil) {
            formService.printForm(pdfDocument: pdf)
        }
    }
    
    private func exportBlankForm(_ template: FormTemplate) {
        guard let pdf = formService.generateFormPDF(for: template, submission: nil) else { return }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.pdf]
        savePanel.nameFieldStringValue = "\(template.name ?? "Form").pdf"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                _ = formService.savePDF(pdfDocument: pdf, to: url)
            }
        }
    }
    
    private func duplicateTemplate(_ template: FormTemplate) {
        let newName = "\(template.name ?? "Form") Copy"
        _ = formService.createTemplate(
            name: newName,
            type: template.type ?? "custom",
            fields: template.fields,
            description: template.templateData?.description,
            instructions: template.templateData?.instructions
        )
        loadData()
    }
    
    private func deleteTemplate(_ template: FormTemplate) {
        formService.deleteTemplate(template)
        loadData()
    }
}

// MARK: - Form Template Row

struct FormTemplateRow: View {
    let template: FormTemplate
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iconForType(template.type))
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(template.name ?? "Untitled")
                    .font(.headline)
                
                HStack(spacing: 12) {
                    Label("\(template.fields.count) fields", systemImage: "list.bullet")
                    
                    if template.isDefault {
                        Label("Default", systemImage: "star.fill")
                            .foregroundColor(.orange)
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(template.type?.capitalized ?? "Custom")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(4)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func iconForType(_ type: String?) -> String {
        switch type {
        case "intake": return "arrow.down.doc"
        case "pickup": return "arrow.up.doc"
        case "agreement": return "doc.text.signature"
        case "checklist": return "checklist"
        default: return "doc.text"
        }
    }
}
