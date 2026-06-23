import Observation
import SwiftUI

enum MatchPhase: Equatable {
    case memorizing
    case guessing
    case result
}

@Observable
final class MatchColorViewModel {
    let challenge: ColorChallenge

    var hue:        Double = 0.5
    var saturation: Double = 0.5
    var brightness: Double = 0.5

    private(set) var phase: MatchPhase = .memorizing
    private(set) var memorizeTimeLeft: Double = 3.0
    private(set) var accuracy: Double = 0
    private(set) var result: RoundResult? = nil

    var guessColor: Color {
        Color(hue: hue, saturation: saturation, brightness: brightness)
    }

    private let store: any PersistenceStore

    init(level: Int = 1, store: any PersistenceStore = UserDefaultsStore()) {
        self.store = store
        let seed = UInt64(Date.now.timeIntervalSince1970 * 1000)
        self.challenge = ColorGenerator.matchChallenge(level: level, seed: seed)
    }

    func tick() {
        guard phase == .memorizing else { return }
        memorizeTimeLeft = max(0, memorizeTimeLeft - 0.05)
        if memorizeTimeLeft <= 0 {
            phase = .guessing
        }
    }

    func submit() {
        guard phase == .guessing else { return }
        accuracy = ScoringEngine.accuracy(target: challenge.targetColor, guess: guessColor)
        let score = ScoringEngine.score(accuracy: accuracy, level: challenge.level)
        let isNewBest = accuracy > store.matchBest
        store.saveMatchBest(accuracy)
        store.incrementTotalGames()
        result = RoundResult(
            mode: .match,
            score: score,
            accuracyPercent: accuracy,
            isNewBest: isNewBest,
            level: challenge.level
        )
        phase = .result
    }
}
