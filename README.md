# Okmain

`Okmain` extracts a small palette of visually strong dominant colors from an image.

This package is a Swift rewrite of Dan Groshev's Rust [`okmain`](https://github.com/si14/okmain/tree/main/crates/okmain) crate, adapted for Apple platforms with:

- Core Image-backed image normalization and rasterization
- Oklab-based clustering and scoring
- deterministic results
- a small, Apple-friendly API surface
- convenience support for `CGImage`, `CIImage`, `NSImage`, `UIImage`, and SwiftUI `Image`

The goal of this package is to preserve the spirit and behavior of the original project while providing a native Swift Package API for Apple image types.

## Requirements

- Swift 6.2
- macOS 13+
- iOS 16+
- tvOS 16+
- visionOS 1+

## Installation

Add the package to your `Package.swift`:

```swift
.package(url: "https://github.com/finnvoor/swift-okmain.git", from: "0.1.0")
```

Then add the product to your target:

```swift
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "Okmain", package: "swift-okmain")
    ]
)
```

## Attribution And Licensing

This repository is a rewrite of `okmain` by Dan Groshev.

Upstream project:

- GitHub: <https://github.com/si14/okmain>
- Crate: <https://crates.io/crates/okmain>

Upstream `okmain` is dual-licensed under `MIT OR Apache-2.0`. This package follows that licensing model and includes both license texts:

- [LICENSE-MIT](./LICENSE-MIT)
- [LICENSE-APACHE](./LICENSE-APACHE)

Additional provenance information is in [NOTICE](./NOTICE).

## Quick Start

For most callers, `Okmain.colors(in:)` is the simplest API:

```swift
import Okmain

let colors = try Okmain.colors(in: cgImage)
let dominant = colors.first
```

If you want ranking metadata and helper rendering APIs, use `Okmain.palette(in:)`:

```swift
import Okmain

let palette = try Okmain.palette(in: cgImage)

print(palette.colors)
print(palette.dominant?.color)
print(palette.swatches)
```

## Public API

### Entry Points

Static APIs:

```swift
let palette = try Okmain.palette(in: ciImage)
let palette = try Okmain.palette(in: cgImage)
let colors = try Okmain.colors(in: ciImage)
let colors = try Okmain.colors(in: cgImage)
```

Platform convenience overloads:

```swift
let palette = try Okmain.palette(in: nsImage)
let palette = try Okmain.palette(in: uiImage)
let palette = try Okmain.palette(in: swiftUIImage)
```

Instance convenience APIs:

```swift
let palette = try ciImage.okmainPalette()
let colors = try cgImage.okmainColors()
let palette = try nsImage.okmainPalette()
let colors = try uiImage.okmainColors()
let palette = try swiftUIImage.okmainPalette()
```

### `Okmain.Options`

`Okmain.Options` controls palette extraction:

```swift
let options = Okmain.Options(
    maximumColorCount: 4,
    maskSaturatedThreshold: 0.3,
    maskWeight: 1.0,
    weightedCountsWeight: 0.3,
    chromaWeight: 0.7
)
```

Fields:

- `maximumColorCount`: maximum number of returned colors, `1...4`
- `maskSaturatedThreshold`: center-priority mask threshold, must be in `[0, 0.5)`
- `maskWeight`: how much center weighting matters, must be in `[0, 1]`
- `weightedCountsWeight`: score contribution from weighted coverage, must be in `[0, 1]`
- `chromaWeight`: score contribution from chroma, must be in `[0, 1]`

`weightedCountsWeight + chromaWeight` must equal `1`.

Example:

```swift
let options = Okmain.Options(
    maximumColorCount: 3,
    maskWeight: 0.8,
    weightedCountsWeight: 0.5,
    chromaWeight: 0.5
)

let palette = try Okmain.palette(in: cgImage, options: options)
```

### `Okmain.Palette`

`Okmain.Palette` is the richer result type.

```swift
public struct Palette {
    public var swatches: [Swatch]
    public var dominant: Swatch? { get }
    public var colors: [OkmainColor] { get }
}
```

Each `Swatch` includes:

- `color`: the extracted color
- `score`: final ranking score
- `chroma`: normalized Oklab chroma used in ranking
- `weightedCoverage`: normalized weighted pixel coverage

Example:

```swift
let palette = try Okmain.palette(in: cgImage)

for swatch in palette.swatches {
    print(swatch.color, swatch.score)
}
```

### `OkmainColor`

`OkmainColor` stores sRGB components as bytes:

```swift
public struct OkmainColor {
    public var red: UInt8
    public var green: UInt8
    public var blue: UInt8
    public var alpha: UInt8
}
```

It also provides platform conversions:

- `cgColor`
- `ciColor`
- `nsColor` on AppKit platforms
- `uiColor` on UIKit platforms
- `swiftUIColor` when SwiftUI is available

Example:

```swift
let color = try Okmain.colors(in: cgImage).first!
let cgColor = color.cgColor
```

## Supported Image Types

### `CGImage`

```swift
let palette = try Okmain.palette(in: cgImage)
let colors = try cgImage.okmainColors()
```

### `CIImage`

```swift
let palette = try Okmain.palette(in: ciImage)
let colors = try ciImage.okmainColors()
```

### `NSImage`

```swift
import AppKit
import Okmain

let palette = try nsImage.okmainPalette()
let colors = try nsImage.okmainColors()
```

### `UIImage`

```swift
import UIKit
import Okmain

let palette = try uiImage.okmainPalette()
let colors = try uiImage.okmainColors()
```

### SwiftUI `Image`

SwiftUI images must be rendered before analysis, so those overloads are `@MainActor`.

```swift
import SwiftUI
import Okmain

@MainActor
func extractPalette(image: Image) throws -> Okmain.Palette {
    try image.okmainPalette(proposedSize: CGSize(width: 300, height: 300))
}
```

You can also control the render size and scale:

```swift
let palette = try image.okmainPalette(
    proposedSize: CGSize(width: 400, height: 300),
    scale: 2
)
```

## Rendering Palette Strips

`Okmain.Palette` can render a simple swatch strip image:

```swift
let palette = try Okmain.palette(in: cgImage)
let swatchStrip = try palette.swatchStripCGImage()
```

Also available:

- `swatchStripCIImage()`
- `swatchStripNSImage()` on AppKit
- `swatchStripUIImage()` on UIKit
- `swatchStripImage()` for SwiftUI

Example:

```swift
let strip = try palette.swatchStripCIImage(
    swatchSize: CGSize(width: 80, height: 40)
)
```

## Error Handling

Errors are thrown as `OkmainError`.

Current cases include:

- `emptyImage`
- `invalidImageExtent(_:)`
- `unableToCreateBitmapContext`
- `unableToRenderSwiftUIImage`
- `unableToCreateCGImage`
- invalid option validation errors

Example:

```swift
do {
    let palette = try Okmain.palette(in: cgImage)
    print(palette.colors)
} catch {
    print(error)
}
```

## Notes

- Results are deterministic for the same input.
- The ranking is not just raw pixel frequency; more central and more visually prominent colors are prioritized.
- Returned palettes may contain fewer than the requested maximum when clusters collapse together.
