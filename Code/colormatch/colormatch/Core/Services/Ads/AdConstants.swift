import Foundation

enum AdConstants {
    static let applicationID = "ca-app-pub-7772128325282437~5855574864"
    static let interstitialUnitID = "ca-app-pub-7772128325282437/6480436990"
    static let appOpenUnitID = "ca-app-pub-7772128325282437/6268684005"

    #if DEBUG
    static let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"
    static let appOpenAdUnitID = "ca-app-pub-3940256099942544/5575463023"
    #else
    static let interstitialAdUnitID = interstitialUnitID
    static let appOpenAdUnitID = appOpenUnitID
    #endif
}
