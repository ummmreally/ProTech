//
//  FormsListView.swift
//  ProTech
//
//  Forms management view (Pro feature)
//

import SwiftUI

struct FormsListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FormTemplate.createdAt, ascending: false)]
    ) var templates: FetchedResults<FormTemplate>
    
    @State private var showingEditor = false
    @State private var selectedTemplate: FormTemplate?
    @State private var showingSubmissions = false
    
    var body: some View {
        VStack {
            if templates.isEmpty {
                emptyStateView
            } else {
                List {
                    ForEach(templates) { template in
                        FormRow(template: template)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedTemplate = template
                                showingEditor = true
                            }
                            .contextMenu {
                                Button {
                                    selectedTemplate = template
                                    showingEditor = true
                                } label: {
                                    Label("Edit Template", systemImage: "pencil")
                                }
                                
                                Button {
                                    duplicateTemplate(template)
                                } label: {
                                    Label("Duplicate", systemImage: "plus.square.on.square")
                                }
                                
                                Divider()
                                
                                Button(role: .destructive) {
                                    deleteTemplate(template)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle("Form Templates")
        .toolbar {
            ToolbarItemGroup {
                Button {
                    showingSubmissions = true
                } label: {
                    Label("View Submissions", systemImage: "tray.full")
                }
                
                Button {
                    createNewForm()
                } label: {
                    Label("New Form", systemImage: "plus")
                }
            }
        }
        .sheet(item: $selectedTemplate) { template in
            FormEditorView(template: template)
        }
        .sheet(isPresented: $showingSubmissions) {
            FormSubmissionsListView()
        }
        .onAppear {
            // Load default templates if none exist
            if templates.isEmpty {
                FormService.shared.loadDefaultTemplates()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No Form Templates")
                .font(.title2)
                .foregroundColor(.secondary)
            Text("Create your first custom form template")
                .font(.body)
                .foregroundColor(.secondary)
            
            HStack(spacing: 16) {
                Button {
                    FormService.shared.loadDefaultTemplates()
                } label: {
                    Label("Load Defaults", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.bordered)
                
                Button {
                    createNewForm()
                } label: {
                    Label("Create New", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func createNewForm() {
        let newTemplate = FormTemplate(context: viewContext)
        newTemplate.id = UUID()
        newTemplate.name = "New Form"
        newTemplate.type = "custom"
        newTemplate.templateJSON = "{\"fields\":[]}"
        newTemplate.isDefault = false
        newTemplate.createdAt = Date()
        newTemplate.updatedAt = Date()
        
        CoreDataManager.shared.save()
        selectedTemplate = newTemplate
        showingEditor = true
    }
    
    private func duplicateTemplate(_ template: FormTemplate) {
        let duplicate = FormTemplate(context: viewContext)
        duplicate.id = UUID()
        duplicate.name = "\(template.name ?? "Form") (Copy)"
        duplicate.type = template.type
        duplicate.templateJSON = template.templateJSON
        duplicate.isDefault = false
        duplicate.createdAt = Date()
        duplicate.updatedAt = Date()
        
        CoreDataManager.shared.save()
    }
    
    private func deleteTemplate(_ template: FormTemplate) {
        viewContext.delete(template)
        CoreDataManager.shared.save()
    }
}

struct FormRow: View {
    let template: FormTemplate
    
    var body: some View {
        HStack {
            Image(systemName: iconForType(template.type ?? "custom"))
                .font(.title2)
                .foregroundColor(.purple)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(template.name ?? "Untitled Form")
                    .font(.headline)
                if let type = template.type {
                    Text(type.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if template.isDefault {
                Text("DEFAULT")
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 8)
    }
    
    func iconForType(_ type: String) -> String {
        switch type {
        case "intake": return "doc.text.fill"
        case "pickup": return "checkmark.circle.fill"
        default: return "doc.fill"
        }
    }
}
