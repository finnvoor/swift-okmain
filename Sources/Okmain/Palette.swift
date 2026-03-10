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

extension Okmain {
    public struct Palette: Sendable, Hashable {
        public struct Swatch: Sendable, Hashable {
            public var color: OkmainColor
            public var score: Float
            public var chroma: Float
            public var weightedCoverage: Float

            public init(color: OkmainColor, score: Float, chroma: Float, weightedCoverage: Float) {
                self.color = color
                self.score = score
                self.chroma = chroma
                self.weightedCoverage = weightedCoverage
            }
        }

        public var swatches: [Swatch]

        public init(swatches: [Swatch]) {
            self.swatches = swatches
        }

        public var dominant: Swatch? { swatches.first }
        public var colors: [OkmainColor] { swatches.map(\.color) }

        public func swatchStripCGImage(
            swatchSize: CGSize = CGSize(width: 64, height: 64)
        ) throws -> CGImage {
            let width = Int(max(swatchSize.width, 1)) * max(swatches.count, 1)
            let height = Int(max(swatchSize.height, 1))
            let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
            guard let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else {
                throw OkmainError.unableToCreateBitmapContext
            }

            for (index, swatch) in swatches.enumerated() {
                context.setFillColor(swatch.color.cgColor)
                let rect = CGRect(
                    x: index * Int(swatchSize.width),
                    y: 0,
                    width: Int(swatchSize.width),
                    height: height
                )
                context.fill(rect)
            }

            guard let image = context.makeImage() else {
                throw OkmainError.unableToCreateCGImage
            }
            return image
        }

        public func swatchStripCIImage(
            swatchSize: CGSize = CGSize(width: 64, height: 64)
        ) throws -> CIImage {
            CIImage(cgImage: try swatchStripCGImage(swatchSize: swatchSize))
        }

        #if canImport(AppKit)
        public func swatchStripNSImage(
            swatchSize: CGSize = CGSize(width: 64, height: 64)
        ) throws -> NSImage {
            let cgImage = try swatchStripCGImage(swatchSize: swatchSize)
            return NSImage(cgImage: cgImage, size: swatchSize)
        }
        #endif

        #if canImport(UIKit)
        public func swatchStripUIImage(
            swatchSize: CGSize = CGSize(width: 64, height: 64)
        ) throws -> UIImage {
            UIImage(cgImage: try swatchStripCGImage(swatchSize: swatchSize))
        }
        #endif

        #if canImport(SwiftUI)
        public func swatchStripImage(
            swatchSize: CGSize = CGSize(width: 64, height: 64)
        ) throws -> Image {
            #if canImport(AppKit)
            return Image(nsImage: try swatchStripNSImage(swatchSize: swatchSize))
            #elseif canImport(UIKit)
            return Image(uiImage: try swatchStripUIImage(swatchSize: swatchSize))
            #else
            return Image(decorative: try swatchStripCGImage(swatchSize: swatchSize), scale: 1)
            #endif
        }
        #endif
    }
}
