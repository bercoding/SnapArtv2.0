import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseDatabase

class ChatListViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var showingSearchResults = false
    @Published var searchResults: [UserProfile] = []
    @Published var isInitializing = false
    @Published var debugMessage: String?
    
    private let chatManager = ChatManager.shared
    private let profileManager = UserProfileManager.shared
    
    // MARK: - Initialization
    
    init() {
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUserProfileLoaded),
            name: .userProfileLoaded,
            object: nil
        )
    }
    
    @objc private func handleUserProfileLoaded(_ notification: Notification) {
        // Xử lý thông báo khi thông tin người dùng được tải
    }
    
    // MARK: - Database Initialization
    
    func initializeDatabase() {
        isInitializing = true
        chatManager.errorMessage = nil
        
        // Đặt timeout ngắn hơn để tránh treo vô hạn
        let timeoutTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.isInitializing = false
                self?.chatManager.errorMessage = "Khởi tạo database quá thời gian. Vui lòng thử lại."
            }
        }
        
        // Kiểm tra kết nối internet trước
        Task {
            await performDatabaseInitialization()
            timeoutTimer.invalidate()
        }
    }
    
    private func performDatabaseInitialization() async {
        do {
            // Load current user profile first
            await profileManager.loadCurrentUserOptimized()
            
            // Initialize chat manager using the correct method
            await withCheckedContinuation { continuation in
                chatManager.initializeDatabaseIfNeeded { success in
                    continuation.resume()
                }
            }
            
            await MainActor.run {
                self.isInitializing = false
            }
        } catch {
            await MainActor.run {
                self.isInitializing = false
                self.chatManager.errorMessage = "Lỗi khởi tạo: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Search Functionality
    
    func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            showingSearchResults = false
            return
        }
        
        Task {
            do {
                let results = try await profileManager.searchUsers(query: searchText)
                await MainActor.run {
                    self.searchResults = results
                    self.showingSearchResults = true
                }
            } catch {
                await MainActor.run {
                    self.debugMessage = "Search error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func clearSearch() {
        searchText = ""
        searchResults = []
        showingSearchResults = false
    }
    
    // MARK: - User Profile Management
    
    func getUserProfile(userId: String) async -> UserProfile? {
        do {
            return try await profileManager.getUserProfile(userId: userId)
        } catch {
            await MainActor.run {
                self.debugMessage = "Error loading user profile: \(error.localizedDescription)"
            }
            return nil
        }
    }
    
    func preloadUserProfiles(userIds: [String]) {
        profileManager.preloadUserProfiles(userIds: userIds)
    }
    
    // MARK: - Cleanup
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Notification Extension
extension Notification.Name {
    static let userProfileLoaded = Notification.Name("userProfileLoaded")
}
