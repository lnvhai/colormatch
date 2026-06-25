import Observation
import SwiftUI

enum MatchPhase: Equatable {
    case memorizing
    case guessing
    case roundResult
    case sessionComplete
}

@Observable
final class MatchColorViewModel {
    static let roundsPerSession = 5
    static let maxSessionScore = Double(roundsPerSession) * 10

    private(set) var challenge: ColorChallenge
    private(set) var currentRound = 1
    private(set) var roundResults: [MatchRoundResult] = []

    var hue:        Double = 0.5
    var saturation: Double = 0.5
    var brightness: Double = 0.5

    private(set) var phase: MatchPhase = .memorizing
    private(set) var memorizeTimeLeft: Double = 3.0
    private(set) var sessionIsNewBest = false
    private(set) var sessionBest: Double = 0

    var guessColor: Color {
        Color(hue: hue, saturation: saturation, brightness: brightness)
    }

    var latestRoundResult: MatchRoundResult? { roundResults.last }

    var totalScore: Double {
        roundResults.map(\.roundScore).reduce(0, +)
    }

    var isLastRound: Bool { currentRound >= Self.roundsPerSession }

    private let store: any PersistenceStore
    private let sessionSeed: UInt64

    init(level: Int = 1, store: any PersistenceStore = UserDefaultsStore()) {
        self.store = store
        self.sessionSeed = UInt64(Date.now.timeIntervalSince1970 * 1000)
        self.sessionBest = store.matchSessionBest
        self.challenge = ColorGenerator.matchChallenge(
            level: level,
            seed: sessionSeed
        )
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
        let accuracy = ScoringEngine.accuracy(target: challenge.targetColor, guess: guessColor)
        let roundScore = ScoringEngine.roundScore(accuracy: accuracy)
        roundResults.append(
            MatchRoundResult(
                targetColor: challenge.targetColor,
                guessColor: guessColor,
                roundScore: roundScore,
                accuracy: accuracy
            )
        )
        phase = .roundResult
    }

    func continueFromRoundResult() {
        guard phase == .roundResult else { return }
        if isLastRound {
            finishSession()
        } else {
            currentRound += 1
            startNextRound()
        }
    }

    func restartSession() {
        currentRound = 1
        roundResults = []
        sessionIsNewBest = false
        sessionBest = store.matchSessionBest
        startNextRound(seed: UInt64(Date.now.timeIntervalSince1970 * 1000))
    }

    private func finishSession() {
        let total = totalScore
        sessionIsNewBest = total > store.matchSessionBest
        store.saveMatchSessionBest(total)
        store.incrementTotalGames()
        sessionBest = store.matchSessionBest
        phase = .sessionComplete
    }

    private func startNextRound(seed: UInt64? = nil) {
        hue = 0.5
        saturation = 0.5
        brightness = 0.5
        memorizeTimeLeft = 3.0
        let roundSeed = seed ?? sessionSeed ^ UInt64(currentRound * 9973)
        challenge = ColorGenerator.matchChallenge(level: currentRound, seed: roundSeed)
        phase = .memorizing
    }
}
