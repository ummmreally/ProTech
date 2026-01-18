//
//  PortalBookingView.swift
//  ProTech
//
//  Customer-facing view for booking new appointments.
//

import SwiftUI

struct PortalBookingView: View {
    let customer: Customer
    @Environment(\.dismiss) private var dismiss
    @StateObject private var portalService = CustomerPortalService.shared
    
    @State private var selectedDate = Date()
    @State private var selectedServiceType: ServiceType = .repair
    @State private var selectedSlot: Date?
    @State private var availableSlots: [Date] = []
    @State private var showingConfirmation = false
    @State private var bookingNote = ""
    @State private var isLoadingSlots = false
    
    enum ServiceType: String, CaseIterable, Identifiable {
        case repair = "Device Repair"
        case consultation = "Consultation"
        case pickup = "Device Pickup"
        
        var id: String { rawValue }
        
        var duration: TimeInterval {
            switch self {
            case .repair: return 3600 // 1 hour
            case .consultation: return 1800 // 30 mins
            case .pickup: return 900 // 15 mins
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Service Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What do you need help with?")
                            .font(.headline)
                        
                        Picker("Service Type", selection: $selectedServiceType) {
                            ForEach(ServiceType.allCases) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding()
                    .background(AppTheme.Colors.cardBackground)
                    .cornerRadius(12)
                    
                    // Date Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Select a Date")
                            .font(.headline)
                        
                        DatePicker(
                            "Date",
                            selection: $selectedDate,
                            in: Date()...,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .onChange(of: selectedDate) {
                            loadSlots()
                        }
                    }
                    .padding()
                    .background(AppTheme.Colors.cardBackground)
                    .cornerRadius(12)
                    
                    // Time Slots
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Available Times")
                            .font(.headline)
                        
                        if isLoadingSlots {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else if availableSlots.isEmpty {
                            Text("No slots available for this date.")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                                ForEach(availableSlots, id: \.self) { slot in
                                    Button {
                                        selectedSlot = slot
                                    } label: {
                                        Text(formatTime(slot))
                                            .font(.subheadline)
                                            .fontWeight(selectedSlot == slot ? .semibold : .regular)
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 12)
                                            .frame(maxWidth: .infinity)
                                            .background(selectedSlot == slot ? AppTheme.Colors.primary : AppTheme.Colors.groupedBackground)
                                            .foregroundColor(selectedSlot == slot ? .white : .primary)
                                            .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(AppTheme.Colors.cardBackground)
                    .cornerRadius(12)
                    
                    // Notes
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Notes (Optional)")
                            .font(.headline)
                        
                        TextField("Describe your issue or request...", text: $bookingNote, axis: .vertical)
                            .lineLimit(3...5)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding()
                    .background(AppTheme.Colors.cardBackground)
                    .cornerRadius(12)
                    
                }
                .padding()
            }
            
            // Bottom Action Bar
            VStack {
                Divider()
                Button {
                    bookAppointment()
                } label: {
                    Text("Confirm Booking")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canBook ? AppTheme.Colors.primary : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(!canBook)
                .padding()
            }
            .background(AppTheme.Colors.cardBackground)
        }
        .navigationTitle("Book Appointment")
        .task {
            loadSlots()
        }
        .alert("Booking Confirmed", isPresented: $showingConfirmation) {
            Button("Done") {
                dismiss()
            }
        } message: {
            Text("Your appointment has been scheduled. We look forward to seeing you!")
        }
    }
    
    private var canBook: Bool {
        selectedSlot != nil
    }
    
    private func loadSlots() {
        isLoadingSlots = true
        selectedSlot = nil // Reset selection on date change
        
        Task {
            // Simulate network delay
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            let slots = await portalService.getAvailableSlots(for: selectedDate)
            
            await MainActor.run {
                self.availableSlots = slots
                self.isLoadingSlots = false
            }
        }
    }
    
    private func bookAppointment() {
        guard let slot = selectedSlot else { return }
        
        Task {
            do {
                try await portalService.bookAppointment(
                    customer: customer,
                    date: slot,
                    serviceType: selectedServiceType.rawValue,
                    duration: selectedServiceType.duration,
                    notes: bookingNote
                )
                
                await MainActor.run {
                    showingConfirmation = true
                }
            } catch {
                print("Booking failed: \(error)")
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
