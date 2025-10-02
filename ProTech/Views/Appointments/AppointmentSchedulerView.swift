import SwiftUI
import CoreData
#if canImport(UIKit)
import UIKit
#endif

struct AppointmentSchedulerView: View {
    @State private var appointments: [Appointment] = []
    @State private var selectedDate = Date()
    @State private var showingNewAppointment = false
    @State private var selectedAppointment: Appointment?
    @State private var viewMode: ViewMode = .day
    
    private let appointmentService = AppointmentService.shared
    private let calendar = Calendar.current
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerView
                
                Divider()
                
                // Controls
                controlsView
                
                Divider()
                
                // Calendar/List View
                if viewMode == .list {
                    listView
                } else {
                    calendarView
                }
            }
            .onAppear {
                loadAppointments()
            }
            .onReceive(NotificationCenter.default.publisher(for: .appointmentsDidChange)) { _ in
                loadAppointments()
            }
            .sheet(isPresented: $showingNewAppointment) {
                NewAppointmentView(selectedDate: selectedDate)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                    .onDisappear {
                        loadAppointments()
                    }
            }
            .navigationDestination(item: $selectedAppointment) { appointment in
                AppointmentDetailView(appointment: appointment)
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Appointments")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(todaysSummary)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Statistics
            statisticsView
            
            Spacer()
            
            Button(action: { showingNewAppointment = true }) {
                Label("New Appointment", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private var todaysSummary: String {
        let todaysAppointments = appointmentService.fetchTodaysAppointments()
        return "\(todaysAppointments.count) appointment\(todaysAppointments.count == 1 ? "" : "s") today"
    }
    
    private var statisticsView: some View {
        let stats = appointmentService.getAppointmentStats()
        
        return HStack(spacing: 20) {
            AppointmentStatCard(
                title: "Today",
                value: "\(stats.today)",
                color: .blue
            )
            
            AppointmentStatCard(
                title: "Upcoming",
                value: "\(stats.upcoming)",
                color: .green
            )
            
            AppointmentStatCard(
                title: "Completed",
                value: "\(stats.completed)",
                color: .gray
            )
        }
    }
    
    // MARK: - Controls
    
    private var controlsView: some View {
        HStack {
            // Date navigation
            Button(action: previousDay) {
                Image(systemName: "chevron.left")
            }
            
            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .onChange(of: selectedDate, initial: false) { _, _ in
                    loadAppointments()
                }
            
            Button(action: nextDay) {
                Image(systemName: "chevron.right")
            }
            
            Button("Today") {
                selectedDate = Date()
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            // View mode toggle
            Picker("View", selection: $viewMode) {
                Label("Day", systemImage: "calendar.day.timeline.left").tag(ViewMode.day)
                Label("Week", systemImage: "calendar").tag(ViewMode.week)
                Label("List", systemImage: "list.bullet").tag(ViewMode.list)
            }
            .pickerStyle(.segmented)
            .frame(width: 300)
        }
        .padding()
    }
    
    // MARK: - Calendar View
    
    private var calendarView: some View {
        ScrollView {
            VStack(spacing: 0) {
                if viewMode == .day {
                    dayView
                } else {
                    weekView
                }
            }
            .padding()
        }
    }
    
    private var dayView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Time slots
            ForEach(9..<18) { hour in
                HStack(alignment: .top, spacing: 12) {
                    // Time label
                    Text(formatHour(hour))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 60, alignment: .trailing)
                    
                    // Appointment slot
                    VStack(spacing: 0) {
                        Divider()
                        
                        ZStack(alignment: .topLeading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.05))
                                .frame(height: 60)
                            
                            // Appointments in this hour
                            ForEach(appointmentsForHour(hour)) { appointment in
                                AppointmentBlock(appointment: appointment)
                                    .onTapGesture {
                                        selectedAppointment = appointment
                                    }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var weekView: some View {
        VStack {
            Text("Week View")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding()
            
            Text("Coming soon - showing day view for now")
                .font(.caption)
                .foregroundColor(.secondary)
            
            dayView
        }
    }
    
    // MARK: - List View
    
    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(appointments) { appointment in
                    AppointmentListRow(appointment: appointment)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedAppointment = appointment
                        }
                        .contextMenu {
                            appointmentContextMenu(for: appointment)
                        }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Context Menu
    
    private func appointmentContextMenu(for appointment: Appointment) -> some View {
        Group {
            Button(action: { selectedAppointment = appointment }) {
                Label("View Details", systemImage: "eye")
            }
            
            if appointment.status == "scheduled" {
                Button(action: { confirmAppointment(appointment) }) {
                    Label("Confirm", systemImage: "checkmark.circle")
                }
            }
            
            if appointment.status != "completed" && appointment.status != "cancelled" {
                Button(action: { completeAppointment(appointment) }) {
                    Label("Mark Complete", systemImage: "checkmark")
                }
            }
            
            Divider()
            
            Button(role: .destructive, action: { cancelAppointment(appointment) }) {
                Label("Cancel", systemImage: "xmark.circle")
            }
        }
    }
    
    // MARK: - Actions
    
    private func loadAppointments() {
        if viewMode == .list {
            appointments = appointmentService.fetchUpcomingAppointments(limit: 50)
        } else {
            appointments = appointmentService.fetchAppointments(for: selectedDate)
        }
    }
    
    private func previousDay() {
        selectedDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
    }
    
    private func nextDay() {
        selectedDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
    }
    
    private func confirmAppointment(_ appointment: Appointment) {
        appointmentService.confirmAppointment(appointment)
        loadAppointments()
    }
    
    private func completeAppointment(_ appointment: Appointment) {
        appointmentService.completeAppointment(appointment)
        loadAppointments()
    }
    
    private func cancelAppointment(_ appointment: Appointment) {
        appointmentService.cancelAppointment(appointment, reason: "Cancelled by staff")
        loadAppointments()
    }
    
    // MARK: - Helper Methods
    
    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:00 a"
        
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        components.hour = hour
        
        guard let date = calendar.date(from: components) else { return "" }
        return formatter.string(from: date)
    }
    
    private func appointmentsForHour(_ hour: Int) -> [Appointment] {
        return appointments.filter { appointment in
            guard let scheduledDate = appointment.scheduledDate else { return false }
            let appointmentHour = calendar.component(.hour, from: scheduledDate)
            return appointmentHour == hour
        }
    }
}

// MARK: - Appointment Block

struct AppointmentBlock: View {
    let appointment: Appointment
    private let coreDataManager = CoreDataManager.shared
    
    var customer: Customer? {
        guard let customerId = appointment.customerId else { return nil }
        return coreDataManager.fetchCustomer(id: customerId)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                
                Text(appointment.typeDisplayName)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            
            if let customer = customer {
                Text("\(customer.firstName ?? "") \(customer.lastName ?? "")")
                    .font(.caption)
            }
            
            Text(appointment.formattedDuration)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(statusColor.opacity(0.2))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(statusColor, lineWidth: 2)
        )
    }
    
    private var statusColor: Color {
        switch appointment.status {
        case "confirmed":
            return .green
        case "scheduled":
            return .blue
        case "completed":
            return .gray
        case "cancelled":
            return .red
        default:
            return .orange
        }
    }
}

// MARK: - Appointment List Row

struct AppointmentListRow: View {
    let appointment: Appointment
    private let coreDataManager = CoreDataManager.shared
    
    var customer: Customer? {
        guard let customerId = appointment.customerId else { return nil }
        return coreDataManager.fetchCustomer(id: customerId)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
            
            // Appointment info
            VStack(alignment: .leading, spacing: 4) {
                Text(appointment.typeDisplayName)
                    .font(.headline)
                
                if let customer = customer {
                    Text("\(customer.firstName ?? "") \(customer.lastName ?? "")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 150, alignment: .leading)
            
            // Date and time
            if let scheduledDate = appointment.scheduledDate {
                VStack(alignment: .leading, spacing: 4) {
                    Text(scheduledDate, style: .date)
                        .font(.subheadline)
                    Text(scheduledDate, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(width: 120, alignment: .leading)
            }
            
            // Duration
            Text(appointment.formattedDuration)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)
            
            Spacer()
            
            // Status badge
            Text(appointment.status?.capitalized ?? "")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.2))
                .foregroundColor(statusColor)
                .cornerRadius(4)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    private var statusColor: Color {
        switch appointment.status {
        case "confirmed":
            return .green
        case "scheduled":
            return .blue
        case "completed":
            return .gray
        case "cancelled":
            return .red
        case "no_show":
            return .orange
        default:
            return .gray
        }
    }
}

// MARK: - Stat Card

struct AppointmentStatCard: View {
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

// MARK: - View Mode

enum ViewMode {
    case day
    case week
    case list
}

// MARK: - Preview

struct AppointmentSchedulerView_Previews: PreviewProvider {
    static var previews: some View {
        AppointmentSchedulerView()
    }
}

// MARK: - Placeholder Views

/// Temporary placeholder form for creating a new appointment.
struct NewAppointmentView: View {
    @Environment(\.dismiss) private var dismiss
    @FetchRequest private var customers: FetchedResults<Customer>
    @State private var appointmentType = "consultation"
    @State private var duration: Double = 30
    @State private var notes = ""
    @State private var searchText = ""
    @State private var selectedCustomer: Customer?
    @State private var showingNewCustomer = false

    let selectedDate: Date

    private let appointmentService = AppointmentService.shared

    init(selectedDate: Date) {
        self.selectedDate = selectedDate
        _customers = FetchRequest(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Customer.lastName, ascending: true),
                NSSortDescriptor(keyPath: \Customer.firstName, ascending: true)
            ]
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Customer") {
                    HStack {
                        TextField("Search customer...", text: $searchText)

                        Button {
                            showingNewCustomer = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .buttonStyle(.borderless)
                        .help("Add a new customer")
                    }

                    if customers.isEmpty {
                        Text("No customers available. Add a customer to schedule appointments.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if searchText.isEmpty && selectedCustomer == nil {
                        Text("Type to search for a customer")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if !filteredCustomers.isEmpty {
                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(filteredCustomers.prefix(8)) { customer in
                                    Button {
                                        selectedCustomer = customer
                                        searchText = customer.displayName
                                        dismissKeyboard()
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(customer.displayName)
                                                    .font(.body)
                                                if let phone = customer.phone, !phone.isEmpty {
                                                    Text(phone)
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            Spacer()
                                            if selectedCustomer?.id == customer.id {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.green)
                                            }
                                        }
                                        .padding(8)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(selectedCustomer?.id == customer.id ? Color.blue.opacity(0.1) : Color.clear)
                                        .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                    } else if !searchText.isEmpty {
                        Text("No matching customers found")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let selectedCustomer {
                        Divider()
                        LabeledContent("Selected") {
                            Text(selectedCustomer.displayName)
                                .fontWeight(.semibold)
                        }
                    }
                }

                Section("When") {
                    DatePicker("Scheduled", selection: .constant(selectedDate), displayedComponents: [.date, .hourAndMinute])
                        .disabled(true)
                    Stepper(value: $duration, in: 15...240, step: 15) {
                        Text("Duration: \(Int(duration)) minutes")
                    }
                }

                Section("Details") {
                    Picker("Type", selection: $appointmentType) {
                        Text("Consultation").tag("consultation")
                        Text("Repair").tag("repair")
                        Text("Pickup").tag("pickup")
                        Text("Drop-off").tag("dropoff")
                    }

                    TextEditor(text: $notes)
                        .frame(height: 100)
                }

                Section(footer: Text("Appointments must be associated with a registered customer.")) {
                    Button("Save Appointment") {
                        createAppointment()
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("New Appointment")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .frame(width: 600, height: 520)
        .sheet(isPresented: $showingNewCustomer) {
            AddCustomerView()
        }
    }

    private var filteredCustomers: [Customer] {
        guard !searchText.isEmpty else { return Array(customers) }
        return customers.filter { customer in
            customer.displayName.localizedCaseInsensitiveContains(searchText) ||
            (customer.phone?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (customer.email?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    private var isValid: Bool {
        selectedCustomer?.id != nil
    }

    private func createAppointment() {
        guard let customer = selectedCustomer, let customerId = customer.id else { return }

        _ = appointmentService.createAppointment(
            customerId: customerId,
            type: appointmentType,
            scheduledDate: selectedDate,
            duration: Int16(duration),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes
        )
    }

    private func dismissKeyboard() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
}

/// Lightweight detail view for displaying an appointment record.
struct AppointmentDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteConfirmation = false

    let appointment: Appointment

    private let appointmentService = AppointmentService.shared
    private let coreDataManager = CoreDataManager.shared

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private var customer: Customer? {
        guard let id = appointment.customerId else { return nil }
        return coreDataManager.fetchCustomer(id: id)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Appointment") {
                    Text("Type: \(appointment.typeDisplayName)")
                    if let scheduledDate = appointment.scheduledDate {
                        Text("Scheduled: \(dateFormatter.string(from: scheduledDate))")
                    }
                    Text("Duration: \(appointment.duration) minutes")
                    if let status = appointment.status?.capitalized {
                        Text("Status: \(status)")
                    }
                }

                if let customer {
                    Section("Customer") {
                        Text(customer.displayName)
                        if let phone = customer.phone, !phone.isEmpty {
                            Label(phone, systemImage: "phone")
                        }
                        if let email = customer.email, !email.isEmpty {
                            Label(email, systemImage: "envelope")
                        }
                    }
                }

                if let notes = appointment.notes, !notes.isEmpty {
                    Section("Notes") {
                        Text(notes)
                    }
                }

                if appointment.status == "scheduled" {
                    Section {
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete Appointment", systemImage: "trash")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Appointment Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Delete Appointment?", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    appointmentService.deleteAppointment(appointment)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently remove the scheduled appointment for \(customer?.displayName ?? "this customer").")
            }
        }
        .frame(width: 600, height: 520)
    }
}
