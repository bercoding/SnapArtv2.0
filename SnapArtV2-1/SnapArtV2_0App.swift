//
//  SnapArtV2_0App.swift
//  SnapArtV2-0
//
//  Created by Le Thanh Nhan on 24/7/25.
//

import SwiftUI
import GoogleMobileAds
import Firebase

@main
struct SnapArtV2_0App: App {
    @StateObject private var appFlowCoordinator = AppFlowCoordinator.shared
    @StateObject private var resumeFlowCoordinator = ResumeFlowCoordinator.shared
    
    init() {
        // Khởi tạo Google Mobile Ads SDK
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        
        // Khởi tạo Firebase
        FirebaseApp.configure()
        
        // Khởi tạo các ad managers
        _ = NativeAdManager.shared
        _ = RewardedAdManager.shared
        _ = InterstitialAdManager.shared
        _ = AppOpenAdManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Main content
                switch appFlowCoordinator.currentFlow {
                case .splash:
                    SplashView()
                        .onAppear {
                            // Splash hiển thị 1.5 giây
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                AppEvents.shared.notifySplashFinished()
                            }
                        }
                    
                case .appOpenAd:
                    Color.clear
                        .onAppear {
                            resumeFlowCoordinator.showAppOpenAdIfAvailable()
                        }
                    
                case .language:
                    LanguageView()
                        .onAppear {
                            // Language chỉ hiển thị 1 lần
                            if !AppState.shared.hasShownLanguageOnce {
                                AppState.shared.setLanguageShownOnce()
                            }
                        }
                        .onDisappear {
                            AppEvents.shared.notifyLanguageFinished()
                        }
                    
                case .onboarding:
                    OnboardingView()
                        .onAppear {
                            // Onboarding chỉ hiển thị 1 lần
                            if !AppState.shared.hasCompletedOnboarding {
                                AppState.shared.setOnboardingCompleted()
                            }
                        }
                        .onDisappear {
                            AppEvents.shared.notifyOnboardingFinished()
                        }
                    
                case .main:
                    ContentView()
                }
            }
            .environmentObject(appFlowCoordinator)
            .environmentObject(resumeFlowCoordinator)
        }
    }
}
