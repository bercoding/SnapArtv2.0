import Foundation
import GoogleMobileAds
//import UIKit

final class InterstitialAdManager: NSObject, ObservableObject {
	static let shared = InterstitialAdManager()
	
	private var interstitial: InterstitialAd?
	private var isLoading = false
	
	// Test ID Interstitial: ca-app-pub-3940256099942544/4411468910
	private let adUnitId = "ca-app-pub-3940256099942544/4411468910"
	
	private override init() {
		super.init()
		loadAd()
	}
	
	func loadAd() {
		guard !isLoading else { return }
		isLoading = true
		
		let request = Request()
		InterstitialAd.load(with: adUnitId, request: request) { [weak self] ad, error in
			guard let self = self else { return }
			self.isLoading = false
			
			if let error = error {
				print("[Interstitial] Failed to load: \(error.localizedDescription)")
				return
			}
			
			self.interstitial = ad
			print("[Interstitial] Loaded successfully")
		}
	}
	
	func showAd(from viewController: UIViewController, completion: (() -> Void)? = nil) {
		guard let ad = interstitial else {
			print("[Interstitial] No ad available, loading new one")
			loadAd()
			completion?()
			return
		}
		
		ad.fullScreenContentDelegate = self
		ad.present(from: viewController)
		
		// Store completion for delegate callbacks
		objc_setAssociatedObject(ad, "completion", completion, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
	}
	
	func showAdIfAvailable(from viewController: UIViewController, completion: (() -> Void)? = nil) {
		showAd(from: viewController, completion: completion)
	}
}

extension InterstitialAdManager: FullScreenContentDelegate {
	func adDidDismissFullScreenContent(_ ad: any FullScreenPresentingAd) {
		print("[Interstitial] Dismissed")
		interstitial = nil
		loadAd() // Preload next ad
		
		// Call completion
		if let completion = objc_getAssociatedObject(ad, "completion") as? (() -> Void) {
			completion()
		}
	}
	
	func ad(_ ad: any FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: any Error) {
		print("[Interstitial] Present failed: \(error.localizedDescription)")
		interstitial = nil
		loadAd()
		
		// Call completion even on failure
		if let completion = objc_getAssociatedObject(ad, "completion") as? (() -> Void) {
			completion()
		}
	}
	
	func adDidRecordImpression(_ ad: any FullScreenPresentingAd) {
		print("[Interstitial] Impression recorded")
	}
} 
