import Foundation
import SwiftUI

class AppState: ObservableObject {
    static let shared = AppState()
    
    @Published var currentFlow: AppFlow = .splash
    @Published var hasCompletedOnboarding: Bool = false
    @Published var hasShownLanguageOnce: Bool = false
    
    private init() {
        loadUserDefaults()
    }
    
    private func loadUserDefaults() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        hasShownLanguageOnce = UserDefaults.standard.bool(forKey: "hasShownLanguageOnce")
    }
    
    func setOnboardingCompleted() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
    
    func setLanguageShownOnce() {
        hasShownLanguageOnce = true
        UserDefaults.standard.set(true, forKey: "hasShownLanguageOnce")
    }
    
    func resetAppFlow() {
        currentFlow = .splash
    }
}

enum AppFlow {
    case splash
    case language
    case onboarding
    case main
} 