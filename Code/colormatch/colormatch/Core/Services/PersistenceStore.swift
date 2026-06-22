import Foundation

protocol PersistenceStore: AnyObject {
    var spotOddBest: Int { get }
    var matchBest: Double { get }
    var dailyStreak: Int { get }
    var lastPlayedDate: Date? { get }
    var totalGames: Int { get }

    func saveSpotOddBest(_ score: Int)
    func saveMatchBest(_ accuracy: Double)
    func recordDailyPlay(date: Date)
    func incrementTotalGames()
    func resetAll()
}

final class UserDefaultsStore: PersistenceStore {
    private enum Key: String, CaseIterable {
        case spotOddBest, matchBest, dailyStreak, lastPlayedDate, totalGames
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var spotOddBest: Int      { defaults.integer(forKey: Key.spotOddBest.rawValue) }
    var matchBest: Double     { defaults.double(forKey: Key.matchBest.rawValue) }
    var dailyStreak: Int      { defaults.integer(forKey: Key.dailyStreak.rawValue) }
    var totalGames: Int       { defaults.integer(forKey: Key.totalGames.rawValue) }
    var lastPlayedDate: Date? { defaults.object(forKey: Key.lastPlayedDate.rawValue) as? Date }

    func saveSpotOddBest(_ score: Int) {
        guard score > spotOddBest else { return }
        defaults.set(score, forKey: Key.spotOddBest.rawValue)
    }

    func saveMatchBest(_ accuracy: Double) {
        guard accuracy > matchBest else { return }
        defaults.set(accuracy, forKey: Key.matchBest.rawValue)
    }

    func recordDailyPlay(date: Date = .now) {
        let cal = Calendar.current
        if let last = lastPlayedDate {
            if cal.isDateInYesterday(last) {
                defaults.set(dailyStreak + 1, forKey: Key.dailyStreak.rawValue)
            } else if !cal.isDateInToday(last) {
                defaults.set(1, forKey: Key.dailyStreak.rawValue)
            }
        } else {
            defaults.set(1, forKey: Key.dailyStreak.rawValue)
        }
        defaults.set(date, forKey: Key.lastPlayedDate.rawValue)
    }

    func incrementTotalGames() {
        defaults.set(totalGames + 1, forKey: Key.totalGames.rawValue)
    }

    func resetAll() {
        Key.allCases.forEach { defaults.removeObject(forKey: $0.rawValue) }
    }
}
