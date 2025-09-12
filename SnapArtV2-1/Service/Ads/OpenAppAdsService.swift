import Foundation

final class AdsService {
	static let shared = AdsService()
	private init() {}
	
	func preloadOpenAd() {
		AppOpenAdManager.shared.loadAppOpenAd()
	}
	
	func presentOpenAd(completion: (() -> Void)? = nil) {
		AppOpenAdManager.shared.showAppOpenAdIfAvailable()
		completion?()
	}
} 
