import Observation
import Foundation

@Observable
final class SpotOddViewModel {
    private(set) var level: Int = 1
    private(set) var challenge: ColorChallenge
    private(set) var lives: Int = 3
    private(set) var score: Int = 0
    private(set) var phase: GamePhase = .playing
    private(set) var timeRemaining: Double? = nil
    private(set) var result: RoundResult? = nil

    // Haptic triggers — increment to fire
    private(set) var correctTapCount: Int = 0
    private(set) var wrongTapCount: Int = 0

    private let store: any PersistenceStore

    init(store: any PersistenceStore = UserDefaultsStore()) {
        self.store = store
        self.challenge = ColorGenerator.spotOddChallenge(level: 1, seed: Self.newSeed(level: 1))
        timeRemaining = DifficultyCurve.config(for: 1).timeLimit
    }

    func tapTile(_ index: Int) {
        guard phase == .playing else { return }
        if index == challenge.oddIndex {
            score += ScoringEngine.score(accuracy: 100.0, level: level)
            correctTapCount += 1
            phase = .levelComplete
        } else {
            wrongTapCount += 1
            lives -= 1
            if lives <= 0 { endGame() }
        }
    }

    func advanceToNextLevel() {
        guard phase == .levelComplete else { return }
        level += 1
        challenge = ColorGenerator.spotOddChallenge(level: level, seed: Self.newSeed(level: level))
        timeRemaining = DifficultyCurve.config(for: level).timeLimit
        phase = .playing
    }

    func tick() {
        guard phase == .playing, var t = timeRemaining else { return }
        t = max(0, t - 0.1)
        timeRemaining = t
        if t <= 0 { endGame() }
    }

    private func endGame() {
        phase = .gameOver
        let isNewBest = score > store.spotOddBest
        store.saveSpotOddBest(score)
        store.incrementTotalGames()
        result = RoundResult(
            mode: .spotOdd,
            score: score,
            accuracyPercent: min(100, Double(score) / Double(max(1, level) * 10) * 100),
            isNewBest: isNewBest,
            level: level
        )
    }

    private static func newSeed(level: Int) -> UInt64 {
        UInt64(Date.now.timeIntervalSince1970 * 1000) ^ UInt64(level &* 7919)
    }
}
