import SwiftUI
import Combine

final class AppFlowCoordinator: ObservableObject {
	private let ads = AdsService.shared
	private let events = AppEvents.shared
	private let state: AppState
	
	private var cancellables = Set<AnyCancellable>()
	
	@Published var showLanguage = false
	
	init(state: AppState) {
		self.state = state
		bind()
	}
	
	private func bind() {
		events.splashFinished
			.receive(on: DispatchQueue.main)
			.sink { [weak self] in self?.afterSplash() }
			.store(in: &cancellables)
	}
	
	private func afterSplash() {
		ads.presentOpenAd { [weak self] in
			guard let self else { return }
			if !self.state.hasShownLanguageOnce {
				self.showLanguage = true
				self.state.hasShownLanguageOnce = true
			}
			self.ads.preloadOpenAd()
		}
	}
} 