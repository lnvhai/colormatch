import GoogleMobileAds
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        MobileAds.shared.start { _ in
            Task { @MainActor in
                await AppOpenAdManager.shared.loadAd()
                InterstitialAdManager.shared.preload()
            }
        }
        return true
    }
}
