//
//  SnapArtV2_0App.swift
//  SnapArtV2-0
//
//  Created by Le Thanh Nhan on 24/7/25.
//

import SwiftUI
import FirebaseCore
import MediaPipeTasksVision
import GoogleMobileAds

@main
struct SnapArtV2_0App: App {
    let coreDataManager = CoreDataManager.shared
    
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var onboardingManager = OnboardingManager()
    @StateObject private var galleryViewModel = GalleryViewModel()
    @StateObject private var languageViewModel = LanguageViewModel()
    @StateObject private var purchaseManager = InAppPurchaseManager.shared
    
    // New app-level state and coordinators
    @StateObject private var appState = AppState()
    @StateObject private var appFlow = AppFlowCoordinator(state: AppState())
    private var resumeFlow: ResumeFlowCoordinator { ResumeFlowCoordinator(state: appState) }
    
    @Environment(\.scenePhase) private var scenePhase
    @State private var showOverlaySplash = false
    
    init() {
        MobileAds.shared.requestConfiguration.testDeviceIdentifiers = [ "Simulator" ]
        MobileAds.shared.start(completionHandler: nil)
        if FirebaseApp.app() == nil { FirebaseApp.configure() }
        do { _ = MediaPipeFaceMeshManager.shared } catch { print(error.localizedDescription) }
    }

    var body: some Scene {
        WindowGroup {
            SplashView()
                .environment(\.managedObjectContext, coreDataManager.persistentContainer.viewContext)
                .environmentObject(authViewModel)
                .environmentObject(onboardingManager)
                .environmentObject(galleryViewModel)
                .environmentObject(languageViewModel)
                .environmentObject(purchaseManager)
                .environment(\.locale, Locale(identifier: languageViewModel.selectedCode))
                .onAppear {
                    Task { await purchaseManager.restoreOnAppLaunch() }
                    // Preload Interstitial Ad
                    InterstitialAdManager.shared.loadAd()
                    
                    // Khởi tạo Native Ad
                    _ = NativeAdManager.shared
                    
                    // Khởi tạo Rewarded Ad
                    _ = RewardedAdManager.shared
                }
                .sheet(isPresented: $appFlow.showLanguage) {
                    LanguageView().environmentObject(languageViewModel)
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                resumeFlow.handleActive(
                    showSplash: { showOverlaySplash = true },
                    afterSplash: { showOverlaySplash = false }
                )
            }
        }
    }
}
