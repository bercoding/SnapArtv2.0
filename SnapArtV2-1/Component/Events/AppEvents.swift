import Foundation
import Combine

final class AppEvents {
	static let shared = AppEvents()
	private init() {}
	
	let splashFinished = PassthroughSubject<Void, Never>()
	let userSignedIn = PassthroughSubject<Void, Never>()
}

extension Notification.Name {
    // Chỉ giữ lại khai báo không trùng với Notification+Extensions.swift
    static let premiumStatusChanged = Notification.Name("premiumStatusChanged")
} 
