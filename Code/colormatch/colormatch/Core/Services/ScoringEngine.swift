import SwiftUI

enum ScoringEngine {
    static func accuracy(target: Color, guess: Color) -> Double {
        let deltaE = Color.deltaE(target, guess)
        return max(0, 100 - deltaE)
    }

    static func score(accuracy: Double, level: Int) -> Int {
        Int(accuracy.rounded(.down)) + level * 10
    }
}
