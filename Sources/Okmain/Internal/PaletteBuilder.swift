import Foundation

extension Okmain.Palette {
    static func build(
        sample: SampledOklabGrid,
        clustering: ClusteringResult,
        options: Okmain.Options
    ) -> Okmain.Palette {
        var weightedCounts = [Float](repeating: 0, count: clustering.centroids.count)

        for (index, assignment) in clustering.assignments.enumerated() {
            let x = index % sample.width
            let y = index / sample.width
            let maskValue = distanceMask(
                saturatedThreshold: options.maskSaturatedThreshold,
                width: sample.width,
                height: sample.height,
                x: x,
                y: y
            )
            let weight = 1 - options.maskWeight * (1 - maskValue)
            weightedCounts[assignment] += weight
        }

        let total = weightedCounts.reduce(0, +)
        if total > 0 {
            for index in weightedCounts.indices {
                weightedCounts[index] /= total
            }
        }

        let swatches = clustering.centroids.enumerated().map { index, centroid in
            let rgb = ColorMath.srgb(from: centroid)
            let chroma = ColorMath.chroma(centroid)
            let coverage = weightedCounts[index]
            let score = coverage * options.weightedCountsWeight + chroma * options.chromaWeight
            return Okmain.Palette.Swatch(
                color: OkmainColor(rgb: rgb),
                score: score,
                chroma: chroma,
                weightedCoverage: coverage
            )
        }
        .sorted { lhs, rhs in
            if lhs.score == rhs.score {
                return lhs.weightedCoverage > rhs.weightedCoverage
            }
            return lhs.score > rhs.score
        }

        return Okmain.Palette(swatches: swatches)
    }
}

private func distanceMask(
    saturatedThreshold: Float,
    width: Int,
    height: Int,
    x: Int,
    y: Int
) -> Float {
    let width = Float(width)
    let height = Float(height)
    var x = Float(x)
    var y = Float(y)

    let middleX = width / 2
    if x > middleX {
        x = width - x
    }

    let middleY = height / 2
    if y > middleY {
        y = height - y
    }

    let xThreshold = width * saturatedThreshold
    let yThreshold = height * saturatedThreshold

    let xContribution = min(0.1 + 0.9 * (x / xThreshold), 1)
    let yContribution = min(0.1 + 0.9 * (y / yThreshold), 1)
    return min(xContribution, yContribution)
}
