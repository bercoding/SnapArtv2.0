import Foundation
import GoogleMobileAds
import UIKit

class InterstitialAdManager: NSObject, ObservableObject {
    static let shared = InterstitialAdManager()
    
    @Published var isAdReady = false
    private var interstitialAd: InterstitialAd?
    
    // Test ID Interstitial Ad
    private let adUnitId = "ca-app-pub-3940256099942544/4411468910"
    
    private override init() {
        super.init()
        loadAd()
    }
    
    func loadAd() {
        let request = GADRequest()
        InterstitialAd.load(with: adUnitId, request: request) { [weak self] ad, error in
            if let error = error {
                print("Failed to load interstitial ad: \(error.localizedDescription)")
                self?.isAdReady = false
                return
            }
            
            self?.interstitialAd = ad
            self?.isAdReady = true
            print("Interstitial ad loaded successfully")
        }
    }
    
    func showAd(from viewController: UIViewController, completion: @escaping () -> Void) {
        guard let interstitialAd = interstitialAd else {
            print("Interstitial ad not ready")
            completion()
            return
        }
        
        interstitialAd.fullScreenContentDelegate = self
        interstitialAd.present(from: viewController)
        
        // Reset ad sau khi present
        self.interstitialAd = nil
        self.isAdReady = false
        
        completion()
    }
}

// MARK: - GADFullScreenContentDelegate
extension InterstitialAdManager: GADFullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("Interstitial ad dismissed")
        loadAd() // Load ad mới
    }
    
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Interstitial ad failed to present with error: \(error.localizedDescription)")
        loadAd() // Load ad mới
    }
} 