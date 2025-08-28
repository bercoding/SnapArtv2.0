import SwiftUI

struct BannerAdModifier: ViewModifier {
	let adUnitId: String
	
	init(adUnitId: String = "ca-app-pub-5416045972856349/6224999479") {
		self.adUnitId = adUnitId
	}

	func body(content: Content) -> some View {
		content
			.safeAreaInset(edge: .bottom) {
				VStack(spacing: 0) {
					BannerAdBar(adUnitId: adUnitId)
				}
			}
	}
}

private struct BannerAdBar: View {
	let adUnitId: String
	
	@State private var isRendering: Bool = false
	@State private var isDisplayed: Bool = false
	
	var body: some View {
		ZStack(alignment: .topTrailing) {
			if isRendering {
				BannerAdView(adUnitId: adUnitId) {
					DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
						withAnimation { isDisplayed = true }
					}
				}
				.background(.ultraThinMaterial)
				.clipped()
				.transition(.move(edge: .bottom).combined(with: .opacity))
			}
			if isDisplayed {
				Button(action: { withAnimation { isDisplayed = false } }) {
					Image(systemName: "xmark.circle.fill")
						.font(.title2)
						.foregroundColor(.secondary)
						.padding(8)
				}
			}
		}
		.onAppear {
			// Mỗi lần màn hình refresh/onAppear: render lại ad và đợi 1s sau khi load để hiển thị
			isRendering = true
			isDisplayed = false
		}
	}
}

extension View {
	func withBannerAd(adUnitId: String = "ca-app-pub-5416045972856349/6224999479") -> some View {
		modifier(BannerAdModifier(adUnitId: adUnitId))
	}
}

#Preview {
	Text("Demo")
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.background(Color.white)
		.withBannerAd()
}
