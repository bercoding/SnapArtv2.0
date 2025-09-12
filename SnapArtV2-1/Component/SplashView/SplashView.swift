import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @State private var size = 0.8
    @State private var opacity = 0.5
    @State private var rotation: Double = 0
    
    // Nhận các environment objects
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var onboardingManager: OnboardingManager // Thay đổi thành EnvironmentObject
    @EnvironmentObject var galleryViewModel: GalleryViewModel // Thêm GalleryViewModel
    @EnvironmentObject var languageViewModel: LanguageViewModel // Thêm LanguageViewModel
    
    var body: some View {
        if isActive {
            if onboardingManager.hasCompletedOnboarding {
                ContentView()
                    .environment(\.managedObjectContext, viewContext)
                    .environmentObject(authViewModel)
                    .environmentObject(onboardingManager)
                    .environmentObject(galleryViewModel)
                    .environmentObject(languageViewModel)
            } else {
                OnboardingView()
                    .environment(\.managedObjectContext, viewContext)
                    .environmentObject(authViewModel)
                    .environmentObject(onboardingManager)
                    .environmentObject(galleryViewModel)
                    .environmentObject(languageViewModel)
            }
        } else {
            ZStack {
                // Sử dụng gradient từ AppTheme
                AppTheme.mainGradient
                    .ignoresSafeArea()
                
                VStack {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 4)
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .trim(from: 0, to: 0.7)
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 120, height: 120)
                            .rotationEffect(Angle(degrees: rotation))
                            .onAppear {
                                withAnimation(Animation.linear(duration: 1).repeatForever(autoreverses: false)) {
                                    self.rotation = 360
                                }
                            }
                        
                        Image(systemName: "camera.filters")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.white)
                    }
                    
                    Text(NSLocalizedString("SnapArt", comment: "App name"))
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                        .id(languageViewModel.refreshID) // Force reload khi ngôn ngữ thay đổi
                    
                    Text(NSLocalizedString("Tạo ảnh độc đáo với filter AR", comment: "Create unique photos with AR filters"))
                        .font(.system(size: 18, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.top, 8)
                        .id(languageViewModel.refreshID) // Force reload khi ngôn ngữ thay đổi
                }
                .scaleEffect(size)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.easeIn(duration: 1.2)) {
                        self.size = 1.0
                        self.opacity = 1.0
                    }
                }
            }
            .onAppear {
                // Preload App Open Ad trong lúc hiển thị splash
                AppOpenAdManager.shared.loadAppOpenAd()
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        self.isActive = true
                    }
                    // Gọi Open App Ad ngay sau Splash (trễ 0.2s cho an toàn chuyển view)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        if UserProfileManager.shared.currentUser?.stats.premiumStatus != true {
                            print("Attempting to show app open ad from SplashView")
                            AppOpenAdManager.shared.showAppOpenAdIfAvailable()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    SplashView()
        .environmentObject(AuthViewModel())
        .environmentObject(OnboardingManager())
        .environmentObject(GalleryViewModel())
        .environmentObject(LanguageViewModel())
} 
