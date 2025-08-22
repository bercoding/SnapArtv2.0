import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var showLanguageSettings = false
    @EnvironmentObject var onboardingManager: OnboardingManager
    @EnvironmentObject var languageViewModel: LanguageViewModel
    
    // Dữ liệu cho các trang onboarding (computed để cập nhật theo .locale)
    private var pages: [OnboardingPage] {
        [
            OnboardingPage(
                image: "onboarding1",
                systemImage: "camera.filters",
                title: "Chào mừng đến với SnapArt",
                description: "Ứng dụng chỉnh sửa ảnh với các bộ lọc khuôn mặt thú vị và độc đáo"
            ),
            OnboardingPage(
                image: "onboarding2",
                systemImage: "face.smiling",
                title: "Bộ lọc khuôn mặt AR",
                description: "Trải nghiệm các bộ lọc khuôn mặt thời gian thực với công nghệ MediaPipe"
            ),
            OnboardingPage(
                image: "onboarding3",
                systemImage: "photo.on.rectangle",
                title: "Lưu trữ và chia sẻ",
                description: "Lưu ảnh của bạn vào thư viện và chia sẻ với bạn bè"
            ),
            OnboardingPage(
                image: "onboarding4",
                systemImage: "person.crop.circle.badge.checkmark",
                title: "Tài khoản cá nhân",
                description: "Đăng nhập để lưu trữ ảnh của bạn trên đám mây và đồng bộ giữa các thiết bị"
            )
        ]
    }
    
    var body: some View {
        ZStack {
            // Nền gradient cục bộ (không phụ thuộc AppTheme)
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0.62, green: 0.59, blue: 0.98), Color(red: 0.82, green: 0.75, blue: 0.98)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Content
            VStack {
                TabView(selection: $currentPage) { // Lướt giữa các trang
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .environmentObject(languageViewModel)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                .transition(.slide)
                
                // Page indicator
                HStack(spacing: 12) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.white : Color.white.opacity(0.4))
                            .frame(width: 8, height: 8)
                            .scaleEffect(currentPage == index ? 1.2 : 1)
                            .animation(.spring(), value: currentPage)
                    }
                }
                .padding(.top, 20)
                
                // Button - Primary
                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation { currentPage += 1 }
                    } else {
                        withAnimation { 
                            showLanguageSettings = true
                        }
                    }
                }) {
                    Text(currentPage < pages.count - 1 ? "Tiếp theo" : "Bắt đầu")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                        .id(languageViewModel.refreshID) // Force reload khi ngôn ngữ thay đổi
                }
                .padding(.bottom, 20)
                
                // Skip button
                if currentPage < pages.count - 1 {
                    Button("Bỏ qua") {
                        withAnimation { 
                            showLanguageSettings = true
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .opacity(0.9)
                    .padding(.bottom, 20)
                    .id(languageViewModel.refreshID) // Force reload khi ngôn ngữ thay đổi
                }
            }
            .padding(.bottom, 30)
        }
        .sheet(isPresented: $showLanguageSettings) {
            LanguageView()
                .environmentObject(languageViewModel)
                .onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { _ in
                    // Khi ngôn ngữ thay đổi, đóng sheet và hoàn thành onboarding
                    showLanguageSettings = false
                    onboardingManager.completeOnboarding()
                }
        }
    }
}

// Struct để lưu trữ thông tin cho mỗi trang onboarding
struct OnboardingPage {
    let image: String
    let systemImage: String
    let title: LocalizedStringKey
    let description: LocalizedStringKey
}

// View cho mỗi trang onboarding
struct OnboardingPageView: View {	
    let page: OnboardingPage
    @State private var useSystemImage: Bool = false
    @EnvironmentObject private var languageViewModel: LanguageViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Image
            Group {
                if useSystemImage {
                    Image(systemName: page.systemImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 180)
                        .foregroundColor(.white)
                } else {
                    Image(page.image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 220, height: 220)
                        .onAppear {
                            // Kiểm tra xem hình ảnh có tồn tại không
                            if UIImage(named: page.image) == nil { useSystemImage = true }
                        }
                }
            }
            .padding(.bottom, 20)
            
            // Title
            Text(page.title)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .id(languageViewModel.refreshID)
            
            // Description
            Text(page.description)
                .font(.system(size: 18))
                .foregroundColor(Color.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .id(languageViewModel.refreshID)
            
            Spacer()
            Spacer()
        }
        .padding()
    }
}

#Preview {
    OnboardingView()
        .environmentObject(OnboardingManager())
        .environmentObject(LanguageViewModel())
} 
