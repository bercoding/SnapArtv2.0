import Foundation
import Combine

final class AppEvents {
	static let shared = AppEvents()
	private init() {}
	
	let splashFinished = PassthroughSubject<Void, Never>()
	let userSignedIn = PassthroughSubject<Void, Never>()
} 
