//
//  OnboardingView.swift
//  ProTech
//
//  Setup Wizard for first-time launch.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    
    @State private var currentStep = 0
    @State private var companyName = ""
    @State private var taxRate = "0.0"
    @State private var currencySymbol = "$"
    @State private var logoData: Data?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("ProTech Setup")
                    .font(.headline)
                Spacer()
                Text("Step \(currentStep + 1) of 3")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Content
            VStack {
                switch currentStep {
                case 0:
                    welcomeStep
                case 1:
                    companyDetailsStep
                case 2:
                    brandingStep
                default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .transition(.push(from: .trailing))
            
            Divider()
            
            // Footer
            HStack {
                if currentStep > 0 {
                    Button("Back") {
                        withAnimation { currentStep -= 1 }
                    }
                    .keyboardShortcut(.leftArrow, modifiers: [])
                }
                
                Spacer()
                
                Button(currentStep == 2 ? "Finish" : "Next") {
                    if currentStep < 2 {
                        withAnimation { currentStep += 1 }
                    } else {
                        completeSetup()
                    }
                }
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 600, height: 500)
    }
    
    // MARK: - Steps
    
    var welcomeStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "desktopcomputer")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Welcome to ProTech!")
                .font(.largeTitle)
                .bold()
            
            Text("Let's get your repair shop set up in just a few minutes.")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    var companyDetailsStep: some View {
        Form {
            Section("Company Information") {
                TextField("Shop Name", text: $companyName)
                TextField("Tax Rate (%)", text: $taxRate)
                TextField("Currency Symbol", text: $currencySymbol)
            }
            
            Section("Preferences") {
                Text("These can be changed later in Settings.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    var brandingStep: some View {
        VStack(spacing: 20) {
            Text("Add Your Logo")
                .font(.title2)
            
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 200, height: 200)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [10]))
                            .foregroundColor(.gray)
                    )
                
                if let data = logoData, let nsImage = NSImage(data: data) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 180)
                } else {
                    VStack {
                        Image(systemName: "photo.badge.plus")
                            .font(.largeTitle)
                        Text("Drag & Drop or Click")
                    }
                    .foregroundColor(.secondary)
                }
            }
            .onTapGesture {
                selectLogo()
            }
            
            Text("This will appear on invoices and estimates.")
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Methods
    
    func selectLogo() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.image]
        
        if panel.runModal() == .OK {
            if let url = panel.url, let data = try? Data(contentsOf: url) {
                logoData = data
            }
        }
    }
    
    func completeSetup() {
        // Save preferences
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.set(companyName, forKey: "companyName")
        UserDefaults.standard.set(taxRate, forKey: "taxRate")
        
        // Dismiss
        isPresented = false
        
        // Show success notification
        NotificationManager.shared.post(title: "Setup Complete", message: "Welcome to ProTech!", type: .success)
    }
}
