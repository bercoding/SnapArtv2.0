import Foundation
import FirebaseFirestore

struct FriendRequest: Identifiable {
    let id: String
    let fromUserId: String
    let toUserId: String
    let status: String
    let createdAt: Date
    let fromUser: UserProfile?
    
    static func fromFirestore(_ data: [String: Any], id: String) -> FriendRequest? {
        guard let fromUserId = data["fromUserId"] as? String,
              let toUserId = data["toUserId"] as? String,
              let status = data["status"] as? String else { return nil }
        
        return FriendRequest(
            id: id,
            fromUserId: fromUserId,
            toUserId: toUserId,
            status: status,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            fromUser: nil // Will be loaded separately
        )
    }
}

enum FriendsError: LocalizedError {
    case notAuthenticated
    case invalidRequest
    case userNotFound
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .invalidRequest:
            return "Invalid friend request"
        case .userNotFound:
            return "User not found"
        }
    }
}
