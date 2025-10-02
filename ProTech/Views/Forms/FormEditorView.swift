//
//  FormEditorView.swift
//  ProTech
//
//  Form template editor with drag-and-drop field builder
//

import SwiftUI

struct FormEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @ObservedObject var template: FormTemplate
    @State private var formName: String
    @State private var formType: String
    @State private var companyName: String
    @State private var headerText: String
    @State private var footerText: String
    @State private var fields: [FormField]
    @State private var showingFieldPicker = false
    @State private var editingField: FormField?
    @State private var showingSaveSuccess = false
    
    init(template: FormTemplate) {
        self.template = template
        
        // Initialize state from template
        _formName = State(initialValue: template.name ?? "New Form")
        _formType = State(initialValue: template.type ?? "custom")
        
        // Parse template JSON if available
        if let jsonString = template.templateJSON,
           let data = jsonString.data(using: .utf8),
           let decoded = try? JSONDecoder().decode(FormTemplateModel.self, from: data) {
            _companyName = State(initialValue: decoded.companyName ?? "")
            _headerText = State(initialValue: decoded.headerText ?? "")
            _footerText = State(initialValue: decoded.footerText ?? "")
            let sortedFields = decoded.fields.sorted { $0.order < $1.order }
            _fields = State(initialValue: sortedFields)
        } else if let jsonString = template.templateJSON,
                  let data = jsonString.data(using: .utf8),
                  let legacy = try? JSONDecoder().decode(LegacyFormTemplateModel.self, from: data) {
            _companyName = State(initialValue: legacy.companyName ?? "")
            _headerText = State(initialValue: legacy.headerText ?? "")
            _footerText = State(initialValue: legacy.footerText ?? "")
            let convertedFields = legacy.fields.enumerated().map { index, field in
                FormField(
                    id: UUID(uuidString: field.id) ?? UUID(),
                    type: FormField.FieldType(legacyValue: field.type),
                    label: field.label,
                    placeholder: field.placeholder,
                    isRequired: field.required,
                    options: field.options,
                    defaultValue: field.defaultValue,
                    order: index
                )
            }
            _fields = State(initialValue: convertedFields)
        } else {
            _companyName = State(initialValue: "")
            _headerText = State(initialValue: "")
            _footerText = State(initialValue: "")
            _fields = State(initialValue: [])
        }
    }
    
    var body: some View {
        NavigationStack {
            HSplitView {
                // Left: Form Builder
                VStack(spacing: 0) {
                    // Form Settings
                    Form {
                        Section("Form Settings") {
                            TextField("Form Name", text: $formName)
                            
                            Picker("Form Type", selection: $formType) {
                                Text("Intake Form").tag("intake")
                                Text("Pickup Form").tag("pickup")
                                Text("Custom Form").tag("custom")
                            }
                            
                            TextField("Company Name", text: $companyName)
                            TextField("Header Text", text: $headerText)
                            TextField("Footer Text", text: $footerText)
                        }
                    }
                    .formStyle(.grouped)
                    .frame(height: 300)
                    
                    Divider()
                    
                    // Field List
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Form Fields")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            Spacer()
                            
                            Button {
                                showingFieldPicker = true
                            } label: {
                                Label("Add Field", systemImage: "plus.circle.fill")
                            }
                            .padding(.horizontal)
                        }
                        .padding(.top)
                        
                        if fields.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "doc.text.magnifyingglass")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                Text("No fields added yet")
                                    .foregroundColor(.secondary)
                                Button("Add First Field") {
                                    showingFieldPicker = true
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            List {
                                ForEach(Array(fields.enumerated()), id: \.element.id) { index, field in
                                    EditorFieldRowView(field: field)
                                        .onTapGesture {
                                            editingField = field
                                        }
                                        .contextMenu {
                                            Button("Edit") {
                                                editingField = field
                                            }
                                            Button("Duplicate") {
                                                duplicateField(field)
                                            }
                                            Divider()
                                            Button("Delete", role: .destructive) {
                                                fields.removeAll { $0.id == field.id }
                                                updateFieldOrders()
                                            }
                                        }
                                }
                                .onMove { source, destination in
                                    fields.move(fromOffsets: source, toOffset: destination)
                                    updateFieldOrders()
                                }
                            }
                        }
                    }
                }
                .frame(minWidth: 350, idealWidth: 400)
                
                // Right: Preview
                FormPreviewView(
                    formName: formName,
                    companyName: companyName,
                    headerText: headerText,
                    footerText: footerText,
                    fields: fields.sorted { $0.order < $1.order }
                )
                .frame(minWidth: 400)
            }
            .navigationTitle("Form Editor")
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
            .sheet(isPresented: $showingFieldPicker) {
                FieldPickerView { fieldType in
                    addField(type: fieldType)
                    showingFieldPicker = false
                }
            }
            .sheet(item: $editingField) { field in
                FieldEditorView(field: field) { updatedField in
                    if let index = fields.firstIndex(where: { $0.id == field.id }) {
                        fields[index] = updatedField
                    }
                    editingField = nil
                }
            }
            .alert("Form Saved", isPresented: $showingSaveSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Form template has been saved successfully.")
            }
        }
        .frame(minWidth: 900, minHeight: 700)
    }
    
    // MARK: - Methods
    
    private func addField(type: FormField.FieldType) {
        let newField = FormField(
            id: UUID(),
            type: type,
            label: defaultLabel(for: type),
            placeholder: defaultPlaceholder(for: type),
            isRequired: false,
            options: defaultOptions(for: type),
            defaultValue: defaultValue(for: type),
            order: fields.count
        )
        fields.append(newField)
        updateFieldOrders()
    }
    
    private func duplicateField(_ field: FormField) {
        var duplicate = field
        duplicate.id = UUID()
        duplicate.label += " (Copy)"
        if let index = fields.firstIndex(where: { $0.id == field.id }) {
            duplicate.order = index + 1
            fields.insert(duplicate, at: index + 1)
            updateFieldOrders()
        }
    }
    
    private func defaultLabel(for type: FormField.FieldType) -> String {
        switch type {
        case .text: return "Text Field"
        case .multiline: return "Multi-line Text"
        case .number: return "Number"
        case .email: return "Email"
        case .phone: return "Phone"
        case .date: return "Date"
        case .dropdown: return "Dropdown"
        case .checkbox: return "Checkbox"
        case .radio: return "Radio Buttons"
        case .signature: return "Signature"
        case .yesNo: return "Yes / No"
        }
    }
    
    private func defaultPlaceholder(for type: FormField.FieldType) -> String? {
        switch type {
        case .text: return "Enter text"
        case .multiline: return "Enter details"
        case .number: return "0"
        case .email: return "name@example.com"
        case .phone: return "+1 (555) 123-4567"
        case .date: return nil
        case .dropdown, .checkbox, .radio, .signature, .yesNo: return nil
        }
    }
    
    private func defaultOptions(for type: FormField.FieldType) -> [String]? {
        switch type {
        case .dropdown, .radio:
            return ["Option 1", "Option 2"]
        case .checkbox:
            return ["Option A", "Option B"]
        case .text, .multiline, .number, .email, .phone, .date, .signature, .yesNo:
            return nil
        }
    }
    
    private func defaultValue(for type: FormField.FieldType) -> String? {
        switch type {
        case .text, .multiline, .number, .email, .phone, .date, .dropdown, .checkbox, .radio, .signature, .yesNo:
            return nil
        }
    }
    
    private func updateFieldOrders() {
        for index in fields.indices {
            fields[index].order = index
        }
    }
    
    private func saveTemplate() {
        updateFieldOrders()
        let sortedFields = fields.sorted { $0.order < $1.order }
        let templateModel = FormTemplateModel(
            id: template.id?.uuidString ?? UUID().uuidString,
            name: formName,
            type: formType,
            companyName: companyName.isEmpty ? nil : companyName,
            companyLogo: nil,
            headerText: headerText.isEmpty ? nil : headerText,
            footerText: footerText.isEmpty ? nil : footerText,
            fields: sortedFields
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        if let jsonData = try? encoder.encode(templateModel),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            template.name = formName
            template.type = formType
            template.templateJSON = jsonString
            template.updatedAt = Date()
            
            if template.id == nil {
                template.id = UUID()
                template.createdAt = Date()
            }
            
            CoreDataManager.shared.save()
            showingSaveSuccess = true
        }
    }
}

private struct LegacyFormTemplateModel: Codable {
    let id: String
    let name: String
    let type: String
    let companyName: String?
    let companyLogo: String?
    let headerText: String?
    let footerText: String?
    let fields: [LegacyFormField]
}

private struct LegacyFormField: Codable {
    let id: String
    let type: String
    let label: String
    let placeholder: String?
    let required: Bool
    let defaultValue: String?
    let options: [String]?
    let rows: Int?
}

private extension FormField.FieldType {
    init(legacyValue: String) {
        switch legacyValue {
        case "text": self = .text
        case "textarea": self = .multiline
        case "number": self = .number
        case "email": self = .email
        case "phone": self = .phone
        case "date": self = .date
        case "dropdown": self = .dropdown
        case "checkbox": self = .checkbox
        case "radio": self = .radio
        case "signature": self = .signature
        case "yesNo", "yes_no": self = .yesNo
        default: self = .text
        }
    }
}

// MARK: - Field Row

struct EditorFieldRowView: View {
    let field: FormField
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconForFieldType(field.type))
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(field.label)
                    .font(.body)
                Text(field.type.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if field.isRequired {
                Text("Required")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.red.opacity(0.2))
                    .foregroundColor(.red)
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
    
    func iconForFieldType(_ type: FormField.FieldType) -> String {
        switch type {
        case .text: return "textformat"
        case .multiline: return "text.alignleft"
        case .number: return "number"
        case .email: return "envelope"
        case .phone: return "phone"
        case .date: return "calendar"
        case .checkbox: return "checkmark.square"
        case .dropdown: return "chevron.down.circle"
        case .radio: return "circle.circle"
        case .signature: return "signature"
        case .yesNo: return "questionmark.circle"
        }
    }
}

// MARK: - Field Picker

struct FieldPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (FormField.FieldType) -> Void
    
    private let fieldTypes: [(FormField.FieldType, String, String)] = [
        (.text, "Text Field", "Single line text input"),
        (.multiline, "Multi-line Text", "Multi-line text input"),
        (.number, "Number", "Numeric input"),
        (.email, "Email", "Email input"),
        (.phone, "Phone", "Phone number input"),
        (.date, "Date", "Date picker"),
        (.dropdown, "Dropdown", "Select from list"),
        (.checkbox, "Checkboxes", "Allow multiple selections"),
        (.radio, "Radio Buttons", "Single selection"),
        (.yesNo, "Yes / No", "Quick yes or no"),
        (.signature, "Signature", "Digital signature pad")
    ]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(fieldTypes, id: \.0) { type, name, description in
                    Button {
                        onSelect(type)
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: iconForType(type))
                                .font(.title2)
                                .foregroundColor(.accentColor)
                                .frame(width: 32)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Add Field")
            .toolbar {
                ToolbarItem {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 450, height: 500)
    }
    
    func iconForType(_ type: FormField.FieldType) -> String {
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

// MARK: - Field Editor

struct FieldEditorView: View {
    @Environment(\.dismiss) private var dismiss
    
    let field: FormField
    let onSave: (FormField) -> Void
    
    @State private var label: String
    @State private var placeholder: String
    @State private var isRequired: Bool
    @State private var defaultValue: String
    @State private var options: [String]
    @State private var newOption = ""
    
    init(field: FormField, onSave: @escaping (FormField) -> Void) {
        self.field = field
        self.onSave = onSave
        _label = State(initialValue: field.label)
        _placeholder = State(initialValue: field.placeholder ?? "")
        _isRequired = State(initialValue: field.isRequired)
        _defaultValue = State(initialValue: field.defaultValue ?? "")
        _options = State(initialValue: field.options ?? [])
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Field Properties") {
                    TextField("Label", text: $label)
                    
                    if supportsPlaceholder {
                        TextField("Placeholder", text: $placeholder)
                    }
                    
                    if supportsRequired {
                        Toggle("Required Field", isOn: $isRequired)
                    }
                    
                    if supportsDefaultValue {
                        TextField("Default Value", text: $defaultValue)
                    }
                }
                
                if field.type == .dropdown || field.type == .radio || field.type == .checkbox {
                    Section("Options") {
                        ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                            HStack {
                                TextField("Option \(index + 1)", text: Binding(
                                    get: { options[index] },
                                    set: { options[index] = $0 }
                                ))
                                
                                Button {
                                    options.remove(at: index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        HStack {
                            TextField("New Option", text: $newOption)
                            Button {
                                if !newOption.isEmpty {
                                    options.append(newOption)
                                    newOption = ""
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.green)
                            }
                            .buttonStyle(.plain)
                            .disabled(newOption.isEmpty)
                        }
                    }
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
                    Button("Save") {
                        let updatedField = FormField(
                            id: field.id,
                            type: field.type,
                            label: label,
                            placeholder: placeholder.isEmpty ? nil : placeholder,
                            isRequired: supportsRequired ? isRequired : field.isRequired,
                            options: sanitizedOptions(),
                            defaultValue: sanitizedDefaultValue(),
                            order: field.order
                        )
                        onSave(updatedField)
                    }
                }
            }
        }
        .frame(width: 500, height: 600)
    }

    private var supportsPlaceholder: Bool {
        switch field.type {
        case .signature, .yesNo:
            return false
        case .dropdown, .radio, .checkbox:
            return false
        case .date:
            return false
        case .text, .multiline, .number, .email, .phone:
            return true
        }
    }
    
    private var supportsRequired: Bool {
        field.type != .signature
    }
    
    private var supportsDefaultValue: Bool {
        switch field.type {
        case .text, .multiline, .number, .email, .phone:
            return true
        default:
            return false
        }
    }
    
    private func sanitizedOptions() -> [String]? {
        guard field.type == .dropdown || field.type == .radio || field.type == .checkbox else {
            return nil
        }
        let cleaned = options.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        return cleaned.isEmpty ? nil : cleaned
    }
    
    private func sanitizedDefaultValue() -> String? {
        let trimmed = defaultValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

// MARK: - Form Preview

struct FormPreviewView: View {
    let formName: String
    let companyName: String
    let headerText: String
    let footerText: String
    let fields: [FormField]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    if !companyName.isEmpty {
                        Text(companyName)
                            .font(.title)
                            .bold()
                    }
                    
                    if !headerText.isEmpty {
                        Text(headerText)
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(formName)
                        .font(.headline)
                    
                    Text("Preview Mode")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                Divider()
                
                // Fields
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(fields) { field in
                        PreviewFieldView(field: field)
                    }
                }
                
                if !footerText.isEmpty {
                    Divider()
                    Text(footerText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct PreviewFieldView: View {
    let field: FormField
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(field.label)
                    .font(.subheadline)
                if field.isRequired {
                    Text("*")
                        .foregroundColor(.red)
                }
            }
            
            switch field.type {
            case .text, .number, .email, .phone:
                TextField(field.placeholder ?? "", text: .constant("") )
                    .textFieldStyle(.roundedBorder)
                    .disabled(true)
            case .multiline:
                TextEditor(text: .constant(""))
                    .frame(height: 120)
                    .border(Color.secondary.opacity(0.3))
                    .disabled(true)
            case .dropdown:
                Picker("", selection: .constant(field.options?.first ?? "")) {
                    ForEach(field.options ?? ["Option"], id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .disabled(true)
            case .radio:
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(field.options ?? ["Option"], id: \.self) { option in
                        HStack {
                            Image(systemName: "circle")
                            Text(option)
                        }
                        .foregroundColor(.secondary)
                    }
                }
            case .checkbox:
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(field.options ?? ["Option"], id: \.self) { option in
                        HStack {
                            Image(systemName: "square")
                            Text(option)
                        }
                        .foregroundColor(.secondary)
                    }
                }
            case .date:
                DatePicker("", selection: .constant(Date()), displayedComponents: .date)
                    .disabled(true)
            case .yesNo:
                Picker("", selection: .constant("")) {
                    Text("Yes").tag("Yes")
                    Text("No").tag("No")
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
                .disabled(true)
            case .signature:
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 80)
                    .overlay {
                        Text("Signature Area")
                            .foregroundColor(.secondary)
                    }
            }
        }
    }
}
