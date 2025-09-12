import Foundation
import GoogleMobileAds
import UIKit

class AppOpenAdManager: NSObject, ObservableObject {
    static let shared = AppOpenAdManager()
    
    private var appOpenAd: AppOpenAd?
    private var loadTime: Date?
    @Published var isAdLoaded = false
    
    // Sử dụng ID quảng cáo test chính xác cho App Open Ad
    private let adUnitID = "ca-app-pub-3940256099942544/9257395921" // Test ID cho App Open Ad
    
    // Thời gian tối đa để sử dụng lại quảng cáo đã tải (4 giờ)
    private let adCacheTimeout: TimeInterval = 4 * 3600
    
    private override init() {
        super.init()
        print("AppOpenAdManager initialized")
        loadAppOpenAd() // Tự động tải quảng cáo khi khởi tạo
    }
    
    func loadAppOpenAd() {
        // Kiểm tra nếu người dùng là premium thì không tải quảng cáo
        if let currentUser = UserProfileManager.shared.currentUser, 
           currentUser.stats.premiumStatus == true {
            print("User is premium, not loading app open ad")
            self.appOpenAd = nil
            self.isAdLoaded = false
            return
        }
        
        print("App open ad loading started with ID: \(adUnitID)")
        
        // Sử dụng cú pháp đúng cho AppOpenAd.load
        let request = Request()
        AppOpenAd.load(with: adUnitID, 
                      request: request) { [weak self] ad, error in
            guard let self = self else { return }
            
            if let error = error {
                print("App open ad failed to load with error: \(error.localizedDescription)")
                
                // Thử tải lại sau 30 giây
                DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
                    self?.loadAppOpenAd()
                }
                return
            }
            
            self.appOpenAd = ad
            self.appOpenAd?.fullScreenContentDelegate = self
            self.loadTime = Date()
            self.isAdLoaded = true
            print("App open ad loaded successfully")
        }
    }
    
    func showAppOpenAdIfAvailable() {
        // Kiểm tra nếu người dùng là premium thì không hiển thị quảng cáo
        if let currentUser = UserProfileManager.shared.currentUser, 
           currentUser.stats.premiumStatus == true {
            print("User is premium, not showing app open ad")
            return
        }
        
        // Kiểm tra quảng cáo đã tải và chưa hết hạn
        if let ad = appOpenAd, !isAdExpired() {
            if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
                print("Showing app open ad")
                ad.present(from: rootViewController)
            } else {
                print("No root view controller found")
            }
        } else {
            print("App open ad not ready or expired")
            loadAppOpenAd()
        }
    }
    
    private func isAdExpired() -> Bool {
        guard let loadTime = loadTime else { return true }
        return Date().timeIntervalSince(loadTime) > adCacheTimeout
    }
}

// MARK: - FullScreenContentDelegate
extension AppOpenAdManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("App open ad dismissed")
        loadAppOpenAd() // Tải quảng cáo mới cho lần sau
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("App open ad failed to present with error: \(error.localizedDescription)")
        loadAppOpenAd() // Thử tải lại quảng cáo
    }
} 
