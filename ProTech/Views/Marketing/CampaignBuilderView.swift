//
//  CampaignBuilderView.swift
//  ProTech
//
//  Create and edit marketing campaigns
//

import SwiftUI

struct CampaignBuilderView: View {
    @Environment(\.dismiss) var dismiss
    
    let campaign: Campaign?
    
    @State private var name = ""
    @State private var campaignType = "review_request"
    @State private var emailSubject = ""
    @State private var emailBody = ""
    @State private var targetSegment = "all"
    @State private var daysAfterEvent = 3
    @State private var showingPreview = false
    
    private let marketingService = MarketingService.shared
    
    var isEditing: Bool {
        campaign != nil
    }
    
    let campaignTypes = [
        ("review_request", "Review Request"),
        ("follow_up", "Follow-up"),
        ("birthday", "Birthday"),
        ("anniversary", "Anniversary"),
        ("re_engagement", "Re-engagement"),
        ("promotional", "Promotional")
    ]
    
    let segments = [
        ("all", "All Customers"),
        ("recent_customers", "Recent Customers"),
        ("inactive", "Inactive Customers"),
        ("high_value", "High-Value Customers")
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Campaign Details") {
                    TextField("Campaign Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                    
                    Picker("Type", selection: $campaignType) {
                        ForEach(campaignTypes, id: \.0) { type in
                            Text(type.1).tag(type.0)
                        }
                    }
                    
                    Picker("Target Segment", selection: $targetSegment) {
                        ForEach(segments, id: \.0) { segment in
                            Text(segment.1).tag(segment.0)
                        }
                    }
                }
                
                Section("Timing") {
                    Stepper("Send \(daysAfterEvent) day\(daysAfterEvent == 1 ? "" : "s") after event", value: $daysAfterEvent, in: 0...30)
                    
                    Text("Email will be sent \(daysAfterEvent) days after the trigger event")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Email Content") {
                    TextField("Subject Line", text: $emailSubject)
                        .textFieldStyle(.roundedBorder)
                    
                    Text("Available placeholders:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("{first_name}, {last_name}, {customer_name}, {ticket_number}, {device_type}, {device_model}, {company_name}")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .textSelection(.enabled)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Email Body")
                            .font(.subheadline)
                        
                        TextEditor(text: $emailBody)
                            .frame(height: 200)
                            .font(.body)
                            .border(Color.gray.opacity(0.3))
                    }
                }
                
                Section {
                    Button {
                        showingPreview = true
                    } label: {
                        Label("Preview Email", systemImage: "eye")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .formStyle(.grouped)
            .navigationTitle(isEditing ? "Edit Campaign" : "New Campaign")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Update" : "Create") {
                        saveCampaign()
                    }
                    .disabled(!isValid)
                }
            }
        }
        .frame(width: 800, height: 700)
        .onAppear {
            loadCampaignData()
        }
        .sheet(isPresented: $showingPreview) {
            EmailPreviewView(subject: emailSubject, emailBody: emailBody)
        }
    }
    
    private var isValid: Bool {
        return !name.isEmpty && !emailSubject.isEmpty && !emailBody.isEmpty
    }
    
    private func loadCampaignData() {
        if let campaign = campaign {
            name = campaign.name ?? ""
            campaignType = campaign.campaignType ?? "review_request"
            emailSubject = campaign.emailSubject ?? ""
            emailBody = campaign.emailBody ?? ""
            targetSegment = campaign.targetSegment ?? "all"
            daysAfterEvent = Int(campaign.daysAfterEvent)
        } else {
            // Load default template
            loadDefaultTemplate(for: campaignType)
        }
    }
    
    private func loadDefaultTemplate(for type: String) {
        let templates = marketingService.getDefaultTemplates()
        if let template = templates.first(where: { $0.type == type }) {
            emailSubject = template.subject
            emailBody = template.body
        }
    }
    
    private func saveCampaign() {
        if let existingCampaign = campaign {
            marketingService.updateCampaign(
                existingCampaign,
                name: name,
                subject: emailSubject,
                body: emailBody
            )
        } else {
            _ = marketingService.createCampaign(
                name: name,
                type: campaignType,
                subject: emailSubject,
                body: emailBody,
                targetSegment: targetSegment,
                daysAfterEvent: daysAfterEvent
            )
        }
        
        dismiss()
    }
}

// MARK: - Email Preview

struct EmailPreviewView: View {
    @Environment(\.dismiss) var dismiss
    
    let subject: String
    let emailBody: String
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                // Email header
                VStack(alignment: .leading, spacing: 8) {
                    Text("From: no-reply@protech.com")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("To: customer@example.com")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    Text("Subject: \(subject)")
                        .font(.headline)
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
                
                // Email body
                ScrollView {
                    Text(emailBody)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                
                Text("* Placeholders will be replaced with actual customer data when sent")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationTitle("Email Preview")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 600, height: 500)
    }
}

// MARK: - Preview

struct CampaignBuilderView_Previews: PreviewProvider {
    static var previews: some View {
        CampaignBuilderView(campaign: nil)
    }
}
