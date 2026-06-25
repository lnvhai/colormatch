import GoogleMobileAds
import UIKit

@MainActor
final class AppOpenAdManager: NSObject {
    static let shared = AppOpenAdManager()

    private var appOpenAd: AppOpenAd?
    private var isLoading = false
    private(set) var isShowingAd = false
    private var loadTime: Date?
    private var shouldShowWhenReady = false

    private let timeoutInterval: TimeInterval = 4 * 3_600

    private override init() {
        super.init()
    }

    func loadAd() async {
        guard !isLoading, !isAdAvailable() else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let ad = try await AppOpenAd.load(
                with: AdConstants.appOpenAdUnitID,
                request: Request()
            )
            ad.fullScreenContentDelegate = self
            appOpenAd = ad
            loadTime = Date()

            if shouldShowWhenReady {
                shouldShowWhenReady = false
                presentIfPossible()
            }
        } catch {
            appOpenAd = nil
            loadTime = nil
            shouldShowWhenReady = false
        }
    }

    func showAdIfAvailable() {
        guard !isShowingAd else { return }

        if isAdAvailable() {
            shouldShowWhenReady = false
            presentIfPossible()
        } else {
            shouldShowWhenReady = true
            Task { await loadAd() }
        }
    }

    private func presentIfPossible() {
        guard !isShowingAd, let appOpenAd, isAdAvailable() else { return }
        appOpenAd.present(from: Self.rootViewController)
        isShowingAd = true
    }

    private func isAdAvailable() -> Bool {
        guard appOpenAd != nil, let loadTime else { return false }
        return Date().timeIntervalSince(loadTime) < timeoutInterval
    }

    private static var rootViewController: UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
    }
}

extension AppOpenAdManager: FullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in
            appOpenAd = nil
            isShowingAd = false
            await loadAd()
        }
    }

    nonisolated func ad(
        _ ad: FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        Task { @MainActor in
            appOpenAd = nil
            isShowingAd = false
            await loadAd()
        }
    }
}
