import Foundation
import Combine

class AppEvents: ObservableObject {
    static let shared = AppEvents()
    
    @Published var splashDidFinish = PassthroughSubject<Void, Never>()
    @Published var appOpenAdDidFinish = PassthroughSubject<Void, Never>()
    @Published var languageDidFinish = PassthroughSubject<Void, Never>()
    @Published var onboardingDidFinish = PassthroughSubject<Void, Never>()
    @Published var userDidLogin = PassthroughSubject<Void, Never>()
    @Published var userDidLogout = PassthroughSubject<Void, Never>()
    
    private init() {}
    
    func notifySplashFinished() {
        splashDidFinish.send()
    }
    
    func notifyAppOpenAdFinished() {
        appOpenAdDidFinish.send()
    }
    
    func notifyLanguageFinished() {
        languageDidFinish.send()
    }
    
    func notifyOnboardingFinished() {
        onboardingDidFinish.send()
    }
    
    func notifyUserLoggedIn() {
        userDidLogin.send()
    }
    
    func notifyUserLoggedOut() {
        userDidLogout.send()
    }
} 