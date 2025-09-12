import Foundation
import FirebaseAuth
import FirebaseFirestore

struct UserProfile: Identifiable, Codable {
    let id: String
    let email: String
    let displayName: String
    let avatarURL: String?
    let bio: String?
    let joinDate: Date
    let isOnline: Bool
    let lastSeen: Date
    let stats: UserStats
    
    init(id: String, email: String, displayName: String) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.avatarURL = nil
        self.bio = nil
        self.joinDate = Date()
        self.isOnline = false
        self.lastSeen = Date()
        self.stats = UserStats()
    }
    
    // Hàm tạo đơn giản hơn cho ChatListView
    init(id: String, email: String, displayName: String, avatarURL: String?, bio: String?) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.bio = bio
        self.joinDate = Date()
        self.isOnline = false
        self.lastSeen = Date()
        self.stats = UserStats()
    }
    
    init(id: String, email: String, displayName: String, avatarURL: String?, bio: String?, joinDate: Date, isOnline: Bool, lastSeen: Date, stats: UserStats) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.bio = bio
        self.joinDate = joinDate
        self.isOnline = isOnline
        self.lastSeen = lastSeen
        self.stats = stats
    }
}

struct UserStats: Codable {
    var photosCount: Int = 0
    var filtersUsed: Int = 0
    var friendsCount: Int = 0
    var likesReceived: Int = 0
    var premiumStatus: Bool = false
}

// MARK: - Extensions

extension UserProfile {
    static func fromFirestore(_ data: [String: Any], id: String) -> UserProfile? {
        guard let email = data["email"] as? String,
              let displayName = data["displayName"] as? String else {
            return nil // Trả về nil nếu thiếu các trường bắt buộc
        }
        
        return UserProfile(
            id: id,
            email: email,
            displayName: displayName,
            avatarURL: data["avatarURL"] as? String,
            bio: data["bio"] as? String,
            joinDate: (data["joinDate"] as? Timestamp)?.dateValue() ?? Date(),
            isOnline: data["isOnline"] as? Bool ?? false,
            lastSeen: (data["lastSeen"] as? Timestamp)?.dateValue() ?? Date(),
            stats: UserStats.fromFirestore(data["stats"] as? [String: Any] ?? [:])
        )
    }
    
    func toFirestore() -> [String: Any] {
        return [
            "email": email,
            "displayName": displayName,
            "avatarURL": avatarURL ?? NSNull(),
            "bio": bio ?? NSNull(),
            "joinDate": Timestamp(date: joinDate),
            "isOnline": isOnline,
            "lastSeen": Timestamp(date: lastSeen),
            "stats": stats.toFirestore()
        ]
    }
}

extension UserStats {
    static func fromFirestore(_ data: [String: Any]) -> UserStats {
        return UserStats(
            photosCount: data["photosCount"] as? Int ?? 0,
            filtersUsed: data["filtersUsed"] as? Int ?? 0,
            friendsCount: data["friendsCount"] as? Int ?? 0,
            likesReceived: data["likesReceived"] as? Int ?? 0,
            premiumStatus: data["premiumStatus"] as? Bool ?? false
        )
    }
    
    func toFirestore() -> [String: Any] {
        return [
            "photosCount": photosCount,
            "filtersUsed": filtersUsed,
            "friendsCount": friendsCount,
            "likesReceived": likesReceived,
            "premiumStatus": premiumStatus
        ]
    }
}
