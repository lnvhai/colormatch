import Observation

@Observable
final class HomeViewModel {
    var spotOddBest: Int = 0
    var matchBest: Double = 0
    var matchSessionBest: Double = 0
    var dailyStreak: Int = 0

    private let store: any PersistenceStore

    init(store: any PersistenceStore = UserDefaultsStore()) {
        self.store = store
        refresh()
    }

    func refresh() {
        spotOddBest = store.spotOddBest
        matchBest   = store.matchBest
        matchSessionBest = store.matchSessionBest
        dailyStreak = store.dailyStreak
    }
}
