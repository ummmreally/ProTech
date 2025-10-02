//
//  FormBuilderView.swift
//  ProTech
//
//  Build and edit form templates
//

import SwiftUI

struct FormBuilderView: View {
    @Environment(\.dismiss) var dismiss
    
    let template: FormTemplate?
    
    @State private var name = ""
    @State private var type = "custom"
    @State private var description = ""
    @State private var instructions = ""
    @State private var fields: [FormField] = []
    @State private var showingFieldEditor = false
    @State private var editingField: FormField?
    @State private var editingFieldIndex: Int?
    
    private let formService = FormService.shared
    
    var isEditing: Bool {
        template != nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Template Information") {
                    TextField("Form Name", text: $name)
                    
                    Picker("Form Type", selection: $type) {
                        Text("Custom").tag("custom")
                        Text("Intake Form").tag("intake")
                        Text("Pickup Form").tag("pickup")
                        Text("Service Agreement").tag("agreement")
                        Text("Checklist").tag("checklist")
                    }
                    
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                    
                    TextField("Instructions (optional)", text: $instructions, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section {
                    HStack {
                        Text("Form Fields")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button {
                            editingField = nil
                            editingFieldIndex = nil
                            showingFieldEditor = true
                        } label: {
                            Label("Add Field", systemImage: "plus.circle.fill")
                        }
                    }
                    
                    if fields.isEmpty {
                        Text("No fields added yet")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        ForEach(Array(fields.enumerated()), id: \.element.id) { index, field in
                            BuilderFieldRowView(field: field)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    editingField = field
                                    editingFieldIndex = index
                                    showingFieldEditor = true
                                }
                                .contextMenu {
                                    Button {
                                        editingField = field
                                        editingFieldIndex = index
                                        showingFieldEditor = true
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    
                                    Button(role: .destructive) {
                                        fields.remove(at: index)
                                        reorderFields()
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                        .onMove { from, to in
                            fields.move(fromOffsets: from, toOffset: to)
                            reorderFields()
                        }
                    }
                } header: {
                    Text("Fields")
                }
            }
            .formStyle(.grouped)
            .navigationTitle(isEditing ? "Edit Template" : "New Template")
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
                    .disabled(name.isEmpty || fields.isEmpty)
                }
            }
            .sheet(isPresented: $showingFieldEditor) {
                BuilderFieldEditorView(
                    field: editingField,
                    onSave: { newField in
                        if let index = editingFieldIndex {
                            fields[index] = newField
                        } else {
                            var field = newField
                            field.order = fields.count
                            fields.append(field)
                        }
                        showingFieldEditor = false
                    }
                )
            }
            .onAppear {
                loadTemplateData()
            }
        }
        .frame(width: 700, height: 600)
    }
    
    private func loadTemplateData() {
        guard let template = template else { return }
        name = template.name ?? ""
        type = template.type ?? "custom"
        description = template.templateData?.description ?? ""
        instructions = template.templateData?.instructions ?? ""
        fields = template.fields
    }
    
    private func saveTemplate() {
        if let template = template {
            formService.updateTemplate(
                template,
                name: name,
                fields: fields,
                description: description.isEmpty ? nil : description,
                instructions: instructions.isEmpty ? nil : instructions
            )
        } else {
            _ = formService.createTemplate(
                name: name,
                type: type,
                fields: fields,
                description: description.isEmpty ? nil : description,
                instructions: instructions.isEmpty ? nil : instructions
            )
        }
        dismiss()
    }
    
    private func reorderFields() {
        for (index, _) in fields.enumerated() {
            fields[index].order = index
        }
    }
}

// MARK: - Field Row View

struct BuilderFieldRowView: View {
    let field: FormField
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconForFieldType(field.type))
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(field.label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 8) {
                    Text(field.type.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if field.isRequired {
                        Text("• Required")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "line.3.horizontal")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
    
    private func iconForFieldType(_ type: FormField.FieldType) -> String {
        switch type {
        case .text: return "textformat"
        case .multiline: return "text.alignleft"
        case .number: return "number"
        case .email: return "envelope"
        case .phone: return "phone"
        case .date: return "calendar"
        case .dropdown: return "chevron.down.circle"
        case .checkbox: return "checkmark.square"
        case .radio: return "circle.circle"
        case .signature: return "signature"
        case .yesNo: return "questionmark.circle"
        }
    }
}

// MARK: - Field Editor View

struct BuilderFieldEditorView: View {
    @Environment(\.dismiss) var dismiss
    
    let field: FormField?
    let onSave: (FormField) -> Void
    
    @State private var label = ""
    @State private var placeholder = ""
    @State private var fieldType: FormField.FieldType = .text
    @State private var isRequired = false
    @State private var options: [String] = []
    @State private var newOption = ""
    
    var isEditing: Bool {
        field != nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Field Details") {
                    TextField("Label", text: $label)
                    
                    Picker("Field Type", selection: $fieldType) {
                        Text("Text").tag(FormField.FieldType.text)
                        Text("Multi-line Text").tag(FormField.FieldType.multiline)
                        Text("Number").tag(FormField.FieldType.number)
                        Text("Email").tag(FormField.FieldType.email)
                        Text("Phone").tag(FormField.FieldType.phone)
                        Text("Date").tag(FormField.FieldType.date)
                        Text("Dropdown").tag(FormField.FieldType.dropdown)
                        Text("Checkbox").tag(FormField.FieldType.checkbox)
                        Text("Radio Buttons").tag(FormField.FieldType.radio)
                        Text("Yes/No").tag(FormField.FieldType.yesNo)
                        Text("Signature").tag(FormField.FieldType.signature)
                    }
                    
                    if fieldType != .signature {
                        TextField("Placeholder (optional)", text: $placeholder)
                    }
                    
                    Toggle("Required Field", isOn: $isRequired)
                }
                
                if fieldType == .dropdown || fieldType == .radio || fieldType == .checkbox {
                    Section("Options") {
                        ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                            HStack {
                                Text(option)
                                Spacer()
                                Button(role: .destructive) {
                                    options.remove(at: index)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        HStack {
                            TextField("Add option", text: $newOption)
                            Button("Add") {
                                if !newOption.isEmpty {
                                    options.append(newOption)
                                    newOption = ""
                                }
                            }
                            .disabled(newOption.isEmpty)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(isEditing ? "Edit Field" : "New Field")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveField()
                    }
                    .disabled(label.isEmpty)
                }
            }
            .onAppear {
                loadFieldData()
            }
        }
        .frame(width: 500, height: 500)
    }
    
    private func loadFieldData() {
        guard let field = field else { return }
        label = field.label
        placeholder = field.placeholder ?? ""
        fieldType = field.type
        isRequired = field.isRequired
        options = field.options ?? []
    }
    
    private func saveField() {
        let newField = FormField(
            id: field?.id ?? UUID(),
            type: fieldType,
            label: label,
            placeholder: placeholder.isEmpty ? nil : placeholder,
            isRequired: isRequired,
            options: (fieldType == .dropdown || fieldType == .radio || fieldType == .checkbox) ? options : nil,
            defaultValue: nil,
            order: field?.order ?? 0
        )
        onSave(newField)
    }
}
