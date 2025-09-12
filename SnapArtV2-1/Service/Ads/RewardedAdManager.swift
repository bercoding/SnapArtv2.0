import Foundation
import GoogleMobileAds
import UIKit

class RewardedAdManager: NSObject, ObservableObject {
    static let shared = RewardedAdManager()
    
    @Published private var rewardedAd: RewardedAd?
    @Published var isLoading = false
    @Published var isAdReady: Bool = false
    private var lastLoadTime: Date?
    private var pendingCompletion: ((Bool) -> Void)?
    
    // Test ID Rewarded: ca-app-pub-3940256099942544/1712485313
    private let adUnitId = "ca-app-pub-3940256099942544/1712485313"
    
    private override init() {
        super.init()
        loadRewardedAd() // Tự động tải quảng cáo khi khởi tạo
    }
    
    func loadRewardedAd() {
        // Kiểm tra nếu người dùng là premium thì không tải quảng cáo
        if let currentUser = UserProfileManager.shared.currentUser, 
           currentUser.stats.premiumStatus == true {
            self.rewardedAd = nil
            self.isAdReady = false
            return
        }
        
        guard !isLoading, shouldLoadNewAd else { return }
        isLoading = true
        
        print("Rewarded ad loading started with ID: \(adUnitId)")
        let request = Request()
        RewardedAd.load(with: adUnitId, request: request) { [weak self] ad, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("[RewardedAd] Failed to load: \(error.localizedDescription)")
                    self.isAdReady = false
                    
                    // Thử tải lại sau 30 giây
                    DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
                        self?.loadRewardedAd()
                    }
                    return
                }
                
                self.rewardedAd = ad
                self.rewardedAd?.fullScreenContentDelegate = self
                self.lastLoadTime = Date()
                self.isAdReady = true
                print("[RewardedAd] Loaded successfully")
            }
        }
    }
    
    func presentAdIfAvailable(from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        // Kiểm tra nếu người dùng là premium thì không hiển thị quảng cáo
        if let currentUser = UserProfileManager.shared.currentUser, 
           currentUser.stats.premiumStatus == true {
            // Nếu là premium, tự động hoàn thành với true
            completion(true)
            return
        }
        
        pendingCompletion = completion
        
        guard let ad = rewardedAd, isAdReady else {
            print("[RewardedAd] Ad not ready, loading new ad")
            loadRewardedAd()
            completion(false)
            return
        }
        
        print("[RewardedAd] Showing ad")
        ad.present(from: viewController) { [weak self] in
            print("[RewardedAd] User earned reward")
            self?.pendingCompletion?(true)
            self?.pendingCompletion = nil
        }
    }
    
    private var shouldLoadNewAd: Bool {
        guard let last = lastLoadTime else { return true }
        return Date().timeIntervalSince(last) > 4 * 60
    }
}

extension RewardedAdManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("[RewardedAd] Dismissed")
        DispatchQueue.main.async {
            self.rewardedAd = nil
            self.isAdReady = false
        }
        loadRewardedAd()
        // Nếu người dùng đóng quảng cáo trước khi nhận phần thưởng, completion sẽ được gọi với false
        if pendingCompletion != nil {
            pendingCompletion?(false)
            pendingCompletion = nil
        }
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("[RewardedAd] Present failed: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.rewardedAd = nil
            self.isAdReady = false
        }
        loadRewardedAd()
        pendingCompletion?(false)
        pendingCompletion = nil
    }
} 
