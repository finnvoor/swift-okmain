import Foundation

extension Okmain {
    public struct Options: Sendable, Hashable {
        public static let `default` = Self()

        public var maximumColorCount: Int
        public var maskSaturatedThreshold: Float
        public var maskWeight: Float
        public var weightedCountsWeight: Float
        public var chromaWeight: Float

        public init(
            maximumColorCount: Int = 4,
            maskSaturatedThreshold: Float = 0.3,
            maskWeight: Float = 1.0,
            weightedCountsWeight: Float = 0.3,
            chromaWeight: Float = 0.7
        ) {
            self.maximumColorCount = maximumColorCount
            self.maskSaturatedThreshold = maskSaturatedThreshold
            self.maskWeight = maskWeight
            self.weightedCountsWeight = weightedCountsWeight
            self.chromaWeight = chromaWeight
        }

        func validate() throws {
            guard (1...4).contains(maximumColorCount) else {
                throw OkmainError.invalidMaximumColorCount(maximumColorCount)
            }
            guard (0..<0.5).contains(maskSaturatedThreshold) else {
                throw OkmainError.invalidMaskSaturatedThreshold(maskSaturatedThreshold)
            }
            guard (0...1).contains(maskWeight) else {
                throw OkmainError.invalidMaskWeight(maskWeight)
            }
            guard (0...1).contains(weightedCountsWeight) else {
                throw OkmainError.invalidWeightedCountsWeight(weightedCountsWeight)
            }
            guard (0...1).contains(chromaWeight) else {
                throw OkmainError.invalidChromaWeight(chromaWeight)
            }

            let sum = weightedCountsWeight + chromaWeight
            guard abs(sum - 1) < 0.00001 else {
                throw OkmainError.weightsMustAddUpToOne(
                    weightedCountsWeight: weightedCountsWeight,
                    chromaWeight: chromaWeight
                )
            }
        }
    }
}

public enum OkmainError: Error, LocalizedError, Sendable, Equatable {
    case emptyImage
    case invalidImageExtent(CGRect)
    case unableToCreateBitmapContext
    case unableToRenderSwiftUIImage
    case unableToCreateCGImage
    case invalidMaximumColorCount(Int)
    case invalidMaskSaturatedThreshold(Float)
    case invalidMaskWeight(Float)
    case invalidWeightedCountsWeight(Float)
    case invalidChromaWeight(Float)
    case weightsMustAddUpToOne(weightedCountsWeight: Float, chromaWeight: Float)

    public var errorDescription: String? {
        switch self {
        case .emptyImage:
            return "The image has no pixels."
        case .invalidImageExtent(let extent):
            return "The image extent is invalid: \(extent)."
        case .unableToCreateBitmapContext:
            return "Failed to create a bitmap context."
        case .unableToRenderSwiftUIImage:
            return "Failed to render the SwiftUI image."
        case .unableToCreateCGImage:
            return "Failed to create a CGImage."
        case .invalidMaximumColorCount(let count):
            return "maximumColorCount must be in 1...4, got \(count)."
        case .invalidMaskSaturatedThreshold(let value):
            return "maskSaturatedThreshold must be in [0, 0.5), got \(value)."
        case .invalidMaskWeight(let value):
            return "maskWeight must be in [0, 1], got \(value)."
        case .invalidWeightedCountsWeight(let value):
            return "weightedCountsWeight must be in [0, 1], got \(value)."
        case .invalidChromaWeight(let value):
            return "chromaWeight must be in [0, 1], got \(value)."
        case .weightsMustAddUpToOne(let weightedCountsWeight, let chromaWeight):
            return "weightedCountsWeight (\(weightedCountsWeight)) and chromaWeight (\(chromaWeight)) must add up to 1."
        }
    }
}
