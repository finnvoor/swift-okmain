import CoreGraphics
import CoreImage
import Foundation

struct RasterImage {
    var width: Int
    var height: Int
    var rgba: [UInt8]

    static func make(from image: CIImage, context: CIContext) throws -> RasterImage {
        let integral = image.extent.integral
        guard integral.width > 0, integral.height > 0 else {
            throw integral.isNull ? OkmainError.emptyImage : OkmainError.invalidImageExtent(integral)
        }

        let width = Int(integral.width)
        let height = Int(integral.height)
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()

        context.render(
            image,
            toBitmap: &bytes,
            rowBytes: width * 4,
            bounds: integral,
            format: .RGBA8,
            colorSpace: colorSpace
        )

        return RasterImage(width: width, height: height, rgba: bytes)
    }
}

struct SampledOklabGrid {
    static let maxSampleSize = 250_000

    var width: Int
    var height: Int
    var l: [Float]
    var a: [Float]
    var b: [Float]

    init(from raster: RasterImage) throws {
        guard raster.width > 0, raster.height > 0 else {
            throw OkmainError.emptyImage
        }

        let block = Self.blockSize(width: raster.width, height: raster.height)
        let blocksX = (raster.width + block - 1) / block
        let blocksY = (raster.height + block - 1) / block

        self.width = blocksX
        self.height = blocksY
        self.l = []
        self.a = []
        self.b = []
        self.l.reserveCapacity(blocksX * blocksY)
        self.a.reserveCapacity(blocksX * blocksY)
        self.b.reserveCapacity(blocksX * blocksY)

        var accR = [Float](repeating: 0, count: blocksX)
        var accG = [Float](repeating: 0, count: blocksX)
        var accB = [Float](repeating: 0, count: blocksX)
        var counts = [Int](repeating: 0, count: blocksX)

        for by in 0..<blocksY {
            let yStart = by * block
            let yEnd = min(yStart + block, raster.height)

            for y in yStart..<yEnd {
                let rowOffset = y * raster.width * 4
                for bx in 0..<blocksX {
                    let xStart = bx * block
                    let xEnd = min(xStart + block, raster.width)
                    for x in xStart..<xEnd {
                        let index = rowOffset + x * 4
                        accR[bx] += ColorMath.linearize(raster.rgba[index])
                        accG[bx] += ColorMath.linearize(raster.rgba[index + 1])
                        accB[bx] += ColorMath.linearize(raster.rgba[index + 2])
                        counts[bx] += 1
                    }
                }
            }

            for bx in 0..<blocksX {
                let count = Float(counts[bx])
                let oklab = ColorMath.oklabFromLinear(
                    r: accR[bx] / count,
                    g: accG[bx] / count,
                    b: accB[bx] / count
                )
                l.append(oklab.l)
                a.append(oklab.a)
                b.append(oklab.b)
                accR[bx] = 0
                accG[bx] = 0
                accB[bx] = 0
                counts[bx] = 0
            }
        }
    }

    var count: Int { l.count }

    func point(at index: Int) -> Oklab {
        Oklab(l: l[index], a: a[index], b: b[index])
    }

    static func blockSize(width: Int, height: Int) -> Int {
        let total = width * height
        if total <= maxSampleSize {
            return 1
        }

        let scale = ceil(sqrt(Double(total) / Double(maxSampleSize)))
        let raw = Int(scale)
        return (raw + 3) & ~3
    }
}
