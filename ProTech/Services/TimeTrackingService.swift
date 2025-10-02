//
//  TimeTrackingService.swift
//  ProTech
//
//  Time tracking management service
//

import Foundation
import CoreData
import Combine

class TimeTrackingService: ObservableObject {
    static let shared = TimeTrackingService()
    
    private let coreDataManager = CoreDataManager.shared
    private var timer: Timer?
    
    @Published var activeEntry: TimeEntry?
    @Published var elapsedTime: TimeInterval = 0
    
    private init() {
        loadActiveEntry()
    }
    
    // MARK: - Timer Controls
    
    func startTimer(for ticketId: UUID, technicianId: UUID? = nil, isBillable: Bool = true, hourlyRate: Decimal = 75.00) -> TimeEntry {
        // Stop any existing timer
        if let existing = activeEntry {
            stopTimer(existing)
        }
        
        let context = coreDataManager.viewContext
        let entry = TimeEntry(
            context: context,
            ticketId: ticketId,
            technicianId: technicianId,
            startTime: Date(),
            isBillable: isBillable,
            hourlyRate: hourlyRate
        )
        
        try? context.save()
        
        activeEntry = entry
        elapsedTime = 0
        startTimerLoop()
        
        return entry
    }
    
    func pauseTimer(_ entry: TimeEntry) {
        guard entry.isRunning && !entry.isPaused else { return }
        
        entry.isPaused = true
        entry.pausedAt = Date()
        entry.updatedAt = Date()
        
        try? coreDataManager.viewContext.save()
        stopTimerLoop()
    }
    
    func resumeTimer(_ entry: TimeEntry) {
        guard entry.isRunning && entry.isPaused else { return }
        
        if let pausedAt = entry.pausedAt {
            let pauseDuration = Date().timeIntervalSince(pausedAt)
            entry.totalPausedDuration += pauseDuration
        }
        
        entry.isPaused = false
        entry.pausedAt = nil
        entry.updatedAt = Date()
        
        try? coreDataManager.viewContext.save()
        startTimerLoop()
    }
    
    func stopTimer(_ entry: TimeEntry) {
        guard entry.isRunning else { return }
        
        // Calculate final duration
        if let startTime = entry.startTime {
            let totalElapsed = Date().timeIntervalSince(startTime)
            entry.duration = totalElapsed - entry.totalPausedDuration
        }
        
        entry.isRunning = false
        entry.isPaused = false
        entry.endTime = Date()
        entry.updatedAt = Date()
        
        try? coreDataManager.viewContext.save()
        
        if activeEntry?.id == entry.id {
            activeEntry = nil
            elapsedTime = 0
            stopTimerLoop()
        }
    }
    
    // MARK: - Manual Time Entry
    
    func createManualEntry(ticketId: UUID, startTime: Date, endTime: Date, notes: String? = nil, isBillable: Bool = true, hourlyRate: Decimal = 75.00, technicianId: UUID? = nil) -> TimeEntry {
        let context = coreDataManager.viewContext
        let entry = TimeEntry(
            context: context,
            ticketId: ticketId,
            technicianId: technicianId,
            startTime: startTime,
            isBillable: isBillable,
            hourlyRate: hourlyRate
        )
        
        entry.endTime = endTime
        entry.duration = endTime.timeIntervalSince(startTime)
        entry.notes = notes
        entry.isRunning = false
        
        try? context.save()
        
        return entry
    }
    
    func updateTimeEntry(_ entry: TimeEntry, startTime: Date? = nil, endTime: Date? = nil, notes: String? = nil, isBillable: Bool? = nil, hourlyRate: Decimal? = nil) {
        if let startTime = startTime {
            entry.startTime = startTime
        }
        if let endTime = endTime {
            entry.endTime = endTime
        }
        if let notes = notes {
            entry.notes = notes
        }
        if let isBillable = isBillable {
            entry.isBillable = isBillable
        }
        if let hourlyRate = hourlyRate {
            entry.hourlyRate = hourlyRate
        }
        
        // Recalculate duration if not running
        if !entry.isRunning, let start = entry.startTime, let end = entry.endTime {
            entry.duration = end.timeIntervalSince(start)
        }
        
        entry.updatedAt = Date()
        try? coreDataManager.viewContext.save()
    }
    
    func deleteTimeEntry(_ entry: TimeEntry) {
        let context = coreDataManager.viewContext
        
        if activeEntry?.id == entry.id {
            stopTimer(entry)
        }
        
        context.delete(entry)
        try? context.save()
    }
    
    // MARK: - Queries
    
    func getTimeEntries(for ticketId: UUID) -> [TimeEntry] {
        return TimeEntry.fetchTimeEntriesForTicket(ticketId, context: coreDataManager.viewContext)
    }
    
    func getTotalTime(for ticketId: UUID) -> TimeInterval {
        let entries = getTimeEntries(for: ticketId)
        return entries.reduce(0) { total, entry in
            if entry.isRunning {
                return total + entry.currentDuration
            }
            return total + entry.duration
        }
    }
    
    func getBillableTime(for ticketId: UUID) -> TimeInterval {
        let entries = getTimeEntries(for: ticketId)
        return entries.filter { $0.isBillable }.reduce(0) { total, entry in
            if entry.isRunning {
                return total + entry.currentDuration
            }
            return total + entry.duration
        }
    }
    
    func hasActiveTimer(for ticketId: UUID) -> Bool {
        guard let entry = activeEntry else { return false }
        return entry.ticketId == ticketId && entry.isRunning
    }

    func getTotalBillableAmount(for ticketId: UUID) -> Decimal {
        let entries = getTimeEntries(for: ticketId)
        return entries.reduce(Decimal.zero) { $0 + $1.billableAmount }
    }
    
    // MARK: - Productivity Reports
    
    func getProductivityStats(for technicianId: UUID, from startDate: Date, to endDate: Date) -> ProductivityStats {
        let entries = TimeEntry.fetchTimeEntriesForTechnician(technicianId, context: coreDataManager.viewContext)
            .filter { entry in
                guard let start = entry.startTime else { return false }
                return start >= startDate && start <= endDate
            }
        
        let totalHours = entries.reduce(0.0) { $0 + $1.duration / 3600.0 }
        let billableHours = entries.filter { $0.isBillable }.reduce(0.0) { $0 + $1.duration / 3600.0 }
        let totalRevenue = entries.reduce(Decimal.zero) { $0 + $1.billableAmount }
        let ticketCount = Set(entries.compactMap { $0.ticketId }).count
        
        return ProductivityStats(
            totalHours: totalHours,
            billableHours: billableHours,
            nonBillableHours: totalHours - billableHours,
            totalRevenue: totalRevenue,
            ticketCount: ticketCount,
            averageHoursPerTicket: ticketCount > 0 ? totalHours / Double(ticketCount) : 0
        )
    }
    
    func getDailyTimeEntries(for date: Date) -> [TimeEntry] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return TimeEntry.fetchTimeEntriesInDateRange(from: startOfDay, to: endOfDay, context: coreDataManager.viewContext)
    }
    
    // MARK: - Private Helpers
    
    private func loadActiveEntry() {
        activeEntry = TimeEntry.fetchRunningEntry(context: coreDataManager.viewContext)
        if let entry = activeEntry, !entry.isPaused {
            elapsedTime = entry.currentDuration
            startTimerLoop()
        }
    }
    
    private func startTimerLoop() {
        stopTimerLoop()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let entry = self.activeEntry else { return }
            
            if entry.isRunning && !entry.isPaused {
                self.elapsedTime = entry.currentDuration
            }
        }
    }
    
    private func stopTimerLoop() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Productivity Stats

struct ProductivityStats {
    let totalHours: Double
    let billableHours: Double
    let nonBillableHours: Double
    let totalRevenue: Decimal
    let ticketCount: Int
    let averageHoursPerTicket: Double
    
    var billablePercentage: Double {
        guard totalHours > 0 else { return 0 }
        return (billableHours / totalHours) * 100
    }
    
    var formattedTotalRevenue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: totalRevenue as NSDecimalNumber) ?? "$0.00"
    }
}
