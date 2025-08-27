import SwiftUI
import GoogleMobileAds

struct NativeAdView: View {
    let nativeAd: NativeAd
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header với icon và title
            HStack(spacing: 8) {
                if let icon = nativeAd.icon?.image {
                    Image(uiImage: icon)
                        .resizable()
                        .frame(width: 32, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    if let headline = nativeAd.headline {
                        Text(headline)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    
                    if let advertiser = nativeAd.advertiser {
                        Text(advertiser)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Ad indicator
                Text("Ad")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            
            // Body content
            if let body = nativeAd.body {
                Text(body)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(3)
            }
            
            // Call to action button
            if let callToAction = nativeAd.callToAction {
                Button(action: {
                    // Ad sẽ tự động xử lý khi tap
                }) {
                    Text(callToAction)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
} 