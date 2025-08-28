import Foundation
import GoogleMobileAds
import SwiftUI

final class RewardedAdManager: NSObject, ObservableObject {
    static let shared = RewardedAdManager()
    
    @Published var isAdReady = false
    private var rewardedAd: RewardedAd?
    private var isLoading = false
    
    // Test ID Rewarded Ad: ca-app-pub-3940256099942544/1712485313
    private let adUnitId = "ca-app-pub-3940256099942544/1712485313"
    
    private override init() {
        super.init()
        loadRewardedAd()
    }
    
    func loadRewardedAd() {
        guard !isLoading else { return }
        isLoading = true
        
        print("[RewardedAd] Starting to load ad...")
        
        let request = Request()
        RewardedAd.load(with: adUnitId, request: request) { [weak self] ad, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    print("[RewardedAd] Failed to load: \(error.localizedDescription)")
                    self.isAdReady = false
                    return
                }
                
                self.rewardedAd = ad
                self.isAdReady = true
                print("[RewardedAd] Loaded successfully")
            }
        }
    }
    
    func showAd(from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        guard let ad = rewardedAd, isAdReady else {
            print("[RewardedAd] No ad available")
            completion(false)
            return
        }
        
        ad.fullScreenContentDelegate = self
        ad.present(from: viewController) { [weak self] in
            // User earned reward
            print("[RewardedAd] User earned reward")
            completion(true)
            
            // Load new ad for next time
            self?.loadRewardedAd()
        }
    }
    
    func reloadAd() {
        loadRewardedAd()
    }
}

// MARK: - FullScreenContentDelegate
extension RewardedAdManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("[RewardedAd] Ad dismissed")
        isAdReady = false
        loadRewardedAd() // Load new ad
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("[RewardedAd] Failed to present: \(error.localizedDescription)")
        isAdReady = false
        loadRewardedAd() // Load new ad
    }
} 