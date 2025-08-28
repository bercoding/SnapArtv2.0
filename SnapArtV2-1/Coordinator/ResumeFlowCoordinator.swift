import SwiftUI
import Combine

class ResumeFlowCoordinator: ObservableObject {
    static let shared = ResumeFlowCoordinator()
    
    private var cancellables = Set<AnyCancellable>()
    private let appState = AppState.shared
    private let appEvents = AppEvents.shared
    private let appOpenAdManager = AppOpenAdManager.shared
    
    private init() {
        setupAppResumeHandler()
    }
    
    private func setupAppResumeHandler() {
        // Khi app resume, hiển thị splash và app open ad
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleAppResume()
            }
            .store(in: &cancellables)
    }
    
    private func handleAppResume() {
        // Reset về splash khi app resume
        appState.resetAppFlow()
        
        // Hiển thị splash trong 1.5 giây
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.appEvents.notifySplashFinished()
        }
    }
    
    func showAppOpenAdIfAvailable() {
        guard appOpenAdManager.isAdAvailable else {
            appEvents.notifyAppOpenAdFinished()
            return
        }
        
        // Lấy root view controller để hiển thị app open ad
        let rootVC = getRootViewController()
        
        if let rootVC = rootVC {
            appOpenAdManager.presentAdIfAvailable(from: rootVC) { [weak self] in
                self?.appEvents.notifyAppOpenAdFinished()
            }
        } else {
            appEvents.notifyAppOpenAdFinished()
        }
    }
    
    private func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return nil
        }
        return window.rootViewController
    }
} 