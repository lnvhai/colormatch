import Observation
import SwiftUI

enum DailyState: Equatable {
    case lobby
    case playing
    case done(accuracy: Double, isNewBest: Bool)
    case alreadyPlayed
}

@Observable
final class DailyChallengeViewModel {
    private(set) var state: DailyState = .lobby
    private(set) var streak: Int = 0

    let seed: UInt64
    let challenge: ColorChallenge
    let dateString: String

    var hue:        Double = 0.5
    var saturation: Double = 0.5
    var brightness: Double = 0.5

    var guessColor: Color {
        Color(hue: hue, saturation: saturation, brightness: brightness)
    }

    private let store: any PersistenceStore

    init(store: any PersistenceStore = UserDefaultsStore()) {
        self.store = store
        self.seed      = DailySeed.seed()
        self.challenge = ColorGenerator.matchChallenge(level: 3, seed: DailySeed.seed())
        self.streak    = store.dailyStreak

        let f = DateFormatter()
        f.dateStyle = .long
        self.dateString = f.string(from: .now)

        if let last = store.lastPlayedDate, Calendar.current.isDateInToday(last) {
            state = .alreadyPlayed
        }
    }

    func startPlaying() {
        guard state == .lobby else { return }
        state = .playing
    }

    func submit() {
        guard state == .playing else { return }
        let accuracy  = ScoringEngine.accuracy(target: challenge.targetColor, guess: guessColor)
        let isNewBest = accuracy > store.matchBest
        store.saveMatchBest(accuracy)
        store.recordDailyPlay(date: .now)
        store.incrementTotalGames()
        streak = store.dailyStreak
        state  = .done(accuracy: accuracy, isNewBest: isNewBest)
    }
}
