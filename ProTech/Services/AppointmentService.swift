import Foundation
import CoreData
import EventKit

@MainActor
class AppointmentService {
    static let shared = AppointmentService()
    
    private let coreDataManager = CoreDataManager.shared
    private let notificationService = NotificationService.shared
    private let eventStore = EKEventStore()
    private let appointmentSyncer = AppointmentSyncer()
    
    private var context: NSManagedObjectContext {
        coreDataManager.viewContext
    }
    
    private init() {}
    
    // MARK: - Supabase Sync Methods
    
    /// Sync all appointments from Supabase
    @MainActor
    func syncAppointments() async throws {
        try await appointmentSyncer.download()
    }
    
    /// Sync appointments for a specific date range
    @MainActor
    func syncAppointments(from startDate: Date, to endDate: Date) async throws {
        try await appointmentSyncer.downloadForDateRange(from: startDate, to: endDate)
    }
    
    /// Start real-time sync subscriptions
    @MainActor
    func startRealtimeSync() async throws {
        try await appointmentSyncer.startRealtimeSync()
    }
    
    /// Stop real-time sync subscriptions
    @MainActor
    func stopRealtimeSync() async {
        await appointmentSyncer.stopRealtimeSync()
    }
    
    /// Upload pending local changes
    @MainActor
    func uploadPendingChanges() async throws {
        try await appointmentSyncer.uploadPendingChanges()
    }
    
    // MARK: - Appointment Creation
    
    /// Create a new appointment
    func createAppointment(
        customerId: UUID,
        ticketId: UUID? = nil,
        type: String,
        scheduledDate: Date,
        duration: Int16 = 30,
        notes: String? = nil
    ) -> Appointment {
        let appointment = Appointment(context: context)
        appointment.id = UUID()
        appointment.customerId = customerId
        appointment.ticketId = ticketId
        appointment.appointmentType = type
        appointment.scheduledDate = scheduledDate
        appointment.duration = duration
        appointment.status = "scheduled"
        appointment.notes = notes
        appointment.reminderSent = false
        appointment.confirmationSent = false
        appointment.createdAt = Date()
        appointment.updatedAt = Date()
        
        coreDataManager.save()
        
        // Send confirmation
        sendConfirmation(for: appointment)
        
        // Add to system calendar
        addToCalendar(appointment)
        NotificationCenter.default.post(name: .appointmentsDidChange, object: appointment)
        
        // Sync to Supabase
        Task { @MainActor in
            try? await appointmentSyncer.upload(appointment)
        }
        
        return appointment
    }
    
    /// Update appointment
    func updateAppointment(
        _ appointment: Appointment,
        scheduledDate: Date? = nil,
        duration: Int16? = nil,
        notes: String? = nil,
        status: String? = nil
    ) {
        if let scheduledDate = scheduledDate {
            appointment.scheduledDate = scheduledDate
        }
        if let duration = duration {
            appointment.duration = duration
        }
        if let notes = notes {
            appointment.notes = notes
        }
        if let status = status {
            appointment.status = status
            
            if status == "completed" {
                appointment.completedAt = Date()
            } else if status == "cancelled" {
                appointment.cancelledAt = Date()
            }
        }
        
        appointment.updatedAt = Date()
        coreDataManager.save()
        NotificationCenter.default.post(name: .appointmentsDidChange, object: appointment)
        
        // Sync to Supabase
        Task { @MainActor in
            try? await appointmentSyncer.upload(appointment)
        }
    }
    
    /// Cancel appointment
    func cancelAppointment(_ appointment: Appointment, reason: String? = nil) {
        appointment.status = "cancelled"
        appointment.cancelledAt = Date()
        appointment.cancellationReason = reason
        appointment.updatedAt = Date()
        
        coreDataManager.save()
        
        // Send cancellation notification
        sendCancellationNotification(for: appointment)
        NotificationCenter.default.post(name: .appointmentsDidChange, object: appointment)
        
        // Sync to Supabase
        Task { @MainActor in
            try? await appointmentSyncer.upload(appointment)
        }
    }
    
    /// Mark appointment as completed
    func completeAppointment(_ appointment: Appointment) {
        appointment.status = "completed"
        appointment.completedAt = Date()
        appointment.updatedAt = Date()
        
        coreDataManager.save()
        NotificationCenter.default.post(name: .appointmentsDidChange, object: appointment)
        
        // Sync to Supabase
        Task { @MainActor in
            try? await appointmentSyncer.upload(appointment)
        }
    }
    
    /// Mark appointment as no-show
    func markAsNoShow(_ appointment: Appointment) {
        appointment.status = "no_show"
        appointment.updatedAt = Date()
        
        coreDataManager.save()
        NotificationCenter.default.post(name: .appointmentsDidChange, object: appointment)
        
        // Sync to Supabase
        Task { @MainActor in
            try? await appointmentSyncer.upload(appointment)
        }
    }
    
    /// Confirm appointment
    func confirmAppointment(_ appointment: Appointment) {
        appointment.status = "confirmed"
        appointment.updatedAt = Date()
        
        coreDataManager.save()
        NotificationCenter.default.post(name: .appointmentsDidChange, object: appointment)
        
        // Sync to Supabase
        Task { @MainActor in
            try? await appointmentSyncer.upload(appointment)
        }
    }
    
    // MARK: - Fetch Operations
    
    /// Fetch all appointments
    func fetchAppointments(sortBy: AppointmentSortOption = .dateAsc) -> [Appointment] {
        let request: NSFetchRequest<Appointment> = Appointment.fetchRequest()
        request.sortDescriptors = sortBy.sortDescriptors
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching appointments: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Fetch appointments for a customer
    func fetchAppointments(for customerId: UUID) -> [Appointment] {
        let request: NSFetchRequest<Appointment> = Appointment.fetchRequest()
        request.predicate = NSPredicate(format: "customerId == %@", customerId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Appointment.scheduledDate, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching customer appointments: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Fetch appointments for a date
    func fetchAppointments(for date: Date) -> [Appointment] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<Appointment> = Appointment.fetchRequest()
        request.predicate = NSPredicate(
            format: "scheduledDate >= %@ AND scheduledDate < %@",
            startOfDay as NSDate, endOfDay as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Appointment.scheduledDate, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching appointments for date: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Fetch appointments for date range
    func fetchAppointments(from startDate: Date, to endDate: Date) -> [Appointment] {
        let request: NSFetchRequest<Appointment> = Appointment.fetchRequest()
        request.predicate = NSPredicate(
            format: "scheduledDate >= %@ AND scheduledDate <= %@",
            startDate as NSDate, endDate as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Appointment.scheduledDate, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching appointments for range: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Fetch upcoming appointments
    func fetchUpcomingAppointments(limit: Int = 10) -> [Appointment] {
        let request: NSFetchRequest<Appointment> = Appointment.fetchRequest()
        request.predicate = NSPredicate(
            format: "scheduledDate > %@ AND (status == %@ OR status == %@)",
            Date() as NSDate, "scheduled", "confirmed"
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Appointment.scheduledDate, ascending: true)]
        request.fetchLimit = limit
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching upcoming appointments: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Fetch today's appointments
    func fetchTodaysAppointments() -> [Appointment] {
        return fetchAppointments(for: Date())
    }
    
    // MARK: - Availability Checking
    
    /// Check if time slot is available
    func isTimeSlotAvailable(date: Date, duration: Int16) -> Bool {
        let endDate = Calendar.current.date(byAdding: .minute, value: Int(duration), to: date)!
        
        let appointments = fetchAppointments(for: date)
        
        for appointment in appointments where appointment.status != "cancelled" {
            guard let appointmentStart = appointment.scheduledDate,
                  let appointmentEnd = appointment.endDate else { continue }
            
            // Check for overlap
            if (date >= appointmentStart && date < appointmentEnd) ||
               (endDate > appointmentStart && endDate <= appointmentEnd) ||
               (date <= appointmentStart && endDate >= appointmentEnd) {
                return false
            }
        }
        
        return true
    }
    
    /// Get available time slots for a date
    func getAvailableTimeSlots(
        for date: Date,
        duration: Int16 = 30,
        startHour: Int = 9,
        endHour: Int = 17
    ) -> [Date] {
        var availableSlots: [Date] = []
        let calendar = Calendar.current
        
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = startHour
        components.minute = 0
        
        guard var currentTime = calendar.date(from: components) else { return [] }
        
        components.hour = endHour
        guard let endTime = calendar.date(from: components) else { return [] }
        
        while currentTime < endTime {
            if isTimeSlotAvailable(date: currentTime, duration: duration) {
                availableSlots.append(currentTime)
            }
            currentTime = calendar.date(byAdding: .minute, value: Int(duration), to: currentTime)!
        }
        
        return availableSlots
    }
    
    // MARK: - Calendar Integration
    
    /// Request calendar access
    /// Request calendar access
    func requestCalendarAccess() async -> Bool {
        return await withCheckedContinuation { continuation in
            if #available(iOS 17.0, macOS 14.0, *) {
                eventStore.requestFullAccessToEvents { granted, error in
                    continuation.resume(returning: granted)
                }
            } else {
                // Fallback for older OS versions
                eventStore.requestAccess(to: .event) { granted, error in
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    /// Add appointment to system calendar
    private func addToCalendar(_ appointment: Appointment) {
        guard let scheduledDate = appointment.scheduledDate,
              let endDate = appointment.endDate else { return }
        
        Task {
            let granted = await requestCalendarAccess()
            guard granted else { return }
            
            let event = EKEvent(eventStore: self.eventStore)
            event.title = "\(appointment.typeDisplayName) - \(self.getCustomerName(appointment.customerId))"
            event.startDate = scheduledDate
            event.endDate = endDate
            event.notes = appointment.notes
            event.calendar = self.eventStore.defaultCalendarForNewEvents
            
            // Add alarm 1 hour before
            let alarm = EKAlarm(relativeOffset: -3600)
            event.addAlarm(alarm)
            
            do {
                try self.eventStore.save(event, span: .thisEvent)
            } catch {
                print("Error saving to calendar: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Notifications
    
    /// Send confirmation notification
    private func sendConfirmation(for appointment: Appointment) {
        guard let customer = coreDataManager.fetchCustomer(id: appointment.customerId ?? UUID()),
              let scheduledDate = appointment.scheduledDate else { return }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        let subject = "Appointment Confirmed - \(appointment.typeDisplayName)"
        let body = """
        Hi \(customer.firstName ?? ""),
        
        Your \(appointment.typeDisplayName.lowercased()) appointment has been confirmed for:
        \(dateFormatter.string(from: scheduledDate))
        
        Duration: \(appointment.formattedDuration)
        
        \(appointment.notes ?? "")
        
        Please arrive 5 minutes early.
        
        Thank you,
        ProTech
        """
        
        notificationService.sendManualNotification(
            to: customer,
            ticket: nil,
            subject: subject,
            body: body,
            notificationType: "email"
        )
        
        appointment.confirmationSent = true
        coreDataManager.save()
    }
    
    /// Send cancellation notification
    private func sendCancellationNotification(for appointment: Appointment) {
        guard let customer = coreDataManager.fetchCustomer(id: appointment.customerId ?? UUID()),
              let scheduledDate = appointment.scheduledDate else { return }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        let subject = "Appointment Cancelled"
        let body = """
        Hi \(customer.firstName ?? ""),
        
        Your appointment scheduled for \(dateFormatter.string(from: scheduledDate)) has been cancelled.
        
        \(appointment.cancellationReason ?? "")
        
        Please contact us to reschedule.
        
        Thank you,
        ProTech
        """
        
        notificationService.sendManualNotification(
            to: customer,
            ticket: nil,
            subject: subject,
            body: body,
            notificationType: "email"
        )
    }
    
    /// Send reminder notifications
    func sendReminders() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let appointments = fetchAppointments(for: tomorrow)
        
        for appointment in appointments where !appointment.reminderSent && appointment.status != "cancelled" {
            sendReminder(for: appointment)
        }
    }
    
    private func sendReminder(for appointment: Appointment) {
        guard let customer = coreDataManager.fetchCustomer(id: appointment.customerId ?? UUID()),
              let scheduledDate = appointment.scheduledDate else { return }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        let subject = "Appointment Reminder - Tomorrow"
        let body = """
        Hi \(customer.firstName ?? ""),
        
        This is a reminder about your upcoming appointment:
        \(dateFormatter.string(from: scheduledDate))
        
        Type: \(appointment.typeDisplayName)
        Duration: \(appointment.formattedDuration)
        
        We look forward to seeing you!
        
        ProTech
        """
        
        notificationService.sendManualNotification(
            to: customer,
            ticket: nil,
            subject: subject,
            body: body,
            notificationType: "both"
        )
        
        appointment.reminderSent = true
        coreDataManager.save()
    }
    
    // MARK: - Helper Methods
    
    private func getCustomerName(_ customerId: UUID?) -> String {
        guard let customerId = customerId,
              let customer = coreDataManager.fetchCustomer(id: customerId) else {
            return "Customer"
        }
        return "\(customer.firstName ?? "") \(customer.lastName ?? "")".trimmingCharacters(in: .whitespaces)
    }
    
    /// Delete appointment
    func deleteAppointment(_ appointment: Appointment) {
        // Soft delete in Supabase, hard delete locally
        Task { @MainActor in
            try? await appointmentSyncer.softDelete(appointment)
        }
        
        context.delete(appointment)
        coreDataManager.save()
        NotificationCenter.default.post(name: .appointmentsDidChange, object: appointment)
    }
    
    // MARK: - Statistics
    
    /// Get appointment statistics
    func getAppointmentStats() -> (total: Int, upcoming: Int, today: Int, completed: Int) {
        let all = fetchAppointments()
        let upcoming = all.filter { $0.isUpcoming }.count
        let today = fetchTodaysAppointments().count
        let completed = all.filter { $0.status == "completed" }.count
        
        return (all.count, upcoming, today, completed)
    }
}

// MARK: - Sort Options

enum AppointmentSortOption: String, CaseIterable {
    case dateAsc = "Date (Earliest First)"
    case dateDesc = "Date (Latest First)"
    case typeAsc = "Type"
    case statusAsc = "Status"
    
    var sortDescriptors: [NSSortDescriptor] {
        switch self {
        case .dateAsc:
            return [NSSortDescriptor(keyPath: \Appointment.scheduledDate, ascending: true)]
        case .dateDesc:
            return [NSSortDescriptor(keyPath: \Appointment.scheduledDate, ascending: false)]
        case .typeAsc:
            return [NSSortDescriptor(keyPath: \Appointment.appointmentType, ascending: true)]
        case .statusAsc:
            return [NSSortDescriptor(keyPath: \Appointment.status, ascending: true)]
        }
    }
}
