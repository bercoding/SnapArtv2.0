import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {
    let adUnitId: String
    let onAdLoaded: (() -> Void)?
    
    init(adUnitId: String, onAdLoaded: (() -> Void)? = nil) {
        self.adUnitId = adUnitId
        self.onAdLoaded = onAdLoaded
    }
    
    func makeUIView(context: Context) -> GADBannerView {
        let bannerView = GADBannerView()
        bannerView.adUnitID = adUnitId
        bannerView.rootViewController = UIApplication.shared.windows.first?.rootViewController
        bannerView.delegate = context.coordinator
        
        // Sử dụng kích thước banner thích ứng
        let frame = UIScreen.main.bounds
        let viewWidth = frame.size.width
        bannerView.adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(viewWidth)
        
        return bannerView
    }
    
    func updateUIView(_ uiView: GADBannerView, context: Context) {
        // Load quảng cáo khi view được cập nhật
        let request = GADRequest()
        uiView.load(request)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, GADBannerViewDelegate {
        let parent: BannerAdView
        
        init(_ parent: BannerAdView) {
            self.parent = parent
        }
        
        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            print("Banner ad loaded successfully")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.parent.onAdLoaded?()
            }
        }
        
        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
            print("Banner ad failed to load with error: \(error.localizedDescription)")
        }
    }
} 