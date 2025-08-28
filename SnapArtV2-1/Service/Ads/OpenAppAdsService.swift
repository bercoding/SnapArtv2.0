import Foundation

final class AdsService {
	static let shared = AdsService()
	private init() {}
	
	func preloadOpenAd() {
		AppOpenAdManager.shared.loadAdIfNeeded()
	}
	
	func presentOpenAd(completion: (() -> Void)? = nil) {
		AppOpenAdManager.shared.presentAdIfAvailable(completion: completion)
	}
} 