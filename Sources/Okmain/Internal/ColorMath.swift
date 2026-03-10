import Foundation

struct RGB8: Hashable, Sendable {
    var red: UInt8
    var green: UInt8
    var blue: UInt8
}

struct Oklab: Sendable, Hashable {
    var l: Float
    var a: Float
    var b: Float
}

enum ColorMath {
    static let maxSRGBOklabChroma: Float = 0.32
    static let sRGBToLinear: [Float] = (0...255).map { value in
        let srgb = Float(value) / 255
        if srgb <= 0.04045 {
            return srgb / 12.92
        }
        return pow((srgb + 0.055) / 1.055, 2.4)
    }

    static func linearize(_ byte: UInt8) -> Float {
        sRGBToLinear[Int(byte)]
    }

    static func oklab(red: UInt8, green: UInt8, blue: UInt8) -> Oklab {
        oklabFromLinear(
            r: linearize(red),
            g: linearize(green),
            b: linearize(blue)
        )
    }

    static func oklabFromLinear(r: Float, g: Float, b: Float) -> Oklab {
        let l = cubeRoot(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b)
        let m = cubeRoot(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b)
        let s = cubeRoot(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b)

        return Oklab(
            l: 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
            a: 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
            b: 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
        )
    }

    static func srgb(from oklab: Oklab) -> RGB8 {
        let lPrime = oklab.l + 0.3963377774 * oklab.a + 0.2158037573 * oklab.b
        let mPrime = oklab.l - 0.1055613458 * oklab.a - 0.0638541728 * oklab.b
        let sPrime = oklab.l - 0.0894841775 * oklab.a - 1.2914855480 * oklab.b

        let l = lPrime * lPrime * lPrime
        let m = mPrime * mPrime * mPrime
        let s = sPrime * sPrime * sPrime

        let r = +4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
        let g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
        let b = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s

        return RGB8(
            red: encodeSRGB(r),
            green: encodeSRGB(g),
            blue: encodeSRGB(b)
        )
    }

    static func squaredDistance(_ lhs: Oklab, _ rhs: Oklab) -> Float {
        let dl = lhs.l - rhs.l
        let da = lhs.a - rhs.a
        let db = lhs.b - rhs.b
        return dl * dl + da * da + db * db
    }

    static func chroma(_ color: Oklab) -> Float {
        sqrt(color.a * color.a + color.b * color.b) / maxSRGBOklabChroma
    }

    private static func encodeSRGB(_ linear: Float) -> UInt8 {
        let clamped = min(max(linear, 0), 1)
        let srgb: Float
        if clamped <= 0.0031308 {
            srgb = clamped * 12.92
        } else {
            srgb = 1.055 * pow(clamped, 1 / 2.4) - 0.055
        }
        return UInt8(min(max(Int((srgb * 255).rounded()), 0), 255))
    }

    private static func cubeRoot(_ value: Float) -> Float {
        if value == 0 {
            return 0
        }
        return value > 0 ? pow(value, 1 / 3) : -pow(-value, 1 / 3)
    }
}
