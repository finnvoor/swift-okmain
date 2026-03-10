import CoreGraphics
import CoreImage
import Foundation

#if canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

#if canImport(SwiftUI)
import SwiftUI
#endif

#if canImport(AppKit)
public extension Okmain {
    @MainActor
    static func palette(
        in image: NSImage,
        options: Options = .default,
        context: CIContext = sharedContext
    ) throws -> Palette {
        if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            return try palette(in: cgImage, options: options, context: context)
        }
        guard let data = image.tiffRepresentation, let ciImage = CIImage(data: data) else {
            throw OkmainError.unableToCreateCGImage
        }
        return try palette(in: ciImage, options: options, context: context)
    }

    @MainActor
    static func colors(
        in image: NSImage,
        options: Options = .default,
        context: CIContext = sharedContext
    ) throws -> [OkmainColor] {
        try palette(in: image, options: options, context: context).colors
    }
}

public extension NSImage {
    @MainActor
    func okmainPalette(
        options: Okmain.Options = .default,
        context: CIContext = Okmain.sharedContext
    ) throws -> Okmain.Palette {
        try Okmain.palette(in: self, options: options, context: context)
    }

    @MainActor
    func okmainColors(
        options: Okmain.Options = .default,
        context: CIContext = Okmain.sharedContext
    ) throws -> [OkmainColor] {
        try Okmain.colors(in: self, options: options, context: context)
    }
}
#endif

#if canImport(UIKit)
public extension Okmain {
    @MainActor
    static func palette(
        in image: UIImage,
        options: Options = .default,
        context: CIContext = sharedContext
    ) throws -> Palette {
        if let ciImage = image.ciImage {
            return try palette(in: ciImage.oriented(forExifOrientation: Int32(image.imageOrientation.exifOrientation)), options: options, context: context)
        }
        guard let cgImage = image.cgImage else {
            throw OkmainError.unableToCreateCGImage
        }
        let ciImage = CIImage(cgImage: cgImage).oriented(forExifOrientation: Int32(image.imageOrientation.exifOrientation))
        return try palette(in: ciImage, options: options, context: context)
    }

    @MainActor
    static func colors(
        in image: UIImage,
        options: Options = .default,
        context: CIContext = sharedContext
    ) throws -> [OkmainColor] {
        try palette(in: image, options: options, context: context).colors
    }
}

public extension UIImage {
    @MainActor
    func okmainPalette(
        options: Okmain.Options = .default,
        context: CIContext = Okmain.sharedContext
    ) throws -> Okmain.Palette {
        try Okmain.palette(in: self, options: options, context: context)
    }

    @MainActor
    func okmainColors(
        options: Okmain.Options = .default,
        context: CIContext = Okmain.sharedContext
    ) throws -> [OkmainColor] {
        try Okmain.colors(in: self, options: options, context: context)
    }
}

private extension UIImage.Orientation {
    var exifOrientation: UInt32 {
        switch self {
        case .up: 1
        case .down: 3
        case .left: 8
        case .right: 6
        case .upMirrored: 2
        case .downMirrored: 4
        case .leftMirrored: 5
        case .rightMirrored: 7
        @unknown default: 1
        }
    }
}
#endif

#if canImport(SwiftUI)
public extension Okmain {
    @MainActor
    static func palette(
        in image: Image,
        proposedSize: CGSize? = nil,
        scale: CGFloat = 1,
        options: Options = .default,
        context: CIContext = sharedContext
    ) throws -> Palette {
        let renderer = ImageRenderer(content: image)
        renderer.scale = scale
        if let proposedSize {
            renderer.proposedSize = ProposedViewSize(proposedSize)
        }

        #if canImport(AppKit)
        guard let nsImage = renderer.nsImage else {
            throw OkmainError.unableToRenderSwiftUIImage
        }
        return try palette(in: nsImage, options: options, context: context)
        #elseif canImport(UIKit)
        guard let uiImage = renderer.uiImage else {
            throw OkmainError.unableToRenderSwiftUIImage
        }
        return try palette(in: uiImage, options: options, context: context)
        #else
        throw OkmainError.unableToRenderSwiftUIImage
        #endif
    }
}

public extension Image {
    @MainActor
    func okmainPalette(
        proposedSize: CGSize? = nil,
        scale: CGFloat = 1,
        options: Okmain.Options = .default,
        context: CIContext = Okmain.sharedContext
    ) throws -> Okmain.Palette {
        try Okmain.palette(
            in: self,
            proposedSize: proposedSize,
            scale: scale,
            options: options,
            context: context
        )
    }
}
#endif
