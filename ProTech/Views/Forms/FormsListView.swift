//
//  FormsListView.swift
//  ProTech
//
//  Forms management view (Pro feature)
//

import SwiftUI

struct FormsListView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FormTemplate.createdAt, ascending: false)]
    ) var templates: FetchedResults<FormTemplate>
    
    @State private var showingEditor = false
    
    var body: some View {
        VStack {
            if templates.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("No Form Templates")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("Form templates will be loaded automatically")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(templates) { template in
                        FormRow(template: template)
                    }
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle("Forms")
        .toolbar {
            ToolbarItem {
                Button {
                    showingEditor = true
                } label: {
                    Label("New Form", systemImage: "plus")
                }
            }
        }
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
