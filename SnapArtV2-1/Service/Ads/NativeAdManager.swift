import Foundation
import GoogleMobileAds
import UIKit

class NativeAdManager: NSObject, ObservableObject {
    static let shared = NativeAdManager()
    
    @Published var nativeAd: NativeAd?
    @Published var isLoading = false
    @Published var isAdLoaded = false
    @Published var lastError: String?
    
    // Sử dụng ID quảng cáo test chính xác cho Native Ad
    private let adUnitID = "ca-app-pub-3940256099942544/3986624511" // Test ID cho Native Ad
    private var loadAttempts = 0
    private var loadTimer: Timer?
    private var adLoader: AdLoader?
    
    private override init() {
        super.init()
        print("[NativeAdManager] Initialized")
        
        // Đợi một chút trước khi tải quảng cáo đầu tiên
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.loadNativeAd()
        }
    }
    
    deinit {
        loadTimer?.invalidate()
    }
    
    func loadNativeAd() {
        // Kiểm tra nếu người dùng là premium thì không tải quảng cáo
        if let currentUser = UserProfileManager.shared.currentUser, 
           currentUser.stats.premiumStatus == true {
            print("[NativeAdManager] User is premium, not loading native ad")
            self.nativeAd = nil
            self.isAdLoaded = false
            return
        }
        
        guard !isLoading else { 
            print("[NativeAdManager] Native ad is already loading - skipping request")
            
            // Kiểm tra xem quảng cáo có bị kẹt quá lâu không
            if loadTimer == nil {
                print("[NativeAdManager] Setting timeout for existing loading state")
                setupLoadingTimeout()
            }
            return 
        }
        
        // Đặt trạng thái và bắt đầu tải
        loadAttempts += 1
        isLoading = true
        lastError = nil
        
        // Thiết lập timeout
        setupLoadingTimeout()
        
        print("[NativeAdManager] Loading native ad (attempt \(loadAttempts)) with ID: \(adUnitID)")
        
        // Tạo options cho native ad
        let multipleAdsOptions = MultipleAdsAdLoaderOptions()
        multipleAdsOptions.numberOfAds = 1
        
        let videoOptions = VideoOptions()
        videoOptions.shouldStartMuted = true
        
        // Đảm bảo rootViewController không nil
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
            print("[NativeAdManager] Error: rootViewController is nil")
            self.isLoading = false
            self.lastError = "rootViewController is nil"
            loadTimer?.invalidate()
            loadTimer = nil
            return
        }
        
        // Tạo mới adLoader
        adLoader = AdLoader(adUnitID: adUnitID,
                          rootViewController: rootViewController,
                          adTypes: [.native],
                          options: [multipleAdsOptions, videoOptions])
        
        adLoader?.delegate = self
        
        // Tạo request với non-personalized ads nếu cần
        let request = Request()
        
        // Bắt đầu tải quảng cáo
        print("[NativeAdManager] Ad request sent")
        adLoader?.load(request)
    }
    
    private func setupLoadingTimeout() {
        // Hủy timer cũ nếu có
        loadTimer?.invalidate()
        
        // Tạo timer mới với timeout 15 giây
        loadTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: false) { [weak self] _ in
            guard let self = self, self.isLoading else { return }
            
            print("[NativeAdManager] Loading timeout after 15 seconds")
            self.isLoading = false
            self.lastError = "Timeout after 15 seconds"
            self.loadTimer = nil
            self.adLoader = nil
            
            // Thử tải lại sau 2 giây
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.loadNativeAd()
            }
        }
    }
    
    // Hàm reset để xóa quảng cáo hiện tại và tải lại
    func resetAndReloadAd() {
        print("[NativeAdManager] Resetting and reloading ad")
        self.nativeAd = nil
        self.isAdLoaded = false
        self.isLoading = false
        loadTimer?.invalidate()
        loadTimer = nil
        adLoader = nil
        loadAttempts = 0
        
        // Đợi một chút trước khi tải lại
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.loadNativeAd()
        }
    }
    
    // Hàm hủy bỏ tất cả các yêu cầu đang chờ xử lý
    func cancelLoading() {
        print("[NativeAdManager] Cancelling all pending ad requests")
        loadTimer?.invalidate()
        loadTimer = nil
        adLoader = nil
        isLoading = false
    }
}

// MARK: - AdLoaderDelegate
extension NativeAdManager: AdLoaderDelegate {
    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        print("[NativeAdManager] Native ad failed to load with error: \(error.localizedDescription)")
        isLoading = false
        isAdLoaded = false
        lastError = error.localizedDescription
        loadTimer?.invalidate()
        loadTimer = nil
        self.adLoader = nil
        
        // Thử tải lại sau một khoảng thời gian tăng dần theo số lần thử
        let retryDelay = min(pow(2.0, Double(loadAttempts)), 30) // Tối đa 30 giây
        print("[NativeAdManager] Will retry in \(retryDelay) seconds")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) { [weak self] in
            guard let self = self else { return }
            if self.nativeAd == nil && !self.isLoading {
                print("[NativeAdManager] Retrying after delay")
                self.loadNativeAd()
            }
        }
    }
}

// MARK: - NativeAdLoaderDelegate
extension NativeAdManager: NativeAdLoaderDelegate {
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        print("[NativeAdManager] Native ad received successfully")
        
        // Hủy timer timeout
        loadTimer?.invalidate()
        loadTimer = nil
        self.adLoader = nil
        
        // Thêm delegate để theo dõi sự kiện click
        nativeAd.delegate = self
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.nativeAd = nativeAd
            self.isLoading = false
            self.isAdLoaded = true
            self.loadAttempts = 0
            print("[NativeAdManager] Native ad loaded and ready to display")
        }
    }
}

// MARK: - NativeAdDelegate
extension NativeAdManager: NativeAdDelegate {
    func nativeAdDidRecordClick(_ nativeAd: NativeAd) {
        print("[NativeAdManager] Native ad was clicked")
    }
    
    func nativeAdDidRecordImpression(_ nativeAd: NativeAd) {
        print("[NativeAdManager] Native ad recorded an impression")
    }
    
    func nativeAdWillPresentScreen(_ nativeAd: NativeAd) {
        print("[NativeAdManager] Native ad will present screen")
    }
    
    func nativeAdDidDismissScreen(_ nativeAd: NativeAd) {
        print("[NativeAdManager] Native ad did dismiss screen")
        // Tải quảng cáo mới sau khi quảng cáo hiện tại đã được tương tác
        self.loadNativeAd()
    }
} 
