import Foundation
import SwiftUI
import FirebaseFirestore

class ConversationRowViewModel: ObservableObject {
    @Published var otherUserProfile: UserProfile?
    @Published var isLoadingProfile = true
    
    private let chatManager = ChatManager.shared
    private let profileManager = UserProfileManager.shared
    private let conversation: ChatConversation
    
    init(conversation: ChatConversation) {
        self.conversation = conversation
        setupNotifications()
        loadOtherUserProfile()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUserProfileLoaded),
            name: Notification.Name.userProfileLoaded,
            object: nil
        )
    }
    
    @objc private func handleUserProfileLoaded(_ notification: Notification) {
        if let userId = notification.userInfo?["userId"] as? String,
           let otherUserId = chatManager.getOtherParticipantId(in: conversation),
           userId == otherUserId,
           let userData = notification.userInfo?["userData"] as? [String: Any] {
            
            // Tạo UserProfile từ dữ liệu nhận được sử dụng hàm tạo đơn giản hơn
            let profile = UserProfile(
                id: userId,
                email: userData["email"] as? String ?? "",
                displayName: userData["displayName"] as? String ?? "Người dùng",
                avatarURL: userData["avatarURL"] as? String,
                bio: userData["bio"] as? String ?? ""
            )
            
            DispatchQueue.main.async {
                self.otherUserProfile = profile
                self.isLoadingProfile = false
            }
        }
    }
    
    func loadOtherUserProfile() {
        guard let otherUserId = chatManager.getOtherParticipantId(in: conversation) else {
            DispatchQueue.main.async {
                self.isLoadingProfile = false
            }
            return
        }
        
        Task {
            do {
                let profile = try await profileManager.getUserProfile(userId: otherUserId)
                await MainActor.run {
                    self.otherUserProfile = profile
                    self.isLoadingProfile = false
                }
            } catch {
                await MainActor.run {
                    self.isLoadingProfile = false
                    print("Error loading other user profile: \(error.localizedDescription)")
                }
            }
        }
    }
    
    var otherUserDisplayName: String {
        return otherUserProfile?.displayName ?? "Unknown User"
    }
    
    var otherUserAvatarURL: String? {
        return otherUserProfile?.avatarURL
    }
    
    var lastMessageText: String {
        return conversation.lastMessage?.content ?? "No messages yet"
    }
    
    var lastMessageTime: String {
        guard let timestamp = conversation.lastMessage?.timestamp else {
            return ""
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        
        // Chuyển đổi Double timestamp thành Date
        let date = Date(timeIntervalSince1970: timestamp)
        return formatter.string(from: date)
    }
    
    var isUnread: Bool {
        return conversation.unreadCount > 0
    }
    
    var unreadCount: Int {
        return conversation.unreadCount
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
