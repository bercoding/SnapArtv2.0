import SwiftUI
import GoogleMobileAds
import UIKit

struct NativeAdViewContainer: View {
    @StateObject private var adManager = NativeAdManager.shared
    @StateObject private var profileManager = UserProfileManager.shared
    @State private var retryCount = 0
    @State private var showDebugInfo = false
    
    var body: some View {
        Group {
            if profileManager.currentUser?.stats.premiumStatus == true {
                // Không hiển thị quảng cáo nếu người dùng là Premium
                EmptyView()
                    .frame(height: 0)
            } else {
                VStack {
                    if let nativeAd = adManager.nativeAd {
                        NativeAdViewRepresentable(nativeAd: nativeAd)
                            .frame(height: 200) // Giảm chiều cao từ 300 xuống 200
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    } else {
                        adLoadingView
                    }
                }
                .onAppear {
                    print("[NativeAdViewContainer] appeared")
                    if !adManager.isLoading && adManager.nativeAd == nil {
                        adManager.loadNativeAd()
                    }
                }
            }
        }
    }
    
    private var adLoadingView: some View {
        VStack(spacing: 10) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            
            Text("Đang tải quảng cáo...")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if showDebugInfo {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Trạng thái: \(adManager.isLoading ? "Đang tải" : "Chưa tải")")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if let error = adManager.lastError {
                        Text("Lỗi: \(error)")
                            .font(.caption)
                            .foregroundColor(.red)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.vertical, 4)
                
                Button("Tải lại quảng cáo") {
                    retryCount += 1
                    print("[NativeAdViewContainer] Manual reload - attempt \(retryCount)")
                    adManager.resetAndReloadAd()
                }
                .font(.caption)
                .padding(6)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(8)
            }
        }
        .padding()
        .frame(height: 80) // Giảm chiều cao từ 120 xuống 80
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground).opacity(0.8))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .onTapGesture(count: 3) {
            showDebugInfo.toggle()
            print("[NativeAdViewContainer] Debug mode: \(showDebugInfo)")
            
            if showDebugInfo {
                // In thông tin debug khi bật chế độ debug
                print("[NativeAdViewContainer] Ad loaded: \(adManager.isAdLoaded)")
                print("[NativeAdViewContainer] Is loading: \(adManager.isLoading)")
                print("[NativeAdViewContainer] Last error: \(adManager.lastError ?? "None")")
            }
        }
        .onAppear {
            // Thử tải lại quảng cáo sau 5 giây nếu vẫn chưa có
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                if adManager.nativeAd == nil && !adManager.isLoading {
                    print("[NativeAdViewContainer] Auto retry after 5s")
                    adManager.loadNativeAd()
                }
            }
        }
    }
}

struct NativeAdViewRepresentable: UIViewRepresentable {
    let nativeAd: NativeAd

    func makeUIView(context: Context) -> GoogleNativeAdView {
        let nativeAdView = GoogleNativeAdView()
        nativeAdView.backgroundColor = UIColor.secondarySystemBackground
        nativeAdView.layer.cornerRadius = 12
        
        // Create and add UI components
        let headlineLabel = UILabel()
        headlineLabel.font = .boldSystemFont(ofSize: 15) // Giảm kích thước font
        headlineLabel.numberOfLines = 2
        nativeAdView.addSubview(headlineLabel)
        nativeAdView.headlineView = headlineLabel
        
        // Ad indicator
        let adIndicator = UILabel()
        adIndicator.text = "Quảng cáo"
        adIndicator.font = .systemFont(ofSize: 9, weight: .medium) // Giảm kích thước font
        adIndicator.textColor = .white
        adIndicator.backgroundColor = UIColor(red: 0, green: 0.5, blue: 0.8, alpha: 1.0)
        adIndicator.textAlignment = .center
        adIndicator.layer.cornerRadius = 4
        adIndicator.layer.masksToBounds = true
        nativeAdView.addSubview(adIndicator)

        let bodyLabel = UILabel()
        bodyLabel.font = .systemFont(ofSize: 12) // Giảm kích thước font
        bodyLabel.numberOfLines = 2 // Giảm số dòng từ 3 xuống 2
        nativeAdView.addSubview(bodyLabel)
        nativeAdView.bodyView = bodyLabel

        let mediaView = MediaView()
        nativeAdView.addSubview(mediaView)
        nativeAdView.mediaView = mediaView
        
        let callToActionButton = UIButton()
        callToActionButton.setTitleColor(.white, for: .normal)
        callToActionButton.backgroundColor = .systemBlue
        callToActionButton.layer.cornerRadius = 8
        callToActionButton.titleLabel?.font = .boldSystemFont(ofSize: 14) // Giảm kích thước font
        nativeAdView.addSubview(callToActionButton)
        nativeAdView.callToActionView = callToActionButton

        // Set up constraints
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        adIndicator.translatesAutoresizingMaskIntoConstraints = false
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        mediaView.translatesAutoresizingMaskIntoConstraints = false
        callToActionButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Ad indicator
            adIndicator.topAnchor.constraint(equalTo: nativeAdView.topAnchor, constant: 8),
            adIndicator.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: 12),
            adIndicator.widthAnchor.constraint(equalToConstant: 50), // Giảm chiều rộng
            adIndicator.heightAnchor.constraint(equalToConstant: 18), // Giảm chiều cao
            
            // Headline
            headlineLabel.topAnchor.constraint(equalTo: adIndicator.bottomAnchor, constant: 4), // Giảm khoảng cách
            headlineLabel.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: 12), // Giảm padding
            headlineLabel.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -12), // Giảm padding
            
            // Media view
            mediaView.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor, constant: 8), // Giảm khoảng cách
            mediaView.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: 12), // Giảm padding
            mediaView.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -12), // Giảm padding
            mediaView.heightAnchor.constraint(equalToConstant: 100), // Giảm chiều cao từ 150 xuống 100
            
            // Body
            bodyLabel.topAnchor.constraint(equalTo: mediaView.bottomAnchor, constant: 8), // Giảm khoảng cách
            bodyLabel.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: 12), // Giảm padding
            bodyLabel.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -12), // Giảm padding
            
            // Call to action button
            callToActionButton.topAnchor.constraint(greaterThanOrEqualTo: bodyLabel.bottomAnchor, constant: 8), // Giảm khoảng cách
            callToActionButton.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: 12), // Giảm padding
            callToActionButton.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -12), // Giảm padding
            callToActionButton.bottomAnchor.constraint(equalTo: nativeAdView.bottomAnchor, constant: -8), // Giảm padding
            callToActionButton.heightAnchor.constraint(equalToConstant: 36) // Giảm chiều cao từ 44 xuống 36
        ])

        return nativeAdView
    }

    func updateUIView(_ uiView: GoogleNativeAdView, context: Context) {
        (uiView.headlineView as? UILabel)?.text = nativeAd.headline
        uiView.mediaView?.mediaContent = nativeAd.mediaContent
        (uiView.bodyView as? UILabel)?.text = nativeAd.body
        (uiView.callToActionView as? UIButton)?.setTitle(nativeAd.callToAction, for: .normal)
        
        uiView.callToActionView?.isHidden = nativeAd.callToAction == nil
        
        uiView.nativeAd = nativeAd
    }
}

// Đổi tên để tránh xung đột với NativeAdView từ GoogleMobileAds
typealias GoogleNativeAdView = NativeAdView

struct NativeAdViewContainer_Previews: PreviewProvider {
    static var previews: some View {
        NativeAdViewContainer()
            .padding()
    }
} 
