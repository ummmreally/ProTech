//
//  FormTemplateManagerView.swift
//  ProTech
//
//  Form template management and customization
//

import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct FormTemplateManagerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FormTemplate.name, ascending: true)],
        animation: .default
    ) private var templates: FetchedResults<FormTemplate>
    
    @State private var searchText = ""
    @State private var selectedTemplate: FormTemplate?
    @State private var showingEditor = false
    @State private var showingImport = false
    @State private var showingExport = false
    @State private var showDeleteAlert = false
    @State private var templateToDelete: FormTemplate?
    
    var filteredTemplates: [FormTemplate] {
        if searchText.isEmpty {
            return Array(templates)
        }
        return templates.filter { template in
            (template.name?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (template.type?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search templates...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(10)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding()
                
                Divider()
                
                // Templates list
                if filteredTemplates.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredTemplates) { template in
                                TemplateRow(template: template) {
                                    selectedTemplate = template
                                    showingEditor = true
                                } onDuplicate: {
                                    duplicateTemplate(template)
                                } onExport: {
                                    exportTemplate(template)
                                } onDelete: {
                                    templateToDelete = template
                                    showDeleteAlert = true
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Form Templates")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .automatic) {
                    Menu {
                        Button {
                            createNewTemplate()
                        } label: {
                            Label("New Template", systemImage: "plus")
                        }
                        
                        Button {
                            showingImport = true
                        } label: {
                            Label("Import from JSON", systemImage: "square.and.arrow.down")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                if let template = selectedTemplate {
                    FormTemplateEditorView(template: template)
                }
            }
            .fileImporter(isPresented: $showingImport, allowedContentTypes: [.json]) { result in
                handleImport(result)
            }
            .alert("Delete Template", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let template = templateToDelete {
                        deleteTemplate(template)
                    }
                }
            } message: {
                Text("Are you sure you want to delete '\(templateToDelete?.name ?? "this template")'? This action cannot be undone.")
            }
        }
        .frame(width: 900, height: 700)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(searchText.isEmpty ? "No Templates Yet" : "No Matching Templates")
                .font(.title2)
                .bold()
            
            Text(searchText.isEmpty ? "Create your first custom form template" : "Try a different search term")
                .foregroundColor(.secondary)
            
            if searchText.isEmpty {
                Button {
                    createNewTemplate()
                } label: {
                    Label("Create Template", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Actions
    
    private func createNewTemplate() {
        let template = FormTemplate(context: viewContext)
        template.id = UUID()
        template.name = "New Template"
        template.type = "custom"
        template.isDefault = false
        template.createdAt = Date()
        template.updatedAt = Date()
        template.setFields([], description: "", instructions: "")
        
        try? viewContext.save()
        selectedTemplate = template
        showingEditor = true
    }
    
    private func duplicateTemplate(_ template: FormTemplate) {
        let newTemplate = FormTemplate(context: viewContext)
        newTemplate.id = UUID()
        newTemplate.name = (template.name ?? "Template") + " Copy"
        newTemplate.type = template.type
        newTemplate.templateJSON = template.templateJSON
        newTemplate.templateDescription = template.templateDescription
        newTemplate.instructions = template.instructions
        newTemplate.isDefault = false
        newTemplate.createdAt = Date()
        newTemplate.updatedAt = Date()
        
        try? viewContext.save()
    }
    
    private func deleteTemplate(_ template: FormTemplate) {
        viewContext.delete(template)
        try? viewContext.save()
    }
    
    private func exportTemplate(_ template: FormTemplate) {
        guard let templateData = template.templateData else { return }
        
        let exportData: [String: Any] = [
            "name": template.name ?? "",
            "type": template.type ?? "custom",
            "description": template.templateDescription ?? "",
            "instructions": template.instructions ?? "",
            "fields": template.fields.map { field in
                [
                    "id": field.id.uuidString,
                    "type": field.type.rawValue,
                    "label": field.label,
                    "placeholder": field.placeholder ?? "",
                    "isRequired": field.isRequired,
                    "options": field.options ?? [],
                    "defaultValue": field.defaultValue ?? "",
                    "order": field.order
                ]
            }
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return
        }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "\(template.name ?? "template").json"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                try? jsonString.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }
    
    private func handleImport(_ result: Result<URL, Error>) {
        guard case .success(let url) = result else { return }
        
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let data = try Data(contentsOf: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return
            }
            
            // Create new template from imported data
            let template = FormTemplate(context: viewContext)
            template.id = UUID()
            template.name = (json["name"] as? String ?? "Imported Template")
            template.type = json["type"] as? String ?? "custom"
            template.templateDescription = json["description"] as? String
            template.instructions = json["instructions"] as? String
            template.isDefault = false
            template.createdAt = Date()
            template.updatedAt = Date()
            
            // Parse fields
            if let fieldsArray = json["fields"] as? [[String: Any]] {
                let fields: [FormField] = fieldsArray.compactMap { fieldDict in
                    guard let typeString = fieldDict["type"] as? String,
                          let type = FormField.FieldType(rawValue: typeString),
                          let label = fieldDict["label"] as? String,
                          let order = fieldDict["order"] as? Int else {
                        return nil
                    }
                    
                    return FormField(
                        id: UUID(),
                        type: type,
                        label: label,
                        placeholder: fieldDict["placeholder"] as? String,
                        isRequired: fieldDict["isRequired"] as? Bool ?? false,
                        options: fieldDict["options"] as? [String],
                        defaultValue: fieldDict["defaultValue"] as? String,
                        order: order
                    )
                }
                
                template.setFields(fields, description: template.templateDescription, instructions: template.instructions)
            }
            
            try viewContext.save()
        } catch {
            print("Import error: \(error)")
        }
    }
}

// MARK: - Template Row

struct TemplateRow: View {
    let template: FormTemplate
    let onEdit: () -> Void
    let onDuplicate: () -> Void
    let onExport: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(template.isDefault ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                    .frame(width: 50, height: 50)
                Image(systemName: template.isDefault ? "star.fill" : "doc.text")
                    .foregroundColor(template.isDefault ? .blue : .secondary)
                    .font(.title3)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(template.name ?? "Unnamed Template")
                        .font(.headline)
                    
                    if template.isDefault {
                        Text("DEFAULT")
                            .font(.caption2)
                            .bold()
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }
                
                HStack(spacing: 12) {
                    if let type = template.type {
                        Label(type.capitalized, systemImage: "tag")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Label("\(template.fields.count) fields", systemImage: "list.bullet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let updated = template.updatedAt {
                        Label(updated.formatted(date: .abbreviated, time: .omitted), systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let description = template.templateDescription, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Actions
            Menu {
                Button {
                    onEdit()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                
                Button {
                    onDuplicate()
                } label: {
                    Label("Duplicate", systemImage: "doc.on.doc")
                }
                
                Button {
                    onExport()
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                
                Divider()
                
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .menuStyle(.borderlessButton)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Template Editor View

struct FormTemplateEditorView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var template: FormTemplate
    
    @State private var templateName: String
    @State private var templateType: String
    @State private var templateDescription: String
    @State private var templateInstructions: String
    @State private var fields: [FormField]
    @State private var editingField: FormField?
    @State private var showingFieldEditor = false
    
    init(template: FormTemplate) {
        self.template = template
        _templateName = State(initialValue: template.name ?? "")
        _templateType = State(initialValue: template.type ?? "custom")
        _templateDescription = State(initialValue: template.templateDescription ?? "")
        _templateInstructions = State(initialValue: template.instructions ?? "")
        _fields = State(initialValue: template.fields)
    }
    
    var body: some View {
        NavigationStack {
            HSplitView {
                // Left: Form configuration
                VStack(spacing: 0) {
                    Form {
                        Section("Template Information") {
                            TextField("Template Name", text: $templateName)
                            TextField("Type", text: $templateType)
                                .help("e.g., repair, intake, waiver")
                            
                            Toggle("Set as Default", isOn: Binding(
                                get: { template.isDefault },
                                set: { template.isDefault = $0 }
                            ))
                        }
                        
                        Section("Description & Instructions") {
                            TextEditor(text: $templateDescription)
                                .frame(height: 60)
                            
                            TextEditor(text: $templateInstructions)
                                .frame(height: 80)
                        }
                    }
                    .formStyle(.grouped)
                }
                .frame(minWidth: 300, idealWidth: 350)
                
                // Right: Fields management
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Form Fields")
                            .font(.headline)
                        Spacer()
                        Button {
                            addNewField()
                        } label: {
                            Label("Add Field", systemImage: "plus.circle.fill")
                        }
                    }
                    .padding()
                    
                    Divider()
                    
                    // Fields list
                    if fields.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "rectangle.on.rectangle")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                            Text("No Fields Yet")
                                .font(.headline)
                            Text("Add fields to build your form")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(fields) { field in
                                FieldRow(field: field) {
                                    editingField = field
                                    showingFieldEditor = true
                                } onDelete: {
                                    deleteField(field)
                                } onMoveUp: {
                                    moveField(field, direction: -1)
                                } onMoveDown: {
                                    moveField(field, direction: 1)
                                }
                            }
                        }
                    }
                }
                .frame(minWidth: 500)
            }
            .navigationTitle("Edit Template")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTemplate()
                    }
                }
            }
            .sheet(isPresented: $showingFieldEditor) {
                if let field = editingField,
                   let index = fields.firstIndex(where: { $0.id == field.id }) {
                    FieldEditorSheet(field: $fields[index])
                }
            }
        }
        .frame(width: 900, height: 700)
    }
    
    private func addNewField() {
        let newField = FormField(
            id: UUID(),
            type: .text,
            label: "New Field",
            placeholder: nil,
            isRequired: false,
            options: nil,
            defaultValue: nil,
            order: fields.count
        )
        fields.append(newField)
        editingField = newField
        showingFieldEditor = true
    }
    
    private func deleteField(_ field: FormField) {
        fields.removeAll { $0.id == field.id }
        reorderFields()
    }
    
    private func moveField(_ field: FormField, direction: Int) {
        guard let index = fields.firstIndex(where: { $0.id == field.id }) else { return }
        let newIndex = index + direction
        guard newIndex >= 0 && newIndex < fields.count else { return }
        
        fields.move(fromOffsets: IndexSet(integer: index), toOffset: newIndex > index ? newIndex + 1 : newIndex)
        reorderFields()
    }
    
    private func reorderFields() {
        for (index, _) in fields.enumerated() {
            fields[index].order = index
        }
    }
    
    private func saveTemplate() {
        template.name = templateName
        template.type = templateType
        template.templateDescription = templateDescription
        template.instructions = templateInstructions
        template.updatedAt = Date()
        template.setFields(fields, description: templateDescription, instructions: templateInstructions)
        
        try? viewContext.save()
        dismiss()
    }
}

// MARK: - Field Row

struct FieldRow: View {
    let field: FormField
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(field.label)
                        .font(.headline)
                    
                    if field.isRequired {
                        Text("*")
                            .foregroundColor(.red)
                            .bold()
                    }
                }
                
                HStack(spacing: 8) {
                    Text(field.type.rawValue.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                    
                    if let placeholder = field.placeholder, !placeholder.isEmpty {
                        Text(placeholder)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button {
                    onMoveUp()
                } label: {
                    Image(systemName: "chevron.up")
                }
                .buttonStyle(.borderless)
                
                Button {
                    onMoveDown()
                } label: {
                    Image(systemName: "chevron.down")
                }
                .buttonStyle(.borderless)
                
                Button {
                    onEdit()
                } label: {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.borderless)
                
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .foregroundColor(.red)
            }
        }
    }
}

// MARK: - Field Editor Sheet

struct FieldEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var field: FormField
    
    @State private var label: String
    @State private var type: FormField.FieldType
    @State private var placeholder: String
    @State private var isRequired: Bool
    @State private var options: String
    @State private var defaultValue: String
    
    init(field: Binding<FormField>) {
        _field = field
        _label = State(initialValue: field.wrappedValue.label)
        _type = State(initialValue: field.wrappedValue.type)
        _placeholder = State(initialValue: field.wrappedValue.placeholder ?? "")
        _isRequired = State(initialValue: field.wrappedValue.isRequired)
        _options = State(initialValue: (field.wrappedValue.options ?? []).joined(separator: "\n"))
        _defaultValue = State(initialValue: field.wrappedValue.defaultValue ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Field Label", text: $label)
                    
                    Picker("Field Type", selection: $type) {
                        ForEach([FormField.FieldType.text, .multiline, .number, .email, .phone, .date, .dropdown, .checkbox, .radio, .signature, .yesNo], id: \.self) { fieldType in
                            Text(fieldType.rawValue.capitalized).tag(fieldType)
                        }
                    }
                    
                    TextField("Placeholder", text: $placeholder)
                    
                    Toggle("Required Field", isOn: $isRequired)
                }
                
                if type == .dropdown || type == .checkbox || type == .radio {
                    Section("Options") {
                        Text("Enter one option per line")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $options)
                            .frame(height: 120)
                    }
                }
                
                Section("Default Value") {
                    TextField("Default Value", text: $defaultValue)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Edit Field")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveField()
                    }
                }
            }
        }
        .frame(width: 500, height: 500)
    }
    
    private func saveField() {
        field.label = label
        field.type = type
        field.placeholder = placeholder.isEmpty ? nil : placeholder
        field.isRequired = isRequired
        field.defaultValue = defaultValue.isEmpty ? nil : defaultValue
        
        if type == .dropdown || type == .checkbox || type == .radio {
            field.options = options
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        } else {
            field.options = nil
        }
        
        dismiss()
    }
}
