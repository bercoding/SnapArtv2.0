import Foundation
import GoogleMobileAds
import UIKit

class InterstitialAdManager: NSObject, ObservableObject {
    static let shared = InterstitialAdManager()
    
    private var interstitialAd: InterstitialAd?
    // Sử dụng ID quảng cáo test chính xác cho Interstitial Ad
    private let adUnitID = "ca-app-pub-3940256099942544/4411468910" // Test ID cho Interstitial Ad
    
    @Published var isAdLoaded = false
    
    // Callback để thông báo khi quảng cáo đóng
    private var adDismissCallback: (() -> Void)?
    
    override init() {
        super.init()
        print("InterstitialAdManager initialized")
        loadInterstitialAd()
    }
    
    func loadInterstitialAd() {
        // Kiểm tra nếu người dùng là premium thì không tải quảng cáo
        if let currentUser = UserProfileManager.shared.currentUser, 
           currentUser.stats.premiumStatus == true {
            print("User is premium, not loading interstitial ad")
            self.interstitialAd = nil
            self.isAdLoaded = false
            return
        }
        
        print("Interstitial ad loading started with ID: \(adUnitID)")
        
        // Sử dụng cú pháp đúng cho InterstitialAd.load
        let request = Request()
        InterstitialAd.load(with: adUnitID, 
                          request: request) { [weak self] ad, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Failed to load interstitial ad with error: \(error.localizedDescription)")
                self.isAdLoaded = false
                
                // Thử tải lại sau 30 giây
                DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
                    self?.loadInterstitialAd()
                }
                return
            }
            
            self.interstitialAd = ad
            self.interstitialAd?.fullScreenContentDelegate = self
            self.isAdLoaded = true
            print("Interstitial ad loaded successfully")
        }
    }
    
    func showInterstitialAd(completion: @escaping () -> Void) {
        // Lưu callback để gọi khi quảng cáo đóng
        adDismissCallback = completion
        
        // Kiểm tra nếu người dùng là premium thì không hiển thị quảng cáo
        if let currentUser = UserProfileManager.shared.currentUser, 
           currentUser.stats.premiumStatus == true {
            print("User is premium, not showing interstitial ad")
            completion()
            return
        }
        
        if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
            if let ad = interstitialAd {
                print("Showing interstitial ad")
                ad.present(from: rootViewController)
            } else {
                print("Interstitial ad wasn't ready, loading new ad")
                loadInterstitialAd()
                // Nếu quảng cáo không sẵn sàng, gọi callback ngay lập tức
                completion()
            }
        } else {
            print("No root view controller found")
            completion()
        }
    }
    
    // Hàm cũ để tương thích ngược
    func showInterstitialAd() {
        showInterstitialAd(completion: {})
    }
}

// MARK: - FullScreenContentDelegate
extension InterstitialAdManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("Interstitial ad dismissed")
        loadInterstitialAd()
        
        // Gọi callback khi quảng cáo đóng
        adDismissCallback?()
        adDismissCallback = nil
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Interstitial ad failed to present with error: \(error.localizedDescription)")
        loadInterstitialAd()
        
        // Gọi callback khi quảng cáo lỗi
        adDismissCallback?()
        adDismissCallback = nil
    }
}
