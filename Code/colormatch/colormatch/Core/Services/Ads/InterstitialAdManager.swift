import GoogleMobileAds

@MainActor
final class InterstitialAdManager: NSObject {
    static let shared = InterstitialAdManager()

    private var interstitial: InterstitialAd?
    private var isLoading = false
    private var onDismiss: (() -> Void)?

    private override init() {
        super.init()
    }

    func preload() {
        guard !isLoading, interstitial == nil else { return }
        isLoading = true

        Task {
            defer { isLoading = false }
            do {
                let ad = try await InterstitialAd.load(
                    with: AdConstants.interstitialAdUnitID,
                    request: Request()
                )
                ad.fullScreenContentDelegate = self
                interstitial = ad
            } catch {
                interstitial = nil
            }
        }
    }

    func showIfAvailable(onDismiss: @escaping () -> Void) {
        guard let interstitial else {
            preload()
            onDismiss()
            return
        }

        self.onDismiss = onDismiss
        interstitial.present(from: nil)
    }
}

extension InterstitialAdManager: FullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in
            interstitial = nil
            let completion = onDismiss
            onDismiss = nil
            completion?()
            preload()
        }
    }

    nonisolated func ad(
        _ ad: FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        Task { @MainActor in
            interstitial = nil
            let completion = onDismiss
            onDismiss = nil
            completion?()
            preload()
        }
    }
}
