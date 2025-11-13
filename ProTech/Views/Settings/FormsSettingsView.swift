//
//  FormsSettingsView.swift
//  ProTech
//
//  Forms customization settings
//

import SwiftUI

struct FormsSettingsView: View {
    @AppStorage("companyName") private var companyName = ""
    @AppStorage("companyAddress") private var companyAddress = ""
    @AppStorage("companyPhone") private var companyPhone = ""
    @AppStorage("formHeaderText") private var formHeaderText = "Device Repair Authorization"
    @AppStorage("formFooterText") private var formFooterText = "Thank you for your business!"
    
    @State private var showingTemplateManager = false
    
    var body: some View {
        Form {
            Section("Company Branding") {
                TextField("Company Name", text: $companyName)
                    .help("This will appear on all forms")
                TextField("Address", text: $companyAddress)
                TextField("Phone", text: $companyPhone)
            }
            
            Section("Form Customization") {
                TextField("Header Text", text: $formHeaderText)
                    .help("Appears at the top of forms")
                TextField("Footer Text", text: $formFooterText)
                    .help("Appears at the bottom of forms")
            }
            
            Section("Form Templates") {
                Button {
                    showingTemplateManager = true
                } label: {
                    Label("Manage Form Templates", systemImage: "doc.text")
                }
                .buttonStyle(.plain)
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pro Feature")
                        .font(.headline)
                    Text("Custom forms, PDF generation, and printing are included with Pro subscription.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .sheet(isPresented: $showingTemplateManager) {
            FormTemplateManagerView()
        }
    }
}
