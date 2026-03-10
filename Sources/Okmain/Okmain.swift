import CoreGraphics
import CoreImage
import Foundation

public enum Okmain {
    public static func palette(
        in image: CIImage,
        options: Options = .default,
        context: CIContext = sharedContext
    ) throws -> Palette {
        try options.validate()
        let raster = try RasterImage.make(from: image, context: context)
        return try analyze(raster: raster, options: options)
    }

    public static func palette(
        in image: CGImage,
        options: Options = .default,
        context: CIContext = sharedContext
    ) throws -> Palette {
        try palette(in: CIImage(cgImage: image), options: options, context: context)
    }

    public static func colors(
        in image: CIImage,
        options: Options = .default,
        context: CIContext = sharedContext
    ) throws -> [OkmainColor] {
        try palette(in: image, options: options, context: context).colors
    }

    public static func colors(
        in image: CGImage,
        options: Options = .default,
        context: CIContext = sharedContext
    ) throws -> [OkmainColor] {
        try palette(in: image, options: options, context: context).colors
    }

    private static func analyze(raster: RasterImage, options: Options) throws -> Palette {
        let sample = try SampledOklabGrid(from: raster)
        let clustering = KMeans.findCentroids(in: sample, maxCentroids: options.maximumColorCount)
        return Palette.build(sample: sample, clustering: clustering, options: options)
    }

    public static let sharedContext: CIContext = {
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        return CIContext(options: [
            .cacheIntermediates: false,
            .workingColorSpace: colorSpace,
            .outputColorSpace: colorSpace,
            .priorityRequestLow: false,
        ])
    }()
}

public extension CIImage {
    func okmainPalette(
        options: Okmain.Options = .default,
        context: CIContext = Okmain.sharedContext
    ) throws -> Okmain.Palette {
        try Okmain.palette(in: self, options: options, context: context)
    }

    func okmainColors(
        options: Okmain.Options = .default,
        context: CIContext = Okmain.sharedContext
    ) throws -> [OkmainColor] {
        try Okmain.colors(in: self, options: options, context: context)
    }
}

public extension CGImage {
    func okmainPalette(
        options: Okmain.Options = .default,
        context: CIContext = Okmain.sharedContext
    ) throws -> Okmain.Palette {
        try Okmain.palette(in: self, options: options, context: context)
    }

    func okmainColors(
        options: Okmain.Options = .default,
        context: CIContext = Okmain.sharedContext
    ) throws -> [OkmainColor] {
        try Okmain.colors(in: self, options: options, context: context)
    }
}
