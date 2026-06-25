import SwiftUI

enum ScoringEngine {
    static func accuracy(target: Color, guess: Color) -> Double {
        let deltaE = Color.deltaE(target, guess)
        return max(0, 100 - deltaE)
    }

    /// Per-round score on a 0–10 scale (one decimal place).
    static func roundScore(accuracy: Double) -> Double {
        (accuracy / 10.0 * 10).rounded() / 10
    }

    static func score(accuracy: Double, level: Int) -> Int {
        Int(accuracy.rounded(.down)) + level * 10
    }
}
