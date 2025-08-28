import Foundation
import GoogleMobileAds
import UIKit

class AppOpenAdManager: NSObject, ObservableObject {
    static let shared = AppOpenAdManager()
    
    @Published var isAdAvailable = false
    private var appOpenAd: AppOpenAd?
    private var loadTime: Date?
    
    // Test ID App Open Ad
    private let adUnitId = "ca-app-pub-3940256099942544/5662855259"
    
    private override init() {
        super.init()
        loadAdIfNeeded()
    }
    
    func loadAdIfNeeded() {
        // Kiểm tra xem ad có cần load lại không
        if wasLoadTimeLessThanNHoursAgo(4) && appOpenAd != nil {
            return
        }
        
        // Load ad mới
        let request = Request()
        AppOpenAd.load(with: adUnitId, request: request) { [weak self] ad, error in
            if let error = error {
                print("Failed to load app open ad: \(error.localizedDescription)")
                return
            }
            
            self?.appOpenAd = ad
            self?.loadTime = Date()
            self?.isAdAvailable = true
            print("App open ad loaded successfully")
        }
    }
    
    func presentAdIfAvailable(from viewController: UIViewController, completion: @escaping () -> Void) {
        guard let appOpenAd = appOpenAd else {
            print("App open ad not available")
            completion()
            return
        }
        
        appOpenAd.fullScreenContentDelegate = self
        appOpenAd.present(from: viewController)
        
        // Reset ad sau khi present
        self.appOpenAd = nil
        self.isAdAvailable = false
        
        completion()
    }
    
    private func wasLoadTimeLessThanNHoursAgo(_ n: Int) -> Bool {
        guard let loadTime = loadTime else { return false }
        let timeIntervalBetweenNowAndLoad = Date().timeIntervalSince(loadTime)
        let intervalInSeconds = TimeInterval(n * 3600)
        return timeIntervalBetweenNowAndLoad < intervalInSeconds
    }
}

// MARK: - FullScreenContentDelegate
extension AppOpenAdManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("App open ad dismissed")
        loadAdIfNeeded()
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("App open ad failed to present with error: \(error.localizedDescription)")
        loadAdIfNeeded()
    }
} 