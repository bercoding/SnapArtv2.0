import Foundation

final class ResumeFlowCoordinator {
	private let ads = AdsService.shared
	private let state: AppState
	
	init(state: AppState) {
		self.state = state
	}
	
	func handleActive(showSplash: @escaping () -> Void, afterSplash: @escaping () -> Void) {
		if !state.didHandleInitialActive {
			state.didHandleInitialActive = true
			return
		}
		showSplash()
		DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
			afterSplash()
			self?.ads.presentOpenAd {
				self?.ads.preloadOpenAd()
			}
		}
	}
} 