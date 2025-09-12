import Foundation
import FirebaseDatabase

enum MessageType: String, Codable {
    case text
    case image
}

struct ChatMessage: Identifiable, Codable {
    var id: String
    var senderId: String
    var receiverId: String
    var content: String // Nội dung tin nhắn hoặc URL ảnh
    var type: MessageType
    var timestamp: Double // Timestamp dạng Double cho Realtime Database
    var isRead: Bool
    
    init(id: String = UUID().uuidString,
         senderId: String,
         receiverId: String,
         content: String,
         type: MessageType = .text,
         timestamp: Double = Date().timeIntervalSince1970,
         isRead: Bool = false) {
        self.id = id
        self.senderId = senderId
        self.receiverId = receiverId
        self.content = content
        self.type = type
        self.timestamp = timestamp
        self.isRead = isRead
    }
    
    // Chuyển đổi từ Date sang timestamp
    var date: Date {
        return Date(timeIntervalSince1970: timestamp)
    }
    
    // Chuyển đổi từ Realtime Database snapshot
    static func fromSnapshot(_ snapshot: DataSnapshot) -> ChatMessage? {
        guard let dict = snapshot.value as? [String: Any] else { return nil }
        
        guard let senderId = dict["senderId"] as? String,
              let receiverId = dict["receiverId"] as? String,
              let content = dict["content"] as? String,
              let typeString = dict["type"] as? String,
              let type = MessageType(rawValue: typeString),
              let timestamp = dict["timestamp"] as? Double else {
            return nil
        }
        
        let isRead = dict["isRead"] as? Bool ?? false
        let id = snapshot.key
        
        return ChatMessage(
            id: id,
            senderId: senderId,
            receiverId: receiverId,
            content: content,
            type: type,
            timestamp: timestamp,
            isRead: isRead
        )
    }
    
    // Chuyển đổi thành dữ liệu cho Realtime Database
    func toDict() -> [String: Any] {
        return [
            "senderId": senderId,
            "receiverId": receiverId,
            "content": content,
            "type": type.rawValue,
            "timestamp": timestamp,
            "isRead": isRead
        ]
    }
}

struct ChatConversation: Identifiable {
    var id: String
    var participants: [String]
    var lastMessage: ChatMessage?
    var unreadCount: Int
    var updatedAt: Double // Timestamp dạng Double cho Realtime Database
    
    init(id: String,
         participants: [String],
         lastMessage: ChatMessage? = nil,
         unreadCount: Int = 0,
         updatedAt: Double = Date().timeIntervalSince1970) {
        self.id = id
        self.participants = participants
        self.lastMessage = lastMessage
        self.unreadCount = unreadCount
        self.updatedAt = updatedAt
    }
    
    // Chuyển đổi từ Date sang timestamp
    var date: Date {
        return Date(timeIntervalSince1970: updatedAt)
    }
    
    // Chuyển đổi từ Realtime Database snapshot
    static func fromSnapshot(_ snapshot: DataSnapshot) -> ChatConversation? {
        guard let dict = snapshot.value as? [String: Any] else { return nil }
        
        guard let participants = dict["participants"] as? [String],
              let updatedAt = dict["updatedAt"] as? Double else {
            return nil
        }
        
        let unreadCount = dict["unreadCount"] as? Int ?? 0
        let id = snapshot.key
        
        // Xử lý lastMessage nếu có
        var lastMessage: ChatMessage? = nil
        if let lastMessageDict = dict["lastMessage"] as? [String: Any],
           let senderId = lastMessageDict["senderId"] as? String,
           let receiverId = lastMessageDict["receiverId"] as? String,
           let content = lastMessageDict["content"] as? String,
           let typeString = lastMessageDict["type"] as? String,
           let type = MessageType(rawValue: typeString),
           let timestamp = lastMessageDict["timestamp"] as? Double,
           let messageId = lastMessageDict["id"] as? String {
            
            let isRead = lastMessageDict["isRead"] as? Bool ?? false
            
            lastMessage = ChatMessage(
                id: messageId,
                senderId: senderId,
                receiverId: receiverId,
                content: content,
                type: type,
                timestamp: timestamp,
                isRead: isRead
            )
        }
        
        return ChatConversation(
            id: id,
            participants: participants,
            lastMessage: lastMessage,
            unreadCount: unreadCount,
            updatedAt: updatedAt
        )
    }
    
    // Chuyển đổi thành dữ liệu cho Realtime Database
    func toDict() -> [String: Any] {
        var data: [String: Any] = [
            "participants": participants,
            "unreadCount": unreadCount,
            "updatedAt": updatedAt
        ]
        
        if let lastMessage = lastMessage {
            var lastMessageDict = lastMessage.toDict()
            lastMessageDict["id"] = lastMessage.id
            data["lastMessage"] = lastMessageDict
        }
        
        return data
    }
} 