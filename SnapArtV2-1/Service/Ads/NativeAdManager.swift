import Foundation
import GoogleMobileAds
import SwiftUI

final class NativeAdManager: NSObject, ObservableObject {
    static let shared = NativeAdManager()
    
    @Published var nativeAd: NativeAd?
    @Published var isLoading = false
    private var adLoader: AdLoader?
    private var lastLoadTime: Date?
    private let minLoadInterval: TimeInterval = 5.0 // 5 giây giữa các lần load
    
    // Test ID Native Ad: ca-app-pub-3940256099942544/2247696110
    private let adUnitId = "ca-app-pub-3940256099942544/2247696110"
    
    private override init() {
        super.init()
        loadNativeAd()
    }
    
    func loadNativeAd() {
        guard !isLoading else { 
            print("[NativeAd] Already loading, skipping...")
            return 
        }
        
        // Kiểm tra thời gian giữa các lần load
        if let lastLoad = lastLoadTime,
           Date().timeIntervalSince(lastLoad) < minLoadInterval {
            let remainingTime = minLoadInterval - Date().timeIntervalSince(lastLoad)
            print("[NativeAd] Need to wait \(String(format: "%.1f", remainingTime)) seconds before next load")
            return
        }
        
        isLoading = true
        lastLoadTime = Date()
        
        print("[NativeAd] Starting to load ad...")
        print("[NativeAd] Ad Unit ID: \(adUnitId)")
        
        let request = Request()
        let rootVC = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
            .first
        
        print("[NativeAd] Root ViewController: \(rootVC?.description ?? "nil")")
        
        adLoader = AdLoader(adUnitID: adUnitId,
                              rootViewController: rootVC,
                              adTypes: [.native],
                              options: nil)
        adLoader?.delegate = self
        adLoader?.load(request)
        
        print("[NativeAd] AdLoader created and started loading")
    }
    
    func reloadAd() {
        loadNativeAd()
    }
}

// MARK: - NativeAdLoaderDelegate
extension NativeAdManager: NativeAdLoaderDelegate {
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        DispatchQueue.main.async {
            print("[NativeAd] ✅ Ad received successfully!")
            print("[NativeAd] Headline: \(nativeAd.headline ?? "nil")")
            print("[NativeAd] Body: \(nativeAd.body ?? "nil")")
            print("[NativeAd] Call to Action: \(nativeAd.callToAction ?? "nil")")
            
            self.nativeAd = nativeAd
            self.isLoading = false
            print("[NativeAd] Ad loaded and stored in @Published property")
        }
    }
    
    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        DispatchQueue.main.async {
            print("[NativeAd] ❌ Failed to load ad!")
            print("[NativeAd] Error: \(error.localizedDescription)")
            print("[NativeAd] Error domain: \((error as NSError).domain)")
            print("[NativeAd] Error code: \((error as NSError).code)")
            
            self.isLoading = false
        }
    }
} 