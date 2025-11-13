//
//  PortalCheckInView.swift
//  ProTech
//
//  Customer check-in interface within the portal
//

import SwiftUI
import CoreData

struct PortalCheckInView: View {
    let customer: Customer
    
    @Environment(\.managedObjectContext) private var viewContext
    @State private var deviceType = ""
    @State private var deviceModel = ""
    @State private var issueDescription = ""
    @State private var isSubmitting = false
    @State private var showingSuccess = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Check In for Service")
                        .font(.largeTitle)
                        .bold()
                    
                    Text("Please provide your device information and we'll call you shortly")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                // Form
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Device Type")
                            .font(.headline)
                        
                        TextField("e.g., iPhone, iPad, MacBook", text: $deviceType)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Device Model")
                            .font(.headline)
                        
                        TextField("e.g., iPhone 14 Pro, iPad Air", text: $deviceModel)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What's the issue?")
                            .font(.headline)
                        
                        TextField("Describe the problem...", text: $issueDescription, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(4...8)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Submit Button
                Button {
                    checkIn()
                } label: {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Check In Now")
                                .bold()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canSubmit ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .disabled(!canSubmit || isSubmitting)
                .padding(.horizontal)
                
                // Info
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("Your information")
                            .font(.headline)
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Name:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(customer.displayName)
                                .bold()
                        }
                        
                        if let email = customer.email {
                            HStack {
                                Text("Email:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(email)
                                    .bold()
                            }
                        }
                        
                        if let phone = customer.phone {
                            HStack {
                                Text("Phone:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(phone)
                                    .bold()
                            }
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .sheet(isPresented: $showingSuccess) {
            CheckInSuccessView()
        }
    }
    
    private var canSubmit: Bool {
        !deviceType.isEmpty && !issueDescription.isEmpty
    }
    
    private func checkIn() {
        guard let customerId = customer.id else { return }
        
        isSubmitting = true
        
        // Create check-in record
        let checkIn = CheckIn(context: viewContext)
        checkIn.id = UUID()
        checkIn.customerId = customerId
        checkIn.checkedInAt = Date()
        checkIn.deviceType = deviceType
        checkIn.deviceModel = deviceModel.isEmpty ? nil : deviceModel
        checkIn.issueDescription = issueDescription
        checkIn.status = "waiting"
        checkIn.createdAt = Date()
        
        do {
            try viewContext.save()
            
            // Notify staff
            NotificationCenter.default.post(
                name: .customerCheckedIn,
                object: nil,
                userInfo: ["checkInId": checkIn.id as Any]
            )
            
            isSubmitting = false
            showingSuccess = true
            
            // Clear form after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                deviceType = ""
                deviceModel = ""
                issueDescription = ""
            }
        } catch {
            print("Error creating check-in: \(error)")
            isSubmitting = false
        }
    }
}

// MARK: - Success View

struct CheckInSuccessView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(.green)
            
            Text("You're Checked In!")
                .font(.largeTitle)
                .bold()
            
            Text("Please have a seat")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("A team member will call you shortly")
                .font(.body)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Text("Close")
                    .bold()
                    .frame(maxWidth: 200)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }
}

#Preview {
    PortalCheckInView(customer: Customer())
}
