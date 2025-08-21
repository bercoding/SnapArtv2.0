import SwiftUI

class OnboardingManager: ObservableObject {
    // Key để lưu trạng thái trong UserDefaults
    private let hasCompletedOnboardingKey = "hasCompletedOnboarding"
    
    // Trạng thái đã hoàn thành onboarding
    @Published var hasCompletedOnboarding: Bool = false {
        didSet {
            // Lưu trạng thái khi thay đổi
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: hasCompletedOnboardingKey)
        }
    }
    
    public init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: hasCompletedOnboardingKey)
    }
    
    // Đánh dấu đã hoàn thành onboarding
    func completeOnboarding() {
        hasCompletedOnboarding = true
    }
} 
