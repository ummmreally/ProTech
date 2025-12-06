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
            VStack(spacing: AppTheme.Spacing.xxl) {
                // Header with gradient
                VStack(spacing: AppTheme.Spacing.lg) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.Colors.portalWelcome)
                            .frame(width: 80, height: 80)
                            .shadow(color: Color(hex: "a855f7").opacity(0.3), radius: 12, x: 0, y: 6)
                        
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.white)
                    }
                    
                    Text("Check In for Service")
                        .font(.system(.largeTitle, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.Colors.portalWelcome)
                    
                    Text("Fill in your details and we'll call you shortly")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Form Card
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("Device Type")
                            .font(AppTheme.Typography.headline)
                        
                        TextField("e.g., iPhone, iPad, MacBook", text: $deviceType)
                            .textFieldStyle(.plain)
                            .padding(AppTheme.Spacing.lg)
                            .background(Color(hex: "f9fafb"))
                            .cornerRadius(AppTheme.cardCornerRadius)
                    }
                    
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("Device Model")
                            .font(AppTheme.Typography.headline)
                        
                        TextField("e.g., iPhone 14 Pro, iPad Air", text: $deviceModel)
                            .textFieldStyle(.plain)
                            .padding(AppTheme.Spacing.lg)
                            .background(Color(hex: "f9fafb"))
                            .cornerRadius(AppTheme.cardCornerRadius)
                    }
                    
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("What's the issue?")
                            .font(AppTheme.Typography.headline)
                        
                        TextField("Describe the problem...", text: $issueDescription, axis: .vertical)
                            .textFieldStyle(.plain)
                            .lineLimit(4...8)
                            .padding(AppTheme.Spacing.lg)
                            .background(Color(hex: "f9fafb"))
                            .cornerRadius(AppTheme.cardCornerRadius)
                    }
                }
                .padding(AppTheme.Spacing.xxl)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
                )
                .padding(.horizontal)
                
                // Submit Button
                Button {
                    checkIn()
                } label: {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        if isSubmitting {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                            Text("Check In Now")
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(
                        canSubmit ? AppTheme.Colors.portalSuccess : LinearGradient(
                            colors: [Color.gray.opacity(0.6), Color.gray.opacity(0.4)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(AppTheme.cardCornerRadius)
                    .shadow(color: canSubmit ? Color(hex: "10b981").opacity(0.3) : Color.clear, radius: 12, x: 0, y: 6)
                }
                .buttonStyle(.plain)
                .disabled(!canSubmit || isSubmitting)
                .padding(.horizontal)
                
                // Info Card
                VStack(spacing: AppTheme.Spacing.md) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "person.circle.fill")
                            .font(.title3)
                            .foregroundStyle(AppTheme.Colors.portalWelcome)
                        Text("Your Information")
                            .font(AppTheme.Typography.headline)
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        HStack {
                            Text("Name:")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(customer.displayName)
                                .font(AppTheme.Typography.subheadline)
                                .fontWeight(.semibold)
                        }
                        
                        if let email = customer.email {
                            HStack {
                                Text("Email:")
                                    .font(AppTheme.Typography.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(email)
                                    .font(AppTheme.Typography.subheadline)
                                    .fontWeight(.semibold)
                            }
                        }
                        
                        if let phone = customer.phone {
                            HStack {
                                Text("Phone:")
                                    .font(AppTheme.Typography.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(phone)
                                    .font(AppTheme.Typography.subheadline)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
                .padding(AppTheme.Spacing.xxl)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
                )
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
        VStack(spacing: AppTheme.Spacing.xxl) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.portalSuccess)
                    .frame(width: 120, height: 120)
                    .shadow(color: Color(hex: "10b981").opacity(0.3), radius: 20, x: 0, y: 10)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: AppTheme.Spacing.md) {
                Text("You're Checked In!")
                    .font(.system(.largeTitle, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.Colors.portalSuccess)
                
                Text("Please have a seat")
                    .font(AppTheme.Typography.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("A team member will call you shortly")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Text("Close")
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.semibold)
                    .frame(maxWidth: 300)
                    .padding(20)
                    .background(AppTheme.Colors.portalWelcome)
                    .foregroundColor(.white)
                    .cornerRadius(AppTheme.cardCornerRadius)
                    .shadow(color: Color(hex: "a855f7").opacity(0.3), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(.plain)
        }
        .padding(AppTheme.Spacing.xxl)
        .frame(minWidth: 500, minHeight: 400)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color(hex: "f8f9fa"),
                    Color(hex: "e9ecef")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

#Preview {
    PortalCheckInView(customer: Customer())
}
