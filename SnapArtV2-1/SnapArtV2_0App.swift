//
//  SnapArtV2_0App.swift
//  SnapArtV2-0
//
//  Created by Le Thanh Nhan on 24/7/25.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseDatabase
import GoogleMobileAds
import MediaPipeTasksVision

@main
struct SnapArtV2_0App: App {
    let coreDataManager = CoreDataManager.shared
    
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var onboardingManager = OnboardingManager()
    @StateObject private var galleryViewModel = GalleryViewModel()
    @StateObject private var languageViewModel = LanguageViewModel()
    @StateObject private var purchaseManager = InAppPurchaseManager.shared
    @StateObject private var appState = AppState()
    @StateObject private var appFlow = AppFlowCoordinator(state: AppState())
    private var resumeFlow: ResumeFlowCoordinator { ResumeFlowCoordinator(state: appState) }
    
    @Environment(\.scenePhase) private var scenePhase
    @State private var showOverlaySplash = false
    
    init() {
        // QUAN TRỌNG: Phải khởi tạo Firebase trước, sau đó mới cấu hình Database
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        // Sau khi đã khởi tạo Firebase, mới cấu hình Database
        let db = Database.database()
        db.isPersistenceEnabled = true
        
        // Cấu hình quảng cáo và các thành phần khác
        MobileAds.shared.requestConfiguration.testDeviceIdentifiers = [ "Simulator","Thanh Nhan" ]
        MobileAds.shared.start(completionHandler: nil)
        
        do {
            _ = MediaPipeFaceMeshManager.shared
        } catch {
            // Xử lý lỗi nếu có
        }
        
        // Thiết lập Firebase Realtime Database sau khi Firebase đã được khởi tạo
        setupFirebaseRealtimeDatabase()
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
                    InterstitialAdManager.shared.loadInterstitialAd()
                    
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
    
    // Thiết lập Firebase Realtime Database
    private func setupFirebaseRealtimeDatabase() {
        // Bảo vệ bằng try-catch để tránh crash
        do {
            // Thiết lập cấu trúc ban đầu cho database
            ChatManager.setupInitialDatabaseStructure()
        } catch {
            print("ERROR: Không thể thiết lập Firebase Realtime Database: \(error.localizedDescription)")
        }
    }
}
