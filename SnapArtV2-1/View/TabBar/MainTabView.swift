import SwiftUI
import UIKit

struct MainTabView: View {
    @StateObject private var interstitialAdManager = InterstitialAdManager.shared
    @EnvironmentObject private var languageViewModel: LanguageViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var chatManager = ChatManager.shared
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Trang Chủ
            HomeTabView()
                .tabItem {
                    Image(systemName: "house.circle")
                    Text(NSLocalizedString("Trang Chủ", comment: "Home"))
                        .id(languageViewModel.refreshID)
                }
                .tag(0)
            
            // Tab 2: Thư viện
            GalleryView()
                .id(languageViewModel.refreshID)
                .tabItem {
                    Image(systemName: "photo.on.rectangle")
                    Text(NSLocalizedString("Thư viện", comment: "Gallery"))
                        .id(languageViewModel.refreshID)
                }
                .tag(1)
            
            // Tab 3: Tin nhắn
            ChatListView()
                .id(languageViewModel.refreshID)
                .tabItem {
                    ZStack {
                        Image(systemName: "message.circle")
                        if chatManager.unreadConversationsCount > 0 {
                            Text("\(chatManager.unreadConversationsCount)")
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                    }
                    Text(NSLocalizedString("Tin nhắn", comment: "Chat"))
                        .id(languageViewModel.refreshID)
                }
                .tag(2)
                .badge(chatManager.unreadConversationsCount > 0 ? chatManager.unreadConversationsCount : 0)
            
            // Tab 4: Hồ sơ
            ProfileView()
                .id(languageViewModel.refreshID)
                .tabItem {
                    Image(systemName: "person.circle")
                    Text(NSLocalizedString("Hồ sơ", comment: "Profile"))
                        .id(languageViewModel.refreshID)
                }
                .tag(3)
        }
        .accentColor(.blue) // Màu khi tab được chọn
        .onAppear {
            // Tùy chỉnh màu sắc của TabView
            let appearance = UITabBarAppearance()
            appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
            appearance.backgroundColor = UIColor(Color.black.opacity(0.5))
            
            // Màu của các item
            let itemAppearance = UITabBarItemAppearance()
            itemAppearance.normal.iconColor = UIColor.white.withAlphaComponent(0.6)
            itemAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white.withAlphaComponent(0.6)]
            itemAppearance.selected.iconColor = UIColor.systemBlue
            itemAppearance.selected.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.systemBlue]
            
            appearance.stackedLayoutAppearance = itemAppearance
            appearance.inlineLayoutAppearance = itemAppearance
            appearance.compactInlineLayoutAppearance = itemAppearance
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
} 