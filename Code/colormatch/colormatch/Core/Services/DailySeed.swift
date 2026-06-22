import Foundation

enum DailySeed {
    static func seed(for date: Date = .now) -> UInt64 {
        let cal = Calendar(identifier: .gregorian)
        let c = cal.dateComponents([.year, .month, .day], from: date)
        let y = UInt64(c.year ?? 2024)
        let m = UInt64(c.month ?? 1)
        let d = UInt64(c.day ?? 1)
        return y * 10000 + m * 100 + d
    }
}
