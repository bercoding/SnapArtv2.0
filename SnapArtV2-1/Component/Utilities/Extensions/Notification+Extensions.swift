import Foundation
import FirebaseDatabase

extension Notification.Name {
    static let userDidSignIn = Notification.Name("userDidSignIn")
    static let userDidSignOut = Notification.Name("userDidSignOut")
    static let splashDidFinish = Notification.Name("splashDidFinishNotification")
    
    // Thông báo cho tin nhắn mới
    static let newMessageReceived = Notification.Name("newMessageReceived")
}

// Tiện ích cho thông báo tin nhắn mới
extension Notification {
    // Lấy tin nhắn từ thông báo
    var chatMessage: Any? {
        return userInfo?["message"]
    }
    
    // Lấy ID cuộc trò chuyện từ thông báo
    var conversationId: String? {
        return userInfo?["conversationId"] as? String
    }
    
    // Lấy ID người gửi từ thông báo
    var senderId: String? {
        return userInfo?["senderId"] as? String
    }
}
