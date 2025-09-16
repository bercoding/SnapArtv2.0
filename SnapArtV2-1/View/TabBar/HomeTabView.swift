import FirebaseCrashlytics
import SwiftUI

// Phiên bản đơn giản hóa của HomePage để sử dụng trong TabView
struct HomeTabView: View {
    @StateObject private var interstitialAdManager = InterstitialAdManager.shared
    @EnvironmentObject private var languageViewModel: LanguageViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var selectedCategory: FilterCategory?
    @State private var selectedFilter: FilterType?
    @State private var showCamera = false
    @State private var navigateToPremium = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient background
                AppTheme.mainGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    header
                    
                    // Category chips
                    CategoryChipsView(selectedCategory: $selectedCategory)
                        .padding(.top, 5)
                    
                    // Filter grid
                    ScrollView {
                        if let cat = selectedCategory {
                            FiltersGrid(category: cat, onSelect: { ft in
                                selectedFilter = ft
                                FilterManager.shared.setFilter(ft)
                                
                                // Hiện Interstitial Ad trước khi mở Camera với callback
                                if UserProfileManager.shared.currentUser?.stats.premiumStatus != true {
                                    print("Attempting to show interstitial ad from HomePage")
                                    interstitialAdManager.showInterstitialAd {
                                        // Mở camera sau khi quảng cáo đóng (hoặc không có quảng cáo)
                                        DispatchQueue.main.async {
                                            showCamera = true
                                        }
                                    }
                                } else {
                                    showCamera = true
                                }
                            })
                        } else {
                            // Sử dụng ZStack để căn giữa hoàn toàn
                            ZStack {
                                VStack(spacing: 20) {
                                    // Thêm khoảng trống để đẩy nội dung xuống giữa màn hình
                                    Spacer()
                                        .frame(height: 80)
                                    
                                    // Biểu tượng thanh trượt
                                    Image(systemName: "slider.horizontal.3")
                                        .font(.system(size: 42, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    // Thông báo
                                    Text(NSLocalizedString("Chọn một danh mục phía trên để xem các filter", comment: "Select category message"))
                                        .font(.callout)
                                        .foregroundColor(.white.opacity(0.8))
                                        .id(languageViewModel.refreshID)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                    
                                    // Thêm khoảng trống bên dưới để cân đối
                                    Spacer()
                                }
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color.white.opacity(0.1))
                                )
                                .padding(.horizontal, 20)
                                .padding(.vertical, 50)
                                .frame(maxHeight: .infinity)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    
                    // Chỉ hiển thị banner ad nếu người dùng không phải là Premium
                    if UserProfileManager.shared.currentUser?.stats.premiumStatus != true {
                        // Bọc banner ad trong một container để đảm bảo nó full chiều ngang
                        ZStack {
                            Color.black.opacity(0.3) // Nền tối cho banner
                            
                            BannerAdView(adUnitID: "ca-app-pub-3940256099942544/2435281174")
                                .frame(height: 50)
                                .padding(.vertical, 5) // Thêm padding dọc để tách khỏi bottom bar
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 60) // Chiều cao cố định cho container
                    }
                }
                .ignoresSafeArea(.all, edges: .top) // Loại bỏ khoảng trắng trên cùng
            }
            .navigationBarHidden(true) // Ẩn thanh điều hướng
            .navigationDestination(isPresented: $navigateToPremium) {
                PremiumView(purchaseManager: InAppPurchaseManager.shared)
                    .environmentObject(InAppPurchaseManager.shared)
                    .navigationBarBackButtonHidden(false)
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraViewControllerRepresentable(isPresented: $showCamera)
            }
        }
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(NSLocalizedString("SnapArt", comment: "App name"))
                    .font(.system(size: 28, weight: .bold, design: .rounded)) // Font lớn và đậm hơn
                    .foregroundColor(.white)
                    .id(languageViewModel.refreshID) // Force reload khi ngôn ngữ thay đổi
                Text(NSLocalizedString("Tạo ảnh vui theo thời gian thực", comment: "App tagline"))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .id(languageViewModel.refreshID) // Force reload khi ngôn ngữ thay đổi
            }
            Spacer()
            
//            // Nút Premium
//            if UserProfileManager.shared.currentUser?.stats.premiumStatus != true {
//                Button {
//                    navigateToPremium = true
//                } label: {
//                    Image(systemName: "crown")
//                        .font(.title2)
//                        .foregroundColor(.yellow)
//                        .padding(8)
//                        .background(Color.white.opacity(0.2))
//                        .clipShape(Circle())
//                }
//                .accessibilityLabel(Text(NSLocalizedString("Premium", comment: "Premium")))
//            }
            
            // Nút Force Crash
            Button {
                Crashlytics.crashlytics().log("Force crash tapped from HomePage header")
                fatalError("Test Crash - Manual trigger")
            } label: {
                Image(systemName: "bolt.trianglebadge.exclamationmark")
                    .font(.title2)
                    .foregroundColor(.yellow)
                    .padding(8)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
            .accessibilityLabel(Text(NSLocalizedString("Test Crash", comment: "Test crash button")))
            
            // Nút đăng xuất
            Button {
                authViewModel.signOut()
            } label: {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
            .accessibilityLabel(Text(NSLocalizedString("Đăng xuất", comment: "Sign out")))
            
            // Nút reset filter - đã di chuyển xuống cuối
//            Button {
//                FilterUnlockManager.shared.resetAllFilters()
//            } label: {
//                Image(systemName: "arrow.counterclockwise")
//                    .font(.title2)
//                    .foregroundColor(.white)
//                    .padding(8)
//                    .background(Color.white.opacity(0.2))
//                    .clipShape(Circle())
//            }
            .accessibilityLabel(Text(NSLocalizedString("Đặt lại bộ lọc", comment: "Reset filters")))
        }
        .padding(.horizontal)
        .padding(.vertical, 8) // Giảm padding dọc
        .padding(.top, UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0) // Thêm padding cho safe area
        .background(.ultraThinMaterial)
        .id(languageViewModel.refreshID) // Force reload khi ngôn ngữ thay đổi
    }
}
