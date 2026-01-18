//
//  SignaturePadView.swift
//  ProTech
//
//  Reusable component for capturing signatures.
//

import SwiftUI
import AppKit

struct SignaturePadView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var signatureData: Data?
    
    @State private var currentPath = Path()
    @State private var paths: [Path] = []
    
    var body: some View {
        NavigationStack {
            VStack {
                ZStack {
                    Color.white
                        .cornerRadius(8)
                        .shadow(radius: 2)
                    
                    Canvas { context, size in
                        for path in paths {
                            context.stroke(path, with: .color(.black), lineWidth: 2)
                        }
                        context.stroke(currentPath, with: .color(.black), lineWidth: 2)
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let point = value.location
                                if currentPath.isEmpty {
                                    currentPath.move(to: point)
                                } else {
                                    currentPath.addLine(to: point)
                                }
                            }
                            .onEnded { _ in
                                paths.append(currentPath)
                                currentPath = Path()
                            }
                    )
                }
                .frame(height: 150)
                .padding()
                .background(Color.gray.opacity(0.1))
                
                HStack {
                    Button("Clear") {
                        paths.removeAll()
                        currentPath = Path()
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Done") {
                        saveSignature()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(paths.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Signature")
        }
        .frame(width: 500, height: 400)
    }
    
    private func saveSignature() {
        let size = CGSize(width: 400, height: 150)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        // White background
        NSColor.white.setFill()
        NSRect(origin: .zero, size: size).fill()
        
        // Save graphics state
        let context = NSGraphicsContext.current?.cgContext
        context?.saveGState()
        
        // Flip coordinate system to match SwiftUI's top-left origin
        context?.translateBy(x: 0, y: size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        // Draw paths
        NSColor.black.setStroke()
        for path in paths {
            let nsPath = NSBezierPath()
            var isFirst = true
            
            // Convert SwiftUI Path to NSBezierPath roughly
            // Since SwiftUI Path element iteration is tricky without explicit access,
            // we will reconstruct it from the stored paths if possible, but actually 
            // the above implementation in FormFillView was relying on a Path extension or similar?
            // Wait, the FormFillView implementation had `path.forEach { element in ... }`.
            // SwiftUI's Path conforms to Sequence where Element is Path.Element.
            
            path.forEach { element in
                switch element {
                case .move(to: let point):
                    nsPath.move(to: point)
                case .line(to: let point):
                    if isFirst {
                        nsPath.move(to: point)
                        isFirst = false
                    } else {
                        nsPath.line(to: point)
                    }
                default:
                    break
                }
            }
            nsPath.lineWidth = 2
            nsPath.stroke()
        }
        
        // Restore graphics state
        context?.restoreGState()
        
        image.unlockFocus()
        
        signatureData = image.tiffRepresentation
    }
}
