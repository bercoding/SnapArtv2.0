import Foundation
import GoogleMobileAds
import UIKit

final class AppOpenAdManager: NSObject {
	static let shared = AppOpenAdManager()
	
	private var appOpenAd: AppOpenAd?
	private var isLoading = false
	private var lastLoadTime: Date?
	private var pendingCompletion: (() -> Void)?
	
	// Test ID App Open: ca-app-pub-3940256099942544/5662855259
	private let adUnitId = "/21775744923/example/app-open"
	
	private override init() {}
	
	func loadAdIfNeeded() {
		guard !isLoading, shouldLoadNewAd else { return }
		isLoading = true
		let request = Request()
		AppOpenAd.load(with: adUnitId, request: request) { [weak self] ad, error in
			guard let self = self else { return }
			self.isLoading = false
			if let error = error as NSError? {
				print("[AppOpenAd] Failed to load: \(error.localizedDescription)")
				// Nếu lỗi format, bỏ qua để không chặn luồng lần này
				return
			}
			self.appOpenAd = ad
			self.lastLoadTime = Date()
			print("[AppOpenAd] Loaded")
		}
	}
	
	func presentAdIfAvailable(completion: (() -> Void)? = nil) {
		pendingCompletion = completion
		guard let rootVC = Self.topViewController() else { completion?(); return }
		guard let ad = appOpenAd else {
			loadAdIfNeeded()
			completion?()
			return
		}
		ad.fullScreenContentDelegate = self
		ad.present(from: rootVC)
	}
	
	private var shouldLoadNewAd: Bool {
		guard let last = lastLoadTime else { return true }
		return Date().timeIntervalSince(last) > 4 * 60
	}
	
	private static func topViewController(base: UIViewController? = UIApplication.shared.connectedScenes
		.compactMap { $0 as? UIWindowScene }
		.flatMap { $0.windows }
		.first { $0.isKeyWindow }?
		.rootViewController) -> UIViewController? {
		if let nav = base as? UINavigationController {
			return topViewController(base: nav.visibleViewController)
		}
		if let tab = base as? UITabBarController {
			return topViewController(base: tab.selectedViewController)
		}
		if let presented = base?.presentedViewController {
			return topViewController(base: presented)
		}
		return base
	}
}

extension AppOpenAdManager: FullScreenContentDelegate {
	func adDidDismissFullScreenContent(_ ad: any FullScreenPresentingAd) {
		print("[AppOpenAd] Dismissed")
		appOpenAd = nil
		loadAdIfNeeded()
		pendingCompletion?()
		pendingCompletion = nil
	}
	
	func ad(_ ad: any FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: any Error) {
		print("[AppOpenAd] Present failed: \(error.localizedDescription)")
		appOpenAd = nil
		loadAdIfNeeded()
		pendingCompletion?()
		pendingCompletion = nil
	}
	
	func adDidRecordImpression(_ ad: any FullScreenPresentingAd) {
		print("[AppOpenAd] Impression")
	}
} 
