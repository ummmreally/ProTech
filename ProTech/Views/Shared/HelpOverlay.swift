//
//  HelpOverlay.swift
//  ProTech
//
//  Guided tour overlay for onboarding.
//

import SwiftUI

struct HelpStep: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let description: String
    let targetFrame: CGRect? // Creating a more robust targeting system is complex, simplifying to center/general for now or using GeometryReader anchor prefs later if needed.
    // simpler approach: Just a modal series for v1
}

struct HelpOverlay: View {
    @Binding var isPresented: Bool
    let steps: [HelpStep]
    
    @State private var currentStepIndex = 0
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    // Optional: isPresented = false
                }
            
            // Step Card
            if currentStepIndex < steps.count {
                let step = steps[currentStepIndex]
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(step.title)
                            .font(.headline)
                        Spacer()
                        Button {
                            isPresented = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Text(step.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("\(currentStepIndex + 1) of \(steps.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if currentStepIndex > 0 {
                            Button("Previous") {
                                withAnimation {
                                    currentStepIndex -= 1
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        Button(currentStepIndex == steps.count - 1 ? "Finish" : "Next") {
                            withAnimation {
                                if currentStepIndex < steps.count - 1 {
                                    currentStepIndex += 1
                                } else {
                                    isPresented = false
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.top, 10)
                }
                .padding()
                .frame(width: 350)
                .background(Color(NSColor.windowBackgroundColor))
                .cornerRadius(12)
                .shadow(radius: 20)
                // In a real implementation we would position this based on `step.targetFrame`
                // For now, center it.
            }
        }
    }
}
