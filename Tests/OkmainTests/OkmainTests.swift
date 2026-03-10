import CoreGraphics
import Foundation
import Testing
@testable import Okmain

@Test func singlePixelRoundTrips() throws {
    let image = try makeImage(width: 1, height: 1, rgb: [128, 64, 32])
    let colors = try Okmain.colors(in: image)

    #expect(colors.count == 1)
    #expect(abs(Int(colors[0].red) - 128) <= 1)
    #expect(abs(Int(colors[0].green) - 64) <= 1)
    #expect(abs(Int(colors[0].blue) - 32) <= 1)
}

@Test func uniformImageProducesSingleColor() throws {
    let image = try makeImage(width: 10, height: 10, rgb: Array(repeating: [200, 100, 50], count: 100).flatMap { $0 })
    let colors = try Okmain.colors(in: image)

    #expect(colors.count == 1)
    #expect(abs(Int(colors[0].red) - 200) <= 1)
    #expect(abs(Int(colors[0].green) - 100) <= 1)
    #expect(abs(Int(colors[0].blue) - 50) <= 1)
}

@Test func dominantColorRanksFirst() throws {
    let width = 20
    let height = 20
    var rgb = [UInt8]()
    rgb.reserveCapacity(width * height * 3)

    for y in 0..<height {
        for x in 0..<width {
            if (2..<18).contains(x) && (2..<18).contains(y) {
                rgb += [255, 0, 0]
            } else {
                rgb += [40, 40, 40]
            }
        }
    }

    let image = try makeImage(width: width, height: height, rgb: rgb)
    let palette = try Okmain.palette(in: image)

    #expect(palette.swatches.count >= 1)
    #expect(palette.swatches[0].color.red > 150)
    #expect(palette.swatches[0].color.green < 80)
}

@Test func deterministicAcrossCalls() throws {
    let image = try makeImage(width: 3, height: 1, rgb: [255, 0, 0, 0, 255, 0, 0, 0, 255])
    let first = try Okmain.colors(in: image)
    let second = try Okmain.colors(in: image)
    #expect(first == second)
}

@Test func invalidWeightsThrow() throws {
    let image = try makeImage(width: 1, height: 1, rgb: [255, 0, 0])
    #expect(throws: OkmainError.self) {
        _ = try Okmain.colors(
            in: image,
            options: .init(weightedCountsWeight: 0.4, chromaWeight: 0.4)
        )
    }
}

@Test func swatchStripRenders() throws {
    let palette = Okmain.Palette(swatches: [
        .init(color: .init(red: 255, green: 0, blue: 0), score: 1, chroma: 1, weightedCoverage: 1),
        .init(color: .init(red: 0, green: 255, blue: 0), score: 0.5, chroma: 1, weightedCoverage: 0.5),
    ])

    let image = try palette.swatchStripCGImage(swatchSize: CGSize(width: 8, height: 4))
    #expect(image.width == 16)
    #expect(image.height == 4)
}

private func makeImage(width: Int, height: Int, rgb: [UInt8]) throws -> CGImage {
    var rgba = [UInt8]()
    rgba.reserveCapacity(width * height * 4)
    for index in stride(from: 0, to: rgb.count, by: 3) {
        rgba.append(rgb[index])
        rgba.append(rgb[index + 1])
        rgba.append(rgb[index + 2])
        rgba.append(255)
    }

    let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
    guard let provider = CGDataProvider(data: Data(rgba) as CFData) else {
        throw OkmainError.unableToCreateCGImage
    }

    guard let image = CGImage(
        width: width,
        height: height,
        bitsPerComponent: 8,
        bitsPerPixel: 32,
        bytesPerRow: width * 4,
        space: colorSpace,
        bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
        provider: provider,
        decode: nil,
        shouldInterpolate: false,
        intent: .defaultIntent
    ) else {
        throw OkmainError.unableToCreateCGImage
    }

    return image
}
