import SwiftUI

class OnboardingManager: ObservableObject {
    private let hasCompletedOnboardingKey = "hasCompletedOnboarding"

    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: hasCompletedOnboardingKey)
        }
    }

    public init() {

        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: hasCompletedOnboardingKey)
    }

    // Đánh dấu đã hoàn thành onboarding (chỉ có tác dụng trong phiên hiện tại)
    func completeOnboarding() {
        hasCompletedOnboarding = true
    }
}
