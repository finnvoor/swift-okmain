import CoreGraphics
import CoreImage
import Foundation

#if canImport(SwiftUI)
import SwiftUI
#endif

#if canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

public struct OkmainColor: Hashable, Sendable, Codable {
    public var red: UInt8
    public var green: UInt8
    public var blue: UInt8
    public var alpha: UInt8

    public init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8 = 255) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    internal init(rgb: RGB8) {
        self.init(red: rgb.red, green: rgb.green, blue: rgb.blue)
    }

    public var cgColor: CGColor {
        CGColor(
            colorSpace: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
            components: [
                CGFloat(red) / 255,
                CGFloat(green) / 255,
                CGFloat(blue) / 255,
                CGFloat(alpha) / 255,
            ]
        ) ?? CGColor(gray: 0, alpha: 1)
    }

    public var ciColor: CIColor {
        CIColor(cgColor: cgColor)
    }

    #if canImport(AppKit)
    public var nsColor: NSColor {
        NSColor(cgColor: cgColor) ?? NSColor(calibratedRed: CGFloat(red) / 255, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255, alpha: CGFloat(alpha) / 255)
    }
    #endif

    #if canImport(UIKit)
    public var uiColor: UIColor {
        UIColor(red: CGFloat(red) / 255, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255, alpha: CGFloat(alpha) / 255)
    }
    #endif

    #if canImport(SwiftUI)
    public var swiftUIColor: Color {
        Color(cgColor: cgColor)
    }
    #endif
}
