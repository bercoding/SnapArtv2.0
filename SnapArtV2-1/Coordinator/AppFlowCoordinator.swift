import SwiftUI
import Combine

class AppFlowCoordinator: ObservableObject {
    static let shared = AppFlowCoordinator()
    
    @Published var currentFlow: AppFlow = .splash
    @Published var shouldShowAppOpenAd = false
    
    private var cancellables = Set<AnyCancellable>()
    private let appState = AppState.shared
    private let appEvents = AppEvents.shared
    
    private init() {
        setupEventHandlers()
        setupAppStateObserver()
    }
    
    private func setupEventHandlers() {
        // Splash finished -> Show App Open Ad
        appEvents.splashDidFinish
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.showAppOpenAd()
            }
            .store(in: &cancellables)
        
        // App Open Ad finished -> Show Language or Onboarding
        appEvents.appOpenAdDidFinish
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.showNextFlow()
            }
            .store(in: &cancellables)
        
        // Language finished -> Show Onboarding or Main
        appEvents.languageDidFinish
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.showOnboardingOrMain()
            }
            .store(in: &cancellables)
        
        // Onboarding finished -> Show Main
        appEvents.onboardingDidFinish
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.showMain()
            }
            .store(in: &cancellables)
        
        // User login -> Reset to splash
        appEvents.userDidLogin
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.resetToSplash()
            }
            .store(in: &cancellables)
    }
    
    private func setupAppStateObserver() {
        appState.$currentFlow
            .receive(on: DispatchQueue.main)
            .sink { [weak self] flow in
                self?.currentFlow = flow
            }
            .store(in: &cancellables)
    }
    
    private func showAppOpenAd() {
        currentFlow = .appOpenAd
        shouldShowAppOpenAd = true
    }
    
    private func showNextFlow() {
        shouldShowAppOpenAd = false
        
        if !appState.hasShownLanguageOnce {
            currentFlow = .language
        } else if !appState.hasCompletedOnboarding {
            currentFlow = .onboarding
        } else {
            currentFlow = .main
        }
    }
    
    private func showOnboardingOrMain() {
        if !appState.hasCompletedOnboarding {
            currentFlow = .onboarding
        } else {
            currentFlow = .main
        }
    }
    
    private func showMain() {
        currentFlow = .main
    }
    
    private func resetToSplash() {
        currentFlow = .splash
        shouldShowAppOpenAd = false
    }
    
    func resetAppFlow() {
        appState.resetAppFlow()
        resetToSplash()
    }
} 