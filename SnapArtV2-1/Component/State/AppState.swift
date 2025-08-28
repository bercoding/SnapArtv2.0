import Foundation
import Combine

final class AppState: ObservableObject {
	private let hasShownLanguageKey = "hasShownLanguageOnce"
	
	@Published var hasShownLanguageOnce: Bool {
		didSet { UserDefaults.standard.set(hasShownLanguageOnce, forKey: hasShownLanguageKey) }
	}
	
	@Published var didHandleInitialActive: Bool = false
	
	init() {
		hasShownLanguageOnce = UserDefaults.standard.bool(forKey: hasShownLanguageKey)
	}
} 
