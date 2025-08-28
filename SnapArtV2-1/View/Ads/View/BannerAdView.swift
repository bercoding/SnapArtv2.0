import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {
    let adUnitId: String
    let onAdLoaded: (() -> Void)?

    init(adUnitId: String, onAdLoaded: (() -> Void)? = nil) {
        self.adUnitId = adUnitId
        self.onAdLoaded = onAdLoaded
    }

    func makeUIView(context: Context) -> BannerView {
        let width = UIScreen.main.bounds.width
        let size = currentOrientationAnchoredAdaptiveBanner(width: width)
        let bannerView = BannerView(adSize: size)
        bannerView.adUnitID = adUnitId
        bannerView.rootViewController = rootViewController()
        bannerView.delegate = context.coordinator
        return bannerView
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        let width = UIScreen.main.bounds.width
        let size = currentOrientationAnchoredAdaptiveBanner(width: width)
        if uiView.adSize.size != size.size {
            uiView.adSize = size
        }
        if uiView.rootViewController == nil {
            uiView.rootViewController = rootViewController()
        }
        uiView.load(Request())
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, BannerViewDelegate {
        let parent: BannerAdView

        init(_ parent: BannerAdView) {
            self.parent = parent
        }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            print("[Banner] loaded successfully: \(bannerView.adUnitID ?? "")")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.parent.onAdLoaded?()
            }
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            print("[Banner] failed: \(error.localizedDescription)")
        }
    }
}

private func rootViewController() -> UIViewController? {
    UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }
        .first { $0.isKeyWindow }?
        .rootViewController
} 