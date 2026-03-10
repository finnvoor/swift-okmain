import Foundation

private enum KMeansConstants {
    static let maxIterations = 300
    static let convergenceTolerance: Float = 1e-3
    static let adaptiveMinCentroidDistanceSquared: Float = 0.005
    static let greedyCandidateCount = 3
    static let randomSeed: UInt64 = 314_159
}

struct ClusteringResult {
    var centroids: [Oklab]
    var assignments: [Int]
}

enum KMeans {
    static func findCentroids(in sample: SampledOklabGrid, maxCentroids: Int) -> ClusteringResult {
        var rng = Xoshiro256PlusPlus(seed: KMeansConstants.randomSeed)
        var k = min(maxCentroids, sample.count)
        precondition(k > 0)

        while true {
            let result = lloyds(sample: sample, k: k, rng: &rng)
            let similarCount = countSimilarClusters(in: result.centroids)
            if similarCount == 0 || k <= 1 {
                return result
            }
            k -= 1
        }
    }

    private static func lloyds(sample: SampledOklabGrid, k: Int, rng: inout Xoshiro256PlusPlus) -> ClusteringResult {
        let actualK = min(k, sample.count)
        let seeds = findInitialCentroids(sample: sample, k: actualK, rng: &rng)
        var centroids = seeds.map { sample.point(at: $0) }
        var assignments = [Int](repeating: 0, count: sample.count)

        for _ in 0..<KMeansConstants.maxIterations {
            assignPoints(sample: sample, centroids: centroids, assignments: &assignments)
            let update = updateCentroids(sample: sample, centroids: &centroids, assignments: assignments)

            for index in 0..<actualK where update.counts[index] == 0 {
                let replacement = rng.randomRange(upperBound: sample.count)
                centroids[index] = sample.point(at: replacement)
            }

            if update.shiftSquared < KMeansConstants.convergenceTolerance {
                break
            }
        }

        return ClusteringResult(centroids: centroids, assignments: assignments)
    }

    private static func assignPoints(sample: SampledOklabGrid, centroids: [Oklab], assignments: inout [Int]) {
        for index in assignments.indices {
            let point = sample.point(at: index)
            var bestIndex = 0
            var bestDistance = Float.greatestFiniteMagnitude
            for (centroidIndex, centroid) in centroids.enumerated() {
                let distance = ColorMath.squaredDistance(point, centroid)
                if distance < bestDistance {
                    bestDistance = distance
                    bestIndex = centroidIndex
                }
            }
            assignments[index] = bestIndex
        }
    }

    private static func updateCentroids(sample: SampledOklabGrid, centroids: inout [Oklab], assignments: [Int]) -> (shiftSquared: Float, counts: [Int]) {
        let k = centroids.count
        var sumsL = [Float](repeating: 0, count: k)
        var sumsA = [Float](repeating: 0, count: k)
        var sumsB = [Float](repeating: 0, count: k)
        var counts = [Int](repeating: 0, count: k)

        for (pointIndex, centroidIndex) in assignments.enumerated() {
            sumsL[centroidIndex] += sample.l[pointIndex]
            sumsA[centroidIndex] += sample.a[pointIndex]
            sumsB[centroidIndex] += sample.b[pointIndex]
            counts[centroidIndex] += 1
        }

        var shiftSquared: Float = 0
        for index in 0..<k where counts[index] > 0 {
            let newCentroid = Oklab(
                l: sumsL[index] / Float(counts[index]),
                a: sumsA[index] / Float(counts[index]),
                b: sumsB[index] / Float(counts[index])
            )
            shiftSquared += ColorMath.squaredDistance(centroids[index], newCentroid)
            centroids[index] = newCentroid
        }
        return (shiftSquared, counts)
    }

    private static func findInitialCentroids(sample: SampledOklabGrid, k: Int, rng: inout Xoshiro256PlusPlus) -> [Int] {
        let count = sample.count
        guard count > 0 else { return [] }

        var initial = [Int]()
        initial.reserveCapacity(k)

        let first = rng.randomRange(upperBound: count)
        initial.append(first)

        var minDistances = [Float](repeating: 0, count: count)
        var minDistanceSum: Float = 0
        let firstPoint = sample.point(at: first)
        for index in 0..<count {
            let distance = ColorMath.squaredDistance(sample.point(at: index), firstPoint)
            minDistances[index] = distance
            minDistanceSum += distance
        }

        for _ in 1..<k {
            var candidates = [Int](repeating: 0, count: KMeansConstants.greedyCandidateCount)
            for index in candidates.indices {
                candidates[index] = sampleByDistance(minDistances: minDistances, sum: minDistanceSum, rng: &rng)
            }

            var bestPotential = Float.greatestFiniteMagnitude
            var bestCandidate = candidates[0]
            var bestDistances = minDistances

            for candidate in candidates {
                let point = sample.point(at: candidate)
                var candidateDistances = [Float](repeating: 0, count: count)
                var potential: Float = 0
                for index in 0..<count {
                    let distance = min(
                        minDistances[index],
                        ColorMath.squaredDistance(sample.point(at: index), point)
                    )
                    candidateDistances[index] = distance
                    potential += distance
                }
                if potential < bestPotential {
                    bestPotential = potential
                    bestCandidate = candidate
                    bestDistances = candidateDistances
                }
            }

            initial.append(bestCandidate)
            minDistances = bestDistances
            minDistanceSum = bestPotential
        }

        return initial
    }

    private static func sampleByDistance(minDistances: [Float], sum: Float, rng: inout Xoshiro256PlusPlus) -> Int {
        if sum <= 0 {
            return rng.randomRange(upperBound: minDistances.count)
        }

        let threshold = rng.randomF32() * sum
        var cumulative: Float = 0
        for (index, distance) in minDistances.enumerated() {
            cumulative += distance
            if cumulative > threshold {
                return index
            }
        }
        return minDistances.count - 1
    }

    private static func countSimilarClusters(in centroids: [Oklab]) -> Int {
        var count = 0
        for i in centroids.indices {
            for j in (i + 1)..<centroids.count {
                if ColorMath.squaredDistance(centroids[i], centroids[j]) < KMeansConstants.adaptiveMinCentroidDistanceSquared {
                    count += 1
                }
            }
        }
        return count
    }
}

private struct Xoshiro256PlusPlus {
    private var s0: UInt64
    private var s1: UInt64
    private var s2: UInt64
    private var s3: UInt64

    init(seed: UInt64) {
        var splitMix = SplitMix64(state: seed)
        self.s0 = splitMix.next()
        self.s1 = splitMix.next()
        self.s2 = splitMix.next()
        self.s3 = splitMix.next()
    }

    mutating func nextU64() -> UInt64 {
        let result = (s0 &+ s3).rotatedLeft(by: 23) &+ s0
        let t = s1 << 17

        s2 ^= s0
        s3 ^= s1
        s1 ^= s2
        s0 ^= s3

        s2 ^= t
        s3 = s3.rotatedLeft(by: 45)
        return result
    }

    mutating func nextU32() -> UInt32 {
        UInt32(nextU64() >> 32)
    }

    mutating func randomF32() -> Float {
        let precision: UInt32 = 24
        let scale: Float = 1 / Float(1 << precision)
        let value = nextU32() >> (32 - precision)
        return scale * Float(value)
    }

    mutating func randomRange(upperBound: Int) -> Int {
        precondition(upperBound > 0)
        let range = UInt32(upperBound)
        if range == 0 {
            return Int(nextU32())
        }

        let (result, lowOrder) = nextU32().multipliedFullWidth(by: range)
        var high = result

        if lowOrder > (0 &- range) {
            let (newHigh, _) = nextU32().multipliedFullWidth(by: range)
            let (_, overflow) = lowOrder.addingReportingOverflow(newHigh)
            if overflow {
                high &+= 1
            }
        }

        return Int(high)
    }
}

private struct SplitMix64 {
    var state: UInt64

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

private extension UInt64 {
    func rotatedLeft(by amount: UInt64) -> UInt64 {
        (self << amount) | (self >> (64 - amount))
    }
}
