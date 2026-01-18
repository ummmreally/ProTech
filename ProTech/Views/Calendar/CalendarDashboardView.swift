//
//  CalendarDashboardView.swift
//  ProTech
//
//  Main scheduling dashboard with Month/Week/Day views.
//

import SwiftUI
import CoreData

struct CalendarDashboardView: View {
    @State private var selectedDate = Date()
    @State private var viewMode: CalendarViewMode = .month
    @State private var showingNewAppointment = false
    @State private var selectedAppointment: Appointment?
    
    // Filter states
    @State private var selectedTechnicianId: UUID?
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Appointment.scheduledDate, ascending: true)],
        predicate: NSPredicate(format: "status != 'cancelled'")
    ) var appointments: FetchedResults<Appointment>
    
    enum CalendarViewMode: String, CaseIterable, Identifiable {
        case month = "Month"
        case week = "Week"
        case day = "Day"
        case list = "List"
        
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .month: return "calendar"
            case .week: return "calendar.day.timeline.left"
            case .day: return "calendar.day.timeline.leading"
            case .list: return "list.bullet"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header & Controls
                headerView
                
                Divider()
                
                // Main Content
                Group {
                    switch viewMode {
                    case .month:
                        MonthCalendarView(
                            selectedDate: $selectedDate,
                            appointments: Array(appointments),
                            onSelectAppointment: { selectedAppointment = $0 }
                        )
                    case .week:
                        Text("Week View - Coming Soon")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .day:
                        Text("Day View - Coming Soon")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .list:
                        AppointmentListView(
                            appointments: Array(appointments),
                            onSelect: { selectedAppointment = $0 }
                        )
                    }
                }
            }
            .navigationTitle("Schedule")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingNewAppointment = true }) {
                        Label("New Appointment", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewAppointment) {
                // Placeholder for New Appointment View
                Text("New Appointment Form")
            }
            .sheet(item: $selectedAppointment) { appointment in
                // Placeholder for Detail View
                Text("Appointment Detail: \(appointment.scheduledDate?.formatted() ?? "")")
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            // Date Controls
            HStack(spacing: 16) {
                Button(action: { moveDate(by: -1) }) {
                    Image(systemName: "chevron.left")
                }
                
                Text(dateTitle)
                    .font(.headline)
                    .frame(minWidth: 150)
                
                Button(action: { moveDate(by: 1) }) {
                    Image(systemName: "chevron.right")
                }
                
                Button("Today") {
                    selectedDate = Date()
                }
            }
            
            Spacer()
            
            // View Switcher
            Picker("View", selection: $viewMode) {
                ForEach(CalendarViewMode.allCases) { mode in
                    Label(mode.rawValue, systemImage: mode.icon).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 300)
        }
        .padding()
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    private var dateTitle: String {
        let formatter = DateFormatter()
        switch viewMode {
        case .month: formatter.dateFormat = "MMMM yyyy"
        case .week: formatter.dateFormat = "'Week of' MMM d"
        case .day, .list: formatter.dateStyle = .full
        }
        return formatter.string(from: selectedDate)
    }
    
    private func moveDate(by value: Int) {
        let component: Calendar.Component
        switch viewMode {
        case .month: component = .month
        case .week: component = .weekOfYear
        case .day, .list: component = .day
        }
        if let newDate = Calendar.current.date(byAdding: component, value: value, to: selectedDate) {
            selectedDate = newDate
        }
    }
}

// MARK: - Subviews

struct MonthCalendarView: View {
    @Binding var selectedDate: Date
    let appointments: [Appointment]
    let onSelectAppointment: (Appointment) -> Void
    
    private let calendar = Calendar.current
    private let dayFormatter = DateFormatter()
    
    init(selectedDate: Binding<Date>, appointments: [Appointment], onSelectAppointment: @escaping (Appointment) -> Void) {
        self._selectedDate = selectedDate
        self.appointments = appointments
        self.onSelectAppointment = onSelectAppointment
        self.dayFormatter.dateFormat = "d"
    }
    
    var body: some View {
        GeometryReader { geometry in
            let days = daysInMonth()
            let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
            
            VStack(spacing: 0) {
                // Day Headers
                HStack(spacing: 0) {
                    ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.1))
                    }
                }
                
                // Grid
                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(days, id: \.self) { date in
                        if let date = date {
                            DayCell(
                                date: date,
                                isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                isToday: calendar.isDateInToday(date),
                                appointments: appointmentsForDate(date),
                                width: geometry.size.width / 7
                            )
                            .onTapGesture {
                                selectedDate = date
                            }
                        } else {
                            Color.clear
                        }
                    }
                }
            }
        }
    }
    
    private func daysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedDate) else { return [] }
        let monthStart = monthInterval.start
        let monthEnd = monthInterval.end
        
        // Find first weekday
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let offsetDays = firstWeekday - calendar.firstWeekday
        
        var days: [Date?] = Array(repeating: nil, count: offsetDays)
        
        var currentDate = monthStart
        while currentDate < monthEnd {
            days.append(currentDate)
            guard let next = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = next
        }
        
        return days
    }
    
    private func appointmentsForDate(_ date: Date) -> [Appointment] {
        appointments.filter { appointment in
            guard let apptDate = appointment.scheduledDate else { return false }
            return calendar.isDate(apptDate, inSameDayAs: date)
        }
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let appointments: [Appointment]
    let width: CGFloat
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.caption)
                .padding(6)
                .background(isToday ? Color.blue : Color.clear)
                .foregroundColor(isToday ? .white : .primary)
                .clipShape(Circle())
            
            ForEach(appointments.prefix(3)) { appointment in
                Circle()
                    .fill(Color(appointment.statusColor)) // Helper needed or use type
                    .frame(width: 6, height: 6)
            }
            
            Spacer()
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.white)
        .border(Color.gray.opacity(0.2), width: 0.5)
    }
}

struct AppointmentListView: View {
    let appointments: [Appointment]
    let onSelect: (Appointment) -> Void
    
    var body: some View {
        List(appointments) { appointment in
            HStack {
                VStack(alignment: .leading) {
                    Text(appointment.typeDisplayName)
                        .font(.headline)
                    Text(appointment.scheduledDate?.formatted() ?? "No Date")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(appointment.status?.capitalized ?? "")
                    .font(.caption)
                    .padding(4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onSelect(appointment)
            }
        }
    }
}
