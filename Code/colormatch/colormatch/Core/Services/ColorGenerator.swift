import SwiftUI

enum ColorGenerator {
    static func spotOddChallenge(level: Int, seed: UInt64) -> ColorChallenge {
        let config = DifficultyCurve.config(for: level)
        var rng = SeededRandom(seed: seed)

        let baseColor = Color(
            hue:        rng.nextDouble(),
            saturation: 0.55 + rng.nextDouble() * 0.35,
            brightness: 0.50 + rng.nextDouble() * 0.40
        )

        // Shift L by colorDelta toward mid-range to stay in gamut
        let baseLab = baseColor.labComponents
        let direction: Double = baseLab.L > 50 ? -1 : 1
        let oddL = max(0, min(100, baseLab.L + direction * config.colorDelta))
        let oddColor = Color.fromLab(LabColor(L: oddL, a: baseLab.a, b: baseLab.b))

        let tileCount = config.gridSize * config.gridSize
        let oddIndex  = Int(rng.next() % UInt64(tileCount))

        var grid = [Color](repeating: baseColor, count: tileCount)
        grid[oddIndex] = oddColor

        return ColorChallenge(
            mode: .spotOdd, level: level, seed: seed,
            targetColor: oddColor, grid: grid,
            gridSize: config.gridSize, oddIndex: oddIndex
        )
    }

    static func matchChallenge(level: Int, seed: UInt64) -> ColorChallenge {
        var rng = SeededRandom(seed: seed)
        let target = Color(
            hue:        rng.nextDouble(),
            saturation: 0.30 + rng.nextDouble() * 0.60,
            brightness: 0.40 + rng.nextDouble() * 0.50
        )
        return ColorChallenge(
            mode: .match, level: level, seed: seed,
            targetColor: target, grid: [], gridSize: 0, oddIndex: -1
        )
    }
}
