import SwiftUI

struct ProfileView: View {
    @StateObject private var profileManager = UserProfileManager.shared
    @StateObject private var friendsManager = FriendsManager.shared
    @StateObject private var chatManager = ChatManager.shared
    @EnvironmentObject private var languageViewModel: LanguageViewModel
    @StateObject private var purchaseManager = InAppPurchaseManager.shared
    @State private var navigateToEditProfile = false
    @State private var navigateToFriends = false
    @State private var navigateToChat = false
    @State private var navigateToLanguage = false
    @State private var navigateToPremium = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Group {
                if profileManager.isLoading {
                    loadingView
                } else if profileManager.currentUser == nil {
                    noProfileView
                } else {
                    profileContentView
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .onAppear {
                profileManager.loadCurrentUserOptimized()
            }
            .background(
                NavigationLink(
                    destination: ChatListView(),
                    isActive: $navigateToChat
                ) {
                    EmptyView()
                }
            )
            .background(
                NavigationLink(
                    destination: EditProfileView(),
                    isActive: $navigateToEditProfile
                ) {
                    EmptyView()
                }
            )
            .background(
                NavigationLink(
                    destination: LanguageView(),
                    isActive: $navigateToLanguage
                ) {
                    EmptyView()
                }
            )
            .background(
                NavigationLink(
                    destination: PremiumView(purchaseManager: purchaseManager)
                        .environmentObject(purchaseManager),
                    isActive: $navigateToPremium
                ) {
                    EmptyView()
                }
            )
        }
        .id(languageViewModel.refreshID)
    }
    
    private var loadingView: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text(NSLocalizedString("Đang tải hồ sơ...", comment: "Loading profile"))
                    .foregroundColor(.white)
                    .font(.headline)
                    .padding(.top, 20)
                    .id(languageViewModel.refreshID)
            }
        }
    }
    
    private var noProfileView: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white.opacity(0.7))
                
                Text(NSLocalizedString("Không tìm thấy hồ sơ", comment: "No profile found"))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .id(languageViewModel.refreshID)
                
                Text(NSLocalizedString("Vui lòng đăng nhập để xem hồ sơ của bạn", comment: "Please log in to view your profile"))
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .id(languageViewModel.refreshID)
            }
        }
    }
    
    private var profileContentView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Profile Header
                profileHeaderView
                
                // Premium & Language Section
                premiumLanguageSection
                
                // Spacer để tạo khoảng cách dưới cùng
                Spacer().frame(height: 80)
            }
            .padding(.horizontal)
        }
        .background(
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .id(languageViewModel.refreshID)
    }
    
    private var profileHeaderView: some View {
        VStack(spacing: 16) {
            // Avatar with Premium Crown
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: profileManager.currentUser?.avatarURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(width: 120, height: 120)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                )
                .shadow(color: .black.opacity(0.2), radius: 5)
                
                // Premium Crown Badge
                if profileManager.currentUser?.stats.premiumStatus == true {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.yellow)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                        .offset(x: 10, y: -5)
                }
            }
            .padding(.top, 20)
            
            // Name and Bio
            VStack(spacing: 8) {
                Text(profileManager.currentUser?.displayName ?? "Unknown User")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if let bio = profileManager.currentUser?.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Edit Profile Button
                Button(action: {
                    navigateToEditProfile = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14))
                        Text(NSLocalizedString("Chỉnh sửa hồ sơ", comment: "Edit profile"))
                            .font(.subheadline)
                            .id(languageViewModel.refreshID)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.2))
                    .foregroundColor(.white)
                    .cornerRadius(20)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.1))
                .shadow(color: .black.opacity(0.1), radius: 10)
        )
        .padding(.top, 16)
        .id(languageViewModel.refreshID)
    }
    
    private var premiumLanguageSection: some View {
        VStack(spacing: 16) {
            // Premium Card - Hide if user is already premium
            if profileManager.currentUser?.stats.premiumStatus != true {
                menuItem(
                    icon: "crown.fill",
                    iconColor: .yellow,
                    title: NSLocalizedString("Premium", comment: "Premium"),
                    subtitle: NSLocalizedString("Mở khóa tất cả tính năng", comment: "Unlock all features"),
                    action: {
                        navigateToPremium = true
                    }
                )
            }
            
            // Language Card
            menuItem(
                icon: "globe",
                iconColor: .cyan,
                title: NSLocalizedString("Ngôn ngữ", comment: "Language"),
                subtitle: languageViewModel.getCurrentLanguageName(),
                action: {
                    navigateToLanguage = true
                }
            )
            
            // Chat
            menuItem(
                icon: "message.fill",
                iconColor: .green,
                title: NSLocalizedString("Tin nhắn", comment: "Messages"),
                subtitle: NSLocalizedString("Xem tất cả cuộc trò chuyện", comment: "View all conversations"),
                action: {
                    navigateToChat = true
                }
            )
            
            // Sign Out
            menuItem(
                icon: "rectangle.portrait.and.arrow.right",
                iconColor: .red,
                title: NSLocalizedString("Đăng xuất", comment: "Sign out"),
                subtitle: NSLocalizedString("Đăng xuất khỏi tài khoản", comment: "Sign out of account"),
                action: {
                    // Thêm xác nhận trước khi đăng xuất
                    // authViewModel.signOut()
                }
            )
        }
        .id(languageViewModel.refreshID)
    }
    
    private func menuItem(icon: String, iconColor: Color, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.6))
                    .font(.system(size: 14))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ProfileView()
}
