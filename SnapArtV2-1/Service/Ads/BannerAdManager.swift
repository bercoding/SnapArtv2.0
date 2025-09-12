import Foundation
import GoogleMobileAds
import SwiftUI

class BannerAdManager: NSObject, ObservableObject {
    static let shared = BannerAdManager()
    
    @Published var bannerView: BannerView?
    @Published var bannerSize: CGSize = .zero
    @Published var isAdLoaded = false
    
    private let adUnitID = "ca-app-pub-3940256099942544/2934735716" // Test ID
    
    override init() {
        super.init()
    }
    
    func loadBannerAd() {
        // Kiểm tra nếu người dùng là premium thì không hiển thị quảng cáo
        if UserProfileManager.shared.currentUser?.stats.premiumStatus == true {
            self.bannerView = nil
            self.isAdLoaded = false
            return
        }
        
        let bannerView = BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = UIApplication.shared.windows.first?.rootViewController
        bannerView.delegate = self
        bannerView.load(Request())
        self.bannerView = bannerView
    }
    
    func removeBannerAd() {
        self.bannerView = nil
        self.isAdLoaded = false
    }
}

// MARK: - BannerViewDelegate
extension BannerAdManager: BannerViewDelegate {
    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        self.bannerSize = bannerView.sizeThatFits(CGSize(width: UIScreen.main.bounds.width, height: 0))
        self.isAdLoaded = true
        print("Banner ad loaded successfully")
    }
    
    func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
        self.isAdLoaded = false
        print("Banner ad failed to load with error: \(error.localizedDescription)")
    }
} 