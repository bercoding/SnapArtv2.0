import SwiftUI
import GoogleMobileAds
import UIKit

// MARK: - BannerAdView (SwiftUI View)
struct BannerAdView: View {
    let adUnitID: String
    @StateObject private var profileManager = UserProfileManager.shared
    
    var body: some View {
        Group {
            if profileManager.currentUser?.stats.premiumStatus == true {
                // Không hiển thị quảng cáo nếu người dùng là Premium
                EmptyView()
            } else {
                GeometryReader { geometry in
                    let adaptiveSize = currentOrientationAnchoredAdaptiveBanner(width: geometry.size.width)
                    
                    VStack {
                        Spacer()
                        GADBannerViewRepresentable(adUnitID: adUnitID, adSize: adaptiveSize)
                            .frame(width: adaptiveSize.size.width,
                                   height: adaptiveSize.size.height)
                        Spacer()
                    }
                    .frame(width: geometry.size.width)
                }
                .frame(height: 75) // Tạm thời set chiều cao tối thiểu
            }
        }
    }
}

// MARK: - GADBannerViewRepresentable (UIViewRepresentable)
struct GADBannerViewRepresentable: UIViewRepresentable {
    let adUnitID: String
    let adSize: AdSize
    
    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: adSize)
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = UIApplication.shared
            .connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?
            .rootViewController
        bannerView.delegate = context.coordinator
        bannerView.load(Request())
        return bannerView
    }
    
    func updateUIView(_ uiView: BannerView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, BannerViewDelegate {
        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            print("[BannerAd] Ad loaded successfully")
        }
        
        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            print("[BannerAd] Failed to load: \(error.localizedDescription)")
        }
    }
}

// MARK: - Preview
struct BannerAdView_Previews: PreviewProvider {
    static var previews: some View {
        BannerAdView(adUnitID: "ca-app-pub-3940256099942544/2934735716")
            .previewLayout(.sizeThatFits)
    }
}
