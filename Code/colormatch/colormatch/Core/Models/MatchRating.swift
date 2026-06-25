import SwiftUI

enum MatchRoundRating: Equatable {
    case perfect
    case excellent
    case great
    case good
    case almost
    case failed

    init(roundScore: Double) {
        switch roundScore {
        case 9.5...: self = .perfect
        case 8.5...: self = .excellent
        case 7.0...: self = .great
        case 5.5...: self = .good
        case 4.0...: self = .almost
        default:    self = .failed
        }
    }

    var message: String {
        switch self {
        case .perfect:
            "You've got photographic memory. Are you even human?"
        case .excellent:
            "Your eyes are razor sharp. Most people can't get this close."
        case .great:
            "Solid color instincts. You've clearly got a good eye."
        case .good:
            "Not bad. Not great. Somewhere in the middle."
        case .almost:
            "You were in the ballpark but the colors disagree."
        case .failed:
            "Way off. Did you even look at the target?"
        }
    }

    var isFailed: Bool { self == .failed }
}

enum MatchSessionRating: Equatable {
    case perfect
    case excellent
    case great
    case good
    case almost
    case failed

    init(totalScore: Double) {
        switch totalScore {
        case 47.5...: self = .perfect
        case 42.5...: self = .excellent
        case 37.5...: self = .great
        case 27.5...: self = .good
        case 20.0...: self = .almost
        default:    self = .failed
        }
    }

    var message: String {
        switch self {
        case .perfect:
            "Flawless session. You're basically a color-calibrated display."
        case .excellent:
            "Legitimately impressive. Your eyes work."
        case .great:
            "Solid session. You've clearly got a good eye."
        case .good:
            "Decent run. A little more focus and you'll crush it."
        case .almost:
            "Some hits, some misses. Keep training."
        case .failed:
            "Rough session. The colors won this round."
        }
    }
}

// Legacy rating used by Daily Challenge.
enum MatchRating: Equatable {
    case perfect
    case excellent
    case great
    case good
    case almost
    case failed

    init(accuracy: Double) {
        switch accuracy {
        case 95...: self = .perfect
        case 85...: self = .excellent
        case 70...: self = .great
        case 55...: self = .good
        case 40...: self = .almost
        default:    self = .failed
        }
    }

    var label: String {
        switch self {
        case .perfect:   "Perfect!"
        case .excellent: "Excellent!"
        case .great:     "Great!"
        case .good:      "Good"
        case .almost:    "Almost..."
        case .failed:    "Failed"
        }
    }

    var message: String {
        switch self {
        case .perfect:
            "You've got photographic memory. Are you even human?"
        case .excellent:
            "Your eyes are razor sharp. Most people can't get this close."
        case .great:
            "Solid color instincts. You've clearly got a good eye."
        case .good:
            "Not bad! A little more focus and you'll nail it."
        case .almost:
            "You were in the ballpark but the colors disagree."
        case .failed:
            "Way off. Did you even look at the target?"
        }
    }

    var color: Color {
        switch self {
        case .perfect, .excellent: return AppColor.success
        case .great, .good:        return AppColor.accent
        case .almost, .failed:     return AppColor.failure
        }
    }

    var isFailed: Bool { self == .failed }
}
