//
//  Color+Hex.swift
//  ProTech
//
//  Shared utilities for converting between Color and hex strings
//

import SwiftUI

#if canImport(AppKit)
import AppKit
typealias PlatformColor = NSColor
#elseif canImport(UIKit)
import UIKit
typealias PlatformColor = UIColor
#endif

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 122, 255)
        }

        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }

    func toHex(includeAlpha: Bool = false) -> String {
#if canImport(AppKit) || canImport(UIKit)
        let platformColor = PlatformColor(self)
#if canImport(AppKit)
        guard let converted = platformColor.usingColorSpace(.sRGB) else {
            return "000000"
        }
        let red = converted.redComponent
        let green = converted.greenComponent
        let blue = converted.blueComponent
        let alpha = converted.alphaComponent
#else
        guard let components = platformColor.cgColor.converted(to: CGColorSpace(name: CGColorSpace.sRGB)!,
                                                               intent: .defaultIntent,
                                                               options: nil)?.components else {
            return "000000"
        }
        let red = components[0]
        let green = components[1]
        let blue = components[2]
        let alpha = components.count >= 4 ? components[3] : 1
#endif

        let r = Int(round(red * 255))
        let g = Int(round(green * 255))
        let b = Int(round(blue * 255))
        let a = Int(round(alpha * 255))

        if includeAlpha {
            return String(format: "%02X%02X%02X%02X", r, g, b, a)
        }
        return String(format: "%02X%02X%02X", r, g, b)
#else
        return "000000"
#endif
    }
}
