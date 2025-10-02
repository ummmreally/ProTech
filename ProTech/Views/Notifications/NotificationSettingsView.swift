import SwiftUI

struct NotificationSettingsView: View {
    @State private var rules: [NotificationRule] = []
    @State private var showingAddRule = false
    @State private var selectedRule: NotificationRule?
    @State private var showingLogs = false
    
    private let notificationService = NotificationService.shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerView
                
                Divider()
                
                // Rules list
                if rules.isEmpty {
                    emptyStateView
                } else {
                    rulesListView
                }
            }
            .onAppear {
                loadRules()
            }
            .sheet(isPresented: $showingAddRule) {
                NotificationRuleEditorView(rule: nil)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .onDisappear {
                        loadRules()
                    }
            }
            .sheet(item: $selectedRule) { rule in
                NotificationRuleEditorView(rule: rule)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .onDisappear {
                        loadRules()
                    }
            }
            .sheet(isPresented: $showingLogs) {
                NotificationLogsView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Automated Notifications")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("\(rules.count) notification rule\(rules.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Statistics
            statisticsView
            
            Spacer()
            
            Button(action: { showingLogs = true }) {
                Label("View Logs", systemImage: "list.bullet.rectangle")
            }
            .buttonStyle(.bordered)
            
            Button(action: initializeDefaults) {
                Label("Load Defaults", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            
            Button(action: { showingAddRule = true }) {
                Label("Add Rule", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private var statisticsView: some View {
        let stats = notificationService.getNotificationStats()
        
        return HStack(spacing: 20) {
            NotificationStatCard(
                title: "Sent",
                value: "\(stats.sent)",
                color: .green
            )
            
            NotificationStatCard(
                title: "Failed",
                value: "\(stats.failed)",
                color: .red
            )
            
            NotificationStatCard(
                title: "Pending",
                value: "\(stats.pending)",
                color: .orange
            )
        }
    }
    
    // MARK: - Rules List
    
    private var rulesListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(rules) { rule in
                    NotificationRuleRow(rule: rule)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedRule = rule
                        }
                        .contextMenu {
                            ruleContextMenu(for: rule)
                        }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.badge")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Notification Rules")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create automated notifications to keep customers informed")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 12) {
                Button(action: initializeDefaults) {
                    Label("Load Default Rules", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                
                Button(action: { showingAddRule = true }) {
                    Label("Create Custom Rule", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Context Menu
    
    private func ruleContextMenu(for rule: NotificationRule) -> some View {
        Group {
            Button(action: { selectedRule = rule }) {
                Label("Edit", systemImage: "pencil")
            }
            
            Button(action: { toggleRule(rule) }) {
                Label(rule.isEnabled ? "Disable" : "Enable", systemImage: rule.isEnabled ? "pause.circle" : "play.circle")
            }
            
            Divider()
            
            Button(role: .destructive, action: { deleteRule(rule) }) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Actions
    
    private func loadRules() {
        rules = notificationService.fetchRules()
    }
    
    private func initializeDefaults() {
        notificationService.initializeDefaultRules()
        loadRules()
    }
    
    private func toggleRule(_ rule: NotificationRule) {
        notificationService.updateRule(rule, isEnabled: !rule.isEnabled)
        loadRules()
    }
    
    private func deleteRule(_ rule: NotificationRule) {
        notificationService.deleteRule(rule)
        loadRules()
    }
}

// MARK: - Notification Rule Row

struct NotificationRuleRow: View {
    let rule: NotificationRule
    
    var body: some View {
        HStack(spacing: 16) {
            // Status indicator
            Circle()
                .fill(rule.isEnabled ? Color.green : Color.gray)
                .frame(width: 12, height: 12)
            
            // Rule info
            VStack(alignment: .leading, spacing: 4) {
                Text(rule.displayName)
                    .font(.headline)
                
                Text(rule.triggerDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Notification type badges
            HStack(spacing: 8) {
                if rule.isEmailEnabled {
                    Label("Email", systemImage: "envelope.fill")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
                
                if rule.isSMSEnabled {
                    Label("SMS", systemImage: "message.fill")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(4)
                }
            }
            
            // Enabled/Disabled badge
            Text(rule.isEnabled ? "Enabled" : "Disabled")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(rule.isEnabled ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                .foregroundColor(rule.isEnabled ? .green : .gray)
                .cornerRadius(4)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Notification Rule Editor

struct NotificationRuleEditorView: View {
    @Environment(\.dismiss) var dismiss
    
    let rule: NotificationRule?
    
    @State private var name = ""
    @State private var statusTrigger = "completed"
    @State private var notificationType = "email"
    @State private var emailSubject = ""
    @State private var emailBody = ""
    @State private var smsBody = ""
    
    private let notificationService = NotificationService.shared
    
    var isEditing: Bool {
        rule != nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Rule Details") {
                    TextField("Rule Name", text: $name)
                    
                    Picker("Trigger Status", selection: $statusTrigger) {
                        Text("Checked In").tag("checked_in")
                        Text("In Progress").tag("in_progress")
                        Text("Completed").tag("completed")
                        Text("Ready for Pickup").tag("ready_for_pickup")
                        Text("Picked Up").tag("picked_up")
                    }
                    
                    Picker("Notification Type", selection: $notificationType) {
                        Text("Email Only").tag("email")
                        Text("SMS Only").tag("sms")
                        Text("Both Email & SMS").tag("both")
                    }
                }
                
                if notificationType == "email" || notificationType == "both" {
                    Section("Email Template") {
                        TextField("Subject", text: $emailSubject)
                        
                        Text("Available placeholders:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("{customer_name}, {ticket_number}, {device_type}, {device_model}, {status}")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $emailBody)
                            .frame(height: 150)
                            .font(.body)
                    }
                }
                
                if notificationType == "sms" || notificationType == "both" {
                    Section("SMS Template") {
                        Text("Available placeholders:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("{customer_name}, {ticket_number}, {device_type}, {status}")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $smsBody)
                            .frame(height: 100)
                            .font(.body)
                        
                        Text("\(smsBody.count)/160 characters")
                            .font(.caption)
                            .foregroundColor(smsBody.count > 160 ? .red : .secondary)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(isEditing ? "Edit Rule" : "New Rule")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRule()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .frame(width: 700, height: 650)
        .onAppear {
            loadRuleData()
        }
    }
    
    private func loadRuleData() {
        if let rule = rule {
            name = rule.name ?? ""
            statusTrigger = rule.statusTrigger ?? "completed"
            notificationType = rule.notificationType ?? "email"
            emailSubject = rule.emailSubject ?? ""
            emailBody = rule.emailBody ?? ""
            smsBody = rule.smsBody ?? ""
        } else {
            // Load default template
            let templates = notificationService.getDefaultTemplates()
            if let template = templates[statusTrigger] {
                emailSubject = template.subject
                emailBody = template.emailBody
                smsBody = template.smsBody
            }
        }
    }
    
    private func saveRule() {
        if let existingRule = rule {
            notificationService.updateRule(
                existingRule,
                name: name,
                notificationType: notificationType,
                emailSubject: emailSubject,
                emailBody: emailBody,
                smsBody: smsBody
            )
        } else {
            _ = notificationService.createRule(
                name: name,
                triggerEvent: "status_change",
                statusTrigger: statusTrigger,
                notificationType: notificationType,
                emailSubject: emailSubject,
                emailBody: emailBody,
                smsBody: smsBody
            )
        }
        
        dismiss()
    }
}

// MARK: - Notification Logs View

struct NotificationLogsView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var logs: [NotificationLog] = []
    @State private var filterStatus = "all"
    
    private let notificationService = NotificationService.shared
    
    var filteredLogs: [NotificationLog] {
        if filterStatus == "all" {
            return logs
        }
        return logs.filter { $0.status == filterStatus }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Filter bar
                HStack {
                    Picker("Filter", selection: $filterStatus) {
                        Text("All").tag("all")
                        Text("Sent").tag("sent")
                        Text("Failed").tag("failed")
                        Text("Pending").tag("pending")
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 400)
                    
                    Spacer()
                }
                .padding()
                
                // Logs list
                List(filteredLogs) { log in
                    NotificationLogRow(log: log)
                }
            }
            .navigationTitle("Notification Logs")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 700, height: 600)
        .onAppear {
            loadLogs()
        }
    }
    
    private func loadLogs() {
        logs = notificationService.fetchRecentLogs()
    }
}

// MARK: - Stat Card

struct NotificationStatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding(12)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Notification Log Row

struct NotificationLogRow: View {
    let log: NotificationLog
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Type icon
                Image(systemName: log.notificationType == "email" ? "envelope.fill" : "message.fill")
                    .foregroundColor(log.notificationType == "email" ? .blue : .green)
                
                // Recipient
                Text(log.displayRecipient)
                    .font(.headline)
                
                Spacer()
                
                // Status badge
                Text(log.status?.capitalized ?? "Unknown")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor(log.status).opacity(0.2))
                    .foregroundColor(statusColor(log.status))
                    .cornerRadius(4)
                
                // Date
                if let createdAt = log.createdAt {
                    Text(createdAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Subject (for email)
            if let subject = log.subject, !subject.isEmpty {
                Text(subject)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Body preview
            if let body = log.body {
                Text(body)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            // Failure reason
            if let failureReason = log.failureReason {
                Text("Error: \(failureReason)")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func statusColor(_ status: String?) -> Color {
        switch status {
        case "sent":
            return .green
        case "failed":
            return .red
        case "pending":
            return .orange
        default:
            return .gray
        }
    }
}

// MARK: - Preview

struct NotificationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationSettingsView()
    }
}
