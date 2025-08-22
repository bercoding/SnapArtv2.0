import SwiftUI

struct HomePage: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var languageViewModel: LanguageViewModel
    @State private var path = NavigationPath()
    @State private var selectedCategory: FilterCategory? = nil
    @State private var showCamera = false
    @State private var selectedFilter: FilterType? = nil
    @State private var showLanguageSettings = false
    @State private var showPremium = false
    
    var body: some View {
        ZStack {
            // Thêm background gradient từ AppTheme
            AppTheme.mainGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header + Category chips (điều hướng sang màn category)
                header
                CategoryChipsView(selectedCategory: $selectedCategory)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                Group {
                    if let cat = selectedCategory {
                        FiltersGrid(category: cat, onSelect: { ft in
                            selectedFilter = ft
                            FilterManager.shared.setFilter(ft)
                            showCamera = true
                        })
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 42, weight: .semibold))
                                .foregroundColor(.white)
                            Text(NSLocalizedString("Chọn một danh mục phía trên để xem các filter", comment: "Select category message"))
                                .font(.callout)
                                .foregroundColor(.white.opacity(0.8))
                                .id(languageViewModel.refreshID) // Force reload khi ngôn ngữ thay đổi
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white.opacity(0.1)) // Nền mờ cho trạng thái rỗng
                                .padding() // Đệm cho hình chữ nhật
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.clear)

                // Thanh điều hướng dưới cùng
                bottomBar
            }
        }
        .navigationBarBackButtonHidden(true)
        .fullScreenCover(isPresented: $showCamera) {
            CameraViewControllerRepresentable(isPresented: $showCamera)
        }
        .sheet(isPresented: $showLanguageSettings) {
            LanguageView()
                .environmentObject(languageViewModel)
                .onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { _ in
                    // Khi ngôn ngữ thay đổi, đóng sheet
                    showLanguageSettings = false
                }
        }
        .sheet(isPresented: $showPremium) {
            PremiumView()
                .environmentObject(InAppPurchaseManager.shared)
        }
        .id(languageViewModel.refreshID) // Force reload toàn bộ view khi ngôn ngữ thay đổi
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
            
//             Nút Premium
            Button {
                showPremium = true
            } label: {
                Image(systemName: "crown.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                    .padding(8)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
            
            // Nút chọn ngôn ngữ
            Button {
                showLanguageSettings = true
            } label: {
                Image(systemName: "globe")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
            
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
        }
        .padding(.horizontal)
        .padding(.vertical, 10) // Điều chỉnh padding
        .background(.ultraThinMaterial)
        .id(languageViewModel.refreshID) // Force reload khi ngôn ngữ thay đổi
    }
    
    private var bottomBar: some View {
        HStack(spacing: 16) {
            NavigationLink {
                HomePage()
                    .id(languageViewModel.refreshID)
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "photo.on.rectangle")
                        .foregroundColor(.white)
                    Text(NSLocalizedString("Thư viện ảnh", comment: "Gallery"))
                        .font(.caption)
                        .foregroundColor(.white)
                        .id(languageViewModel.refreshID) // Force reload khi ngôn ngữ thay đổi
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            NavigationLink {
                GalleryView()
                    .id(languageViewModel.refreshID)
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "photo.on.rectangle")
                        .foregroundColor(.white)
                    Text(NSLocalizedString("Thư viện ảnh", comment: "Gallery"))
                        .font(.caption)
                        .foregroundColor(.white)
                        .id(languageViewModel.refreshID) // Force reload khi ngôn ngữ thay đổi
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            NavigationLink {
                LanguageView()
                    .id(languageViewModel.refreshID)
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "globe")
                        .foregroundColor(.white)
                    Text(NSLocalizedString("Language", comment: "Language"))
                        .font(.caption)
                        .foregroundColor(.white)
                        .id(languageViewModel.refreshID) // Force reload khi ngôn ngữ thay đổi
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            NavigationLink {
                PremiumView()
                    .id(languageViewModel.refreshID)
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "photo.on.rectangle")
                        .foregroundColor(.white)
                    Text(NSLocalizedString("Premium", comment: "Premium"))
                        .font(.caption)
                        .foregroundColor(.white)
                        .id(languageViewModel.refreshID) // Force reload khi ngôn ngữ thay đổi
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            
            
            
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .id(languageViewModel.refreshID) // Force reload khi ngôn ngữ thay đổi
    }
}
