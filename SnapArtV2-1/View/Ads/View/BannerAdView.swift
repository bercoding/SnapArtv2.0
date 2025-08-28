import SwiftUI
import GoogleMobileAds

struct BannerAdView: View {
	let adUnitId: String
	var onAdLoaded: (() -> Void)? = nil

	init(adUnitId: String, onAdLoaded: (() -> Void)? = nil) {
		self.adUnitId = adUnitId
		self.onAdLoaded = onAdLoaded
	}

	var body: some View {
		GeometryReader { geometry in
			let width = geometry.size.width
			GADBannerViewRepresentable(
				adUnitId: adUnitId,
				availableWidth: width,
				onAdLoaded: onAdLoaded
			)
			.frame(width: width, height: currentOrientationAnchoredAdaptiveBanner(width: width).size.height)
		}
		.frame(height: currentOrientationAnchoredAdaptiveBanner(width: UIScreen.main.bounds.width).size.height)
	}
}

private struct GADBannerViewRepresentable: UIViewRepresentable {
	let adUnitId: String
	let availableWidth: CGFloat
	let onAdLoaded: (() -> Void)?

	func makeUIView(context: Context) -> BannerView {
		let size = currentOrientationAnchoredAdaptiveBanner(width: availableWidth)
		let bannerView = BannerView(adSize: size)
		bannerView.adUnitID = adUnitId
		bannerView.rootViewController = rootViewController()
		bannerView.delegate = context.coordinator
		bannerView.load(Request())
		return bannerView
	}

	func updateUIView(_ uiView: BannerView, context: Context) {
		let newSize = currentOrientationAnchoredAdaptiveBanner(width: availableWidth)
		if !CGSizeEqualToSize(uiView.adSize.size, newSize.size) {
			uiView.adSize = newSize
			uiView.load(Request())
		}
		if uiView.rootViewController == nil {
			uiView.rootViewController = rootViewController()
		}
	}

	func makeCoordinator() -> Coordinator {
		Coordinator(onAdLoaded: onAdLoaded)
	}

	final class Coordinator: NSObject, BannerViewDelegate {
		let onAdLoaded: (() -> Void)?
		init(onAdLoaded: (() -> Void)?) {
			self.onAdLoaded = onAdLoaded
		}
		func bannerViewDidReceiveAd(_ bannerView: BannerView) {
			print("[AdMob] Banner loaded: \(bannerView.adUnitID ?? "")")
			onAdLoaded?()
		}
		func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
			print("[AdMob] Banner failed: \(error.localizedDescription)")
		}
	}

	private func rootViewController() -> UIViewController? {
		UIApplication.shared.connectedScenes
			.compactMap { $0 as? UIWindowScene }
			.flatMap { $0.windows }
			.first { $0.isKeyWindow }?
			.rootViewController
	}
}

#Preview {
	BannerAdView(adUnitId: "ca-app-pub-3940256099942544/2934735716")
		.padding(.vertical)
} 
