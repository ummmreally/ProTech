//
//  CustomerDetailView.swift
//  ProTech
//
//  Customer detail view with edit and actions
//

import SwiftUI

struct CustomerDetailView: View {
    @ObservedObject var customer: Customer
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var isEditing = false
    @State private var showingSMSComposer = false
    @State private var showingUpgrade = false
    @State private var isTwilioConfigured = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with avatar
                HStack(spacing: 16) {
                    Circle()
                        .fill(Color.blue.gradient)
                        .frame(width: 80, height: 80)
                        .overlay {
                            Text(initials)
                                .font(.largeTitle)
                                .foregroundColor(.white)
                        }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(customer.firstName ?? "") \(customer.lastName ?? "")")
                            .font(.title)
                            .bold()
                        if let createdAt = customer.createdAt {
                            Text("Customer since \(createdAt, format: .dateTime.month().day().year())")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                
                // Contact Information
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        if let phone = customer.phone {
                            HStack {
                                Label(phone, systemImage: "phone.fill")
                                Spacer()
                                if subscriptionManager.isProSubscriber && isTwilioConfigured {
                                    Button {
                                        showingSMSComposer = true
                                    } label: {
                                        Image(systemName: "message.fill")
                                    }
                                }
                            }
                        }
                        
                        if let email = customer.email {
                            Label(email, systemImage: "envelope.fill")
                        }
                        
                        if let address = customer.address {
                            Label {
                                Text(address)
                            } icon: {
                                Image(systemName: "mappin.circle.fill")
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } label: {
                    Text("Contact Information")
                        .font(.headline)
                }
                .padding(.horizontal)
                
                // Notes
                if let notes = customer.notes, !notes.isEmpty {
                    GroupBox {
                        Text(notes)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } label: {
                        Text("Notes")
                            .font(.headline)
                    }
                    .padding(.horizontal)
                }
                
                // Actions
                GroupBox {
                    VStack(spacing: 8) {
                        ActionButton(title: "Edit Customer", icon: "pencil") {
                            isEditing = true
                        }
                        
                        if subscriptionManager.isProSubscriber {
                            ActionButton(title: "Create Intake Form", icon: "doc.text") {
                                // Navigate to forms
                            }
                            
                            ActionButton(title: "Send SMS", icon: "message") {
                                if isTwilioConfigured {
                                    showingSMSComposer = true
                                } else {
                                    // Show Twilio setup
                                    NotificationCenter.default.post(name: .openTwilioTutorial, object: nil)
                                }
                            }
                        } else {
                            ActionButton(title: "Upgrade for SMS & Forms", icon: "star.fill") {
                                showingUpgrade = true
                            }
                            .foregroundColor(.orange)
                        }
                    }
                } label: {
                    Text("Actions")
                        .font(.headline)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top)
        }
        .navigationTitle("Customer Details")
        .sheet(isPresented: $isEditing) {
            EditCustomerView(customer: customer)
        }
        .sheet(isPresented: $showingSMSComposer) {
            SMSComposerView(customer: customer)
        }
        .sheet(isPresented: $showingUpgrade) {
            SubscriptionView()
                .frame(width: 600, height: 700)
        }
        .task {
            // Cache the Twilio configuration lookup so the view body
            // isn't repeatedly hitting the Keychain on every render.
            isTwilioConfigured = TwilioService.shared.isConfigured
        }
    }
    
    private var initials: String {
        let first = customer.firstName?.prefix(1).uppercased() ?? ""
        let last = customer.lastName?.prefix(1).uppercased() ?? ""
        return first + last
    }
}

// MARK: - Action Button

struct ActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 24)
                Text(title)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}
