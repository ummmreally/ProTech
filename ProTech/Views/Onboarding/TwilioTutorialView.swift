//
//  TwilioTutorialView.swift
//  ProTech
//
//  Step-by-step Twilio setup tutorial
//

import SwiftUI

struct TwilioTutorialView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep: Int = 0
    
    private let steps: [TutorialStep] = [
        TutorialStep(
            title: "What is Twilio?",
            description: "Twilio is a service that lets you send SMS messages to your customers. You'll need your own Twilio account to use this feature.",
            icon: "message.circle.fill",
            action: nil
        ),
        TutorialStep(
            title: "Create Twilio Account",
            description: "Sign up for a free Twilio account at twilio.com. You'll get $15 free credit to start—enough for about 1,900 SMS messages!",
            icon: "person.crop.circle.badge.plus",
            action: URL(string: "https://www.twilio.com/try-twilio")
        ),
        TutorialStep(
            title: "Get a Phone Number",
            description: "In Twilio Console, buy a phone number ($1-2/month). This is the number your SMS messages will come from. Choose a local number in your area code for better customer trust.",
            icon: "phone.circle.fill",
            action: URL(string: "https://console.twilio.com/us1/develop/phone-numbers/manage/search")
        ),
        TutorialStep(
            title: "Copy Your Credentials",
            description: "From the Twilio Dashboard, copy your Account SID and Auth Token. Keep these secret—they're like your password!",
            icon: "key.fill",
            action: URL(string: "https://console.twilio.com")
        ),
        TutorialStep(
            title: "Enter in Settings",
            description: "Go to ProTech Settings → SMS tab, paste your credentials, and test the connection. You're all set!",
            icon: "gearshape.fill",
            action: nil
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<steps.count, id: \.self) { index in
                    Circle()
                        .fill(index <= currentStep ? Color.orange : Color.gray.opacity(0.3))
                        .frame(width: 10, height: 10)
                }
            }
            .padding()
            
            // Current step
            VStack(spacing: 24) {
                Image(systemName: steps[currentStep].icon)
                    .font(.system(size: 70))
                    .foregroundColor(.orange)
                    .symbolRenderingMode(.hierarchical)
                
                Text(steps[currentStep].title)
                    .font(.title)
                    .bold()
                    .multilineTextAlignment(.center)
                
                Text(steps[currentStep].description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 50)
                    .fixedSize(horizontal: false, vertical: true)
                
                if let action = steps[currentStep].action {
                    Link(destination: action) {
                        HStack {
                            Text("Open in Browser")
                            Image(systemName: "arrow.up.forward.app")
                        }
                        .font(.body)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            
            Divider()
            
            // Navigation buttons
            HStack {
                if currentStep > 0 {
                    Button {
                        withAnimation {
                            currentStep -= 1
                        }
                    } label: {
                        Label("Back", systemImage: "chevron.left")
                    }
                }
                
                Spacer()
                
                if currentStep < steps.count - 1 {
                    Button {
                        withAnimation {
                            currentStep += 1
                        }
                    } label: {
                        HStack {
                            Text("Next")
                            Image(systemName: "chevron.right")
                        }
                    }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                } else {
                    Button {
                        dismiss()
                        // Open SMS settings
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            NotificationCenter.default.post(name: .openTwilioSettings, object: nil)
                        }
                    } label: {
                        Label("Open Settings", systemImage: "checkmark")
                    }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .frame(width: 650, height: 550)
    }
}

struct TutorialStep {
    let title: String
    let description: String
    let icon: String
    let action: URL?
}

