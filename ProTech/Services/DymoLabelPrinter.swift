//
//  DymoLabelPrinter.swift
//  ProTech
//
//  DYMO Label Printer Helper - Exact size, no scaling, single page
//  Physical label: 1.1" × 3.5" (≈ 79.2 × 252 pt)
//  Portrait orientation with 90° rotated content
//

import AppKit
import CoreImage

final class DymoLabelPrinter {

    // MARK: - Configuration
    
    // 1. Physical page in points (1.1" x 3.5")
    private static let pageSize = NSSize(width: 72.0 * 1.1, height: 72.0 * 3.5) // 79.2 x 252.0

    // MARK: - Public API
    
    /// Print a DYMO label with product information
    /// - Parameters:
    ///   - name: Product name
    ///   - price: Price string (e.g., "$19.99")
    ///   - subtitle: Product description or subtitle
    ///   - sku: SKU or product code
    ///   - printerName: Optional specific printer name, or nil for default
    static func print(name: String,
                      price: String,
                      subtitle: String,
                      sku: String,
                      printerName: String? = nil) {
        let printInfo = NSPrintInfo.shared.copy() as! NSPrintInfo
        configure(printInfo: printInfo)

        // Set specific printer if provided
        if let printerName = printerName,
           let printer = NSPrinter(name: printerName) {
            printInfo.printer = printer
        } else {
            // Try to find DYMO printer automatically
            if let dymoPrinter = findDymoPrinter() {
                printInfo.printer = dymoPrinter
            }
        }

        // The content view renders inside a 79.2 x 252 pt page and rotates its drawing 90°
        let content = DymoContentView(frame: NSRect(origin: .zero, size: pageSize),
                                      name: name, price: price, subtitle: subtitle, sku: sku)

        let op = NSPrintOperation(view: content, printInfo: printInfo)
        op.showsPrintPanel = true
        op.showsProgressPanel = true
        
        // Run print operation
        if let window = NSApp.keyWindow {
            op.runModal(for: window, delegate: nil, didRun: nil, contextInfo: nil)
        } else {
            op.run()
        }
    }

    /// Generate a preview image of the label
    /// - Parameters:
    ///   - name: Product name
    ///   - price: Price string
    ///   - subtitle: Product description
    ///   - sku: SKU or product code
    /// - Returns: NSImage preview of the label
    static func previewImage(name: String, price: String, subtitle: String, sku: String) -> NSImage {
        let view = DymoContentView(frame: NSRect(origin: .zero, size: pageSize),
                                   name: name, price: price, subtitle: subtitle, sku: sku)
        let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds)!
        view.cacheDisplay(in: view.bounds, to: rep)
        let img = NSImage(size: pageSize)
        img.addRepresentation(rep)
        return img
    }

    // MARK: - Private Configuration
    
    /// Configure print info for exact page size with no scaling
    private static func configure(printInfo: NSPrintInfo) {
        printInfo.orientation = .portrait                           // 79.2 wide, 252 high
        printInfo.paperSize = pageSize
        printInfo.leftMargin = 0
        printInfo.rightMargin = 0
        printInfo.topMargin = 0
        printInfo.bottomMargin = 0
        printInfo.isVerticallyCentered = true
        printInfo.isHorizontallyCentered = true

        // Disable OS scaling; make imageable area = paper size
        printInfo.scalingFactor = 1.0
        printInfo.horizontalPagination = .fit
        printInfo.verticalPagination = .fit
    }
    
    /// Find DYMO printer from available printers
    private static func findDymoPrinter() -> NSPrinter? {
        let printers = NSPrinter.printerNames
        let dymoPatterns = ["dymo", "labelwriter", "label writer", "lw"]
        
        for printerName in printers {
            let nameLowercase = printerName.lowercased()
            for pattern in dymoPatterns {
                if nameLowercase.contains(pattern) {
                    return NSPrinter(name: printerName)
                }
            }
        }
        return nil
    }
}

// MARK: - Content View

/// View that draws rotated content so the long edge prints vertically
final class DymoContentView: NSView {
    private let name: String
    private let price: String
    private let subtitle: String
    private let sku: String

    init(frame: NSRect, name: String, price: String, subtitle: String, sku: String) {
        self.name = name
        self.price = price
        self.subtitle = subtitle
        self.sku = sku
        super.init(frame: frame)
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.white.cgColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.saveGState()

        // Fill background
        NSColor.white.setFill()
        bounds.fill()

        // Rotate content so text reads horizontally along the long edge
        // Translate to bottom-left, then rotate 90° counter-clockwise
        ctx.translateBy(x: 0, y: bounds.height)
        ctx.rotate(by: -.pi / 2)

        // After rotation: drawing area is 252pt wide × 79.2pt tall
        let canvas = CGRect(x: 0, y: 0, width: bounds.height, height: bounds.width)

        // Small margins for clean edges
        let m: CGFloat = 3
        let content = canvas.insetBy(dx: m, dy: m)
        
        // Divide from TOP (maxYEdge after rotation): header 16, title 22, barcode 22, sku rest
        let (skuRect, r1) = content.divided(atDistance: 13, from: .maxYEdge)
        let (barcode, r2) = r1.divided(atDistance: 22, from: .maxYEdge)
        let (title, header) = r2.divided(atDistance: 22, from: .maxYEdge)

        // Header: ProTech • $19.99
        draw(text: "\(name)  •  \(price)",
             in: header, weight: .semibold, baseSize: 12, align: .center, shrinkToFit: true)

        // Title (wrap, always fits)
        draw(text: subtitle,
             in: title, weight: .regular, baseSize: 10, align: .center, shrinkToFit: true, lineBreak: .byWordWrapping)

        // Barcode (Code 128 with quiet zones)
        if let img = code128(from: sku, height: barcode.height - 2, desiredQuietZone: 6) {
            let target = barcode.insetBy(dx: 0, dy: 1)
            img.draw(in: target)
        }

        // SKU line
        draw(text: "SKU: \(sku)",
             in: skuRect, weight: .medium, baseSize: 9, align: .center, shrinkToFit: true)

        ctx.restoreGState()
    }

    // MARK: - Helper Methods

    private func draw(text: String,
                      in rect: CGRect,
                      weight: NSFont.Weight,
                      baseSize: CGFloat,
                      align: NSTextAlignment,
                      shrinkToFit: Bool,
                      lineBreak: NSLineBreakMode = .byTruncatingTail) {
        let para = NSMutableParagraphStyle()
        para.alignment = align
        para.lineBreakMode = lineBreak

        var font = NSFont.systemFont(ofSize: baseSize, weight: weight)

        // Shrink-to-fit if needed
        if shrinkToFit {
            let max = baseSize, min: CGFloat = 7
            var size = max
            while size >= min {
                font = NSFont.systemFont(ofSize: size, weight: weight)
                let w = (text as NSString).boundingRect(
                    with: CGSize(width: rect.width, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: [.font: font, .paragraphStyle: para]
                ).width
                if w <= rect.width { break }
                size -= 0.5
            }
        }

        let attrs: [NSAttributedString.Key: Any] = [
            .font: font, .paragraphStyle: para, .foregroundColor: NSColor.black
        ]
        (text as NSString).draw(with: rect,
                                options: [.usesLineFragmentOrigin, .usesFontLeading],
                                attributes: attrs)
    }

    private func code128(from value: String, height: CGFloat, desiredQuietZone: CGFloat) -> NSImage? {
        guard let f = CIFilter(name: "CICode128BarcodeGenerator") else { return nil }
        f.setValue(value.data(using: .ascii), forKey: "inputMessage")
        f.setValue(0, forKey: "inputQuietSpace")            // we'll add our own quiet zone

        guard let output = f.outputImage else { return nil }
        // Scale to fit width with crisp modules
        let targetWidth: CGFloat = 252 - 8                    // content width minus side margins
        let scaleX = targetWidth / output.extent.width
        let scaled = output.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleX))

        // Pad quiet zones
        let q = desiredQuietZone
        let paddedRect = scaled.extent.insetBy(dx: -q, dy: 0)
        let context = CIContext(options: nil)
        guard let cg = context.createCGImage(scaled, from: paddedRect) else { return nil }
        
        let image = NSImage(size: NSSize(width: paddedRect.width, height: height))
        image.lockFocus()
        NSGraphicsContext.current?.cgContext.interpolationQuality = .none
        NSGraphicsContext.current?.cgContext.draw(cg, in: CGRect(x: 0, y: 0, width: targetWidth, height: height))
        image.unlockFocus()
        return image
    }
}
