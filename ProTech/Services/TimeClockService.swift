//
//  TimeClockService.swift
//  ProTech
//
//  Service for employee time clock operations
//

import Foundation
import CoreData

class TimeClockService: ObservableObject {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = CoreDataManager.shared.viewContext) {
        self.context = context
    }
    
    // MARK: - Clock Operations
    
    func clockIn(employeeId: UUID) throws -> TimeClockEntry {
        // Check if already clocked in
        if TimeClockEntry.fetchActiveEntry(for: employeeId, context: context) != nil {
            throw TimeClockError.alreadyClockedIn
        }
        
        let entry = TimeClockEntry(context: context, employeeId: employeeId)
        try context.save()
        
        return entry
    }
    
    func clockOut(employeeId: UUID, notes: String? = nil) throws -> TimeClockEntry {
        guard let entry = TimeClockEntry.fetchActiveEntry(for: employeeId, context: context) else {
            throw TimeClockError.notClockedIn
        }
        
        // End any active break
        if entry.onBreak {
            try endBreak(entry: entry)
        }
        
        entry.clockOutTime = Date()
        entry.isActive = false
        
        // Calculate total hours
        if let clockIn = entry.clockInTime, let clockOut = entry.clockOutTime {
            let totalSeconds = clockOut.timeIntervalSince(clockIn)
            entry.totalHours = totalSeconds - entry.totalBreakDuration
        }
        
        if let notes = notes {
            entry.notes = notes
        }
        
        entry.updatedAt = Date()
        try context.save()
        
        return entry
    }
    
    func startBreak(employeeId: UUID) throws -> TimeClockEntry {
        guard let entry = TimeClockEntry.fetchActiveEntry(for: employeeId, context: context) else {
            throw TimeClockError.notClockedIn
        }
        
        guard !entry.onBreak else {
            throw TimeClockError.alreadyOnBreak
        }
        
        entry.breakStartTime = Date()
        entry.updatedAt = Date()
        try context.save()
        
        return entry
    }
    
    func endBreak(entry: TimeClockEntry) throws {
        guard let breakStart = entry.breakStartTime else {
            throw TimeClockError.notOnBreak
        }
        
        entry.breakEndTime = Date()
        
        // Add to total break duration
        let breakDuration = entry.breakEndTime!.timeIntervalSince(breakStart)
        entry.totalBreakDuration += breakDuration
        
        // Clear break times
        entry.breakStartTime = nil
        entry.breakEndTime = nil
        
        entry.updatedAt = Date()
        try context.save()
    }
    
    func endBreak(employeeId: UUID) throws -> TimeClockEntry {
        guard let entry = TimeClockEntry.fetchActiveEntry(for: employeeId, context: context) else {
            throw TimeClockError.notClockedIn
        }
        
        guard entry.onBreak else {
            throw TimeClockError.notOnBreak
        }
        
        try endBreak(entry: entry)
        return entry
    }
    
    // MARK: - Status Checks
    
    func getActiveEntry(for employeeId: UUID) -> TimeClockEntry? {
        return TimeClockEntry.fetchActiveEntry(for: employeeId, context: context)
    }
    
    func isClockedIn(employeeId: UUID) -> Bool {
        return getActiveEntry(for: employeeId) != nil
    }
    
    func isOnBreak(employeeId: UUID) -> Bool {
        guard let entry = getActiveEntry(for: employeeId) else { return false }
        return entry.onBreak
    }
    
    // MARK: - Fetch Operations
    
    func fetchEntriesForEmployee(_ employeeId: UUID) -> [TimeClockEntry] {
        return TimeClockEntry.fetchEntriesForEmployee(employeeId, context: context)
    }
    
    func fetchEntriesInDateRange(from startDate: Date, to endDate: Date) -> [TimeClockEntry] {
        return TimeClockEntry.fetchEntriesInDateRange(from: startDate, to: endDate, context: context)
    }
    
    func fetchEntriesForEmployeeInDateRange(employeeId: UUID, from startDate: Date, to endDate: Date) -> [TimeClockEntry] {
        return TimeClockEntry.fetchEntriesForEmployeeInDateRange(employeeId: employeeId, from: startDate, to: endDate, context: context)
    }
    
    func fetchTodaysEntries(for employeeId: UUID) -> [TimeClockEntry] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return fetchEntriesForEmployeeInDateRange(employeeId: employeeId, from: startOfDay, to: endOfDay)
    }
    
    // MARK: - Analytics
    
    func getTotalHoursForEmployee(_ employeeId: UUID, from startDate: Date, to endDate: Date) -> TimeInterval {
        let entries = fetchEntriesForEmployeeInDateRange(employeeId: employeeId, from: startDate, to: endDate)
        return entries.reduce(0) { $0 + $1.totalHours }
    }
    
    func getTotalHoursThisWeek(for employeeId: UUID) -> TimeInterval {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        
        return getTotalHoursForEmployee(employeeId, from: startOfWeek, to: now)
    }
    
    func getTotalHoursThisMonth(for employeeId: UUID) -> TimeInterval {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        return getTotalHoursForEmployee(employeeId, from: startOfMonth, to: now)
    }
    
    func calculatePay(for employeeId: UUID, hourlyRate: Decimal, from startDate: Date, to endDate: Date) -> Decimal {
        let totalHours = getTotalHoursForEmployee(employeeId, from: startDate, to: endDate)
        let hours = Decimal(totalHours / 3600.0)
        return hours * hourlyRate
    }
    
    // MARK: - All Employees
    
    func getAllActiveClockedInEmployees() -> [(employee: Employee, entry: TimeClockEntry)] {
        let request = TimeClockEntry.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == true")
        
        guard let entries = try? context.fetch(request) else { return [] }
        
        var results: [(Employee, TimeClockEntry)] = []
        for entry in entries {
            guard let employeeId = entry.employeeId,
                  let employee = Employee.fetchActiveEmployees(context: context).first(where: { $0.id == employeeId }) else {
                continue
            }
            results.append((employee, entry))
        }
        
        return results
    }
}

// MARK: - Time Clock Errors
enum TimeClockError: LocalizedError {
    case alreadyClockedIn
    case notClockedIn
    case alreadyOnBreak
    case notOnBreak
    
    var errorDescription: String? {
        switch self {
        case .alreadyClockedIn:
            return "Already clocked in"
        case .notClockedIn:
            return "Not clocked in"
        case .alreadyOnBreak:
            return "Already on break"
        case .notOnBreak:
            return "Not on break"
        }
    }
}
