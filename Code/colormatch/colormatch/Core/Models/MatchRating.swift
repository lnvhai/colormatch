import SwiftUI

enum MatchRating: Equatable {
    case perfect    // ≥ 95
    case excellent  // ≥ 85
    case great      // ≥ 70
    case good       // ≥ 55
    case almost     // ≥ 40
    case failed     // < 40

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
