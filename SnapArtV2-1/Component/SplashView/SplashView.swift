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
    
    var body: some View {
        if isActive {
            if onboardingManager.hasCompletedOnboarding {
                ContentView()
                    .environment(\.managedObjectContext, viewContext)
                    .environmentObject(authViewModel)
                    .environmentObject(onboardingManager)
                    .environmentObject(galleryViewModel) 
            } else {
                OnboardingView()
                    .environment(\.managedObjectContext, viewContext)
                    .environmentObject(authViewModel)
                    .environmentObject(onboardingManager)
                    .environmentObject(galleryViewModel)
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
                    
                    Text("SnapArt")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    Text("Tạo ảnh độc đáo với filter AR")
                        .font(.system(size: 18, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.top, 8)
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation {
                        self.isActive = true
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
} 
