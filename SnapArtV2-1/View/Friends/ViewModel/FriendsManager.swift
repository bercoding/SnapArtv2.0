import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Foundation

class FriendsManager: ObservableObject {
    static let shared = FriendsManager()
    
    @Published var friends: [UserProfile] = []
    @Published var friendRequests: [FriendRequest] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchResults: [UserProfile] = []
    
    private let db = Firestore.firestore()
    
    private init() {
        setupAuthStateListener()
        
        // Đăng ký lắng nghe sự kiện đăng nhập/đăng xuất
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUserSignIn),
            name: .userDidSignIn,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUserSignOut),
            name: .userDidSignOut,
            object: nil
        )
    }
    
    private func setupAuthStateListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                self?.loadFriends()
                self?.loadFriendRequests()
            } else {
                DispatchQueue.main.async {
                    self?.friends = []
                    self?.friendRequests = []
                    self?.searchResults = []
                }
            }
        }
    }
    
    @objc private func handleUserSignIn() {
        loadFriends()
        loadFriendRequests()
    }
    
    @objc private func handleUserSignOut() {
        DispatchQueue.main.async {
            self.friends = []
            self.friendRequests = []
            self.searchResults = []
        }
    }
    
    // MARK: - Friends Management
    
    func loadFriends() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        db.collection("friendships")
            .whereField("participants", arrayContains: userId)
            .whereField("status", isEqualTo: "accepted")
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        return
                    }
                    
                    guard let documents = snapshot?.documents else { return }
                    
                    let friendIds = documents.compactMap { doc -> String? in
                        let data = doc.data()
                        let participants = data["participants"] as? [String] ?? []
                        return participants.first { $0 != userId }
                    }
                    
                    self?.loadUserProfiles(friendIds)
                }
            }
    }
    
    private func loadUserProfiles(_ userIds: [String]) {
        guard !userIds.isEmpty else { return }
        
        db.collection("users")
            .whereField(FieldPath.documentID(), in: userIds)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                let profiles = documents.compactMap { doc -> UserProfile? in
                    UserProfile.fromFirestore(doc.data(), id: doc.documentID)
                }
                
                DispatchQueue.main.async {
                    self?.friends = profiles
                }
            }
    }
    
    // MARK: - Friend Requests
    
    func loadFriendRequests() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("friend_requests")
            .whereField("toUserId", isEqualTo: userId)
            .whereField("status", isEqualTo: "pending")
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                let requests = documents.compactMap { doc -> FriendRequest? in
                    FriendRequest.fromFirestore(doc.data(), id: doc.documentID)
                }
                
                DispatchQueue.main.async {
                    self?.friendRequests = requests
                }
            }
    }
    
    func sendFriendRequest(to userId: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw FriendsError.notAuthenticated
        }
        
        // Check if already friends or request exists
        let existingRequest = try await db.collection("friend_requests")
            .whereField("fromUserId", isEqualTo: currentUserId)
            .whereField("toUserId", isEqualTo: userId)
            .whereField("status", isEqualTo: "pending")
            .getDocuments()
        
        if !existingRequest.documents.isEmpty {
            throw FriendsError.invalidRequest
        }
        
        let requestId = UUID().uuidString
        let requestData: [String: Any] = [
            "fromUserId": currentUserId,
            "toUserId": userId,
            "status": "pending",
            "createdAt": Timestamp(date: Date())
        ]
        
        try await db.collection("friend_requests").document(requestId).setData(requestData)
    }
    
    func acceptFriendRequest(_ requestId: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw FriendsError.notAuthenticated
        }
        
        // Get request details
        let requestDoc = try await db.collection("friend_requests").document(requestId).getDocument()
        guard let requestData = requestDoc.data(),
              let fromUserId = requestData["fromUserId"] as? String else {
            throw FriendsError.invalidRequest
        }
        
        // Update request status
        try await db.collection("friend_requests").document(requestId).updateData([
            "status": "accepted"
        ])
        
        // Create friendship
        let friendshipId = UUID().uuidString
        let friendshipData: [String: Any] = [
            "participants": [currentUserId, fromUserId],
            "status": "accepted",
            "createdAt": Timestamp(date: Date())
        ]
        
        try await db.collection("friendships").document(friendshipId).setData(friendshipData)
        
        // Update friend counts
        try await updateFriendCount(currentUserId)
        try await updateFriendCount(fromUserId)
        
        // Reload data
        loadFriends()
        loadFriendRequests()
    }
    
    func rejectFriendRequest(_ requestId: String) async throws {
        try await db.collection("friend_requests").document(requestId).updateData([
            "status": "rejected"
        ])
        
        loadFriendRequests()
    }
    
    private func updateFriendCount(_ userId: String) async throws {
        let friendsQuery = db.collection("friendships")
            .whereField("participants", arrayContains: userId)
            .whereField("status", isEqualTo: "accepted")
        
        let snapshot = try await friendsQuery.getDocuments()
        let count = snapshot.documents.count
        
        try await db.collection("users").document(userId).updateData([
            "stats.friendsCount": count
        ])
    }
    
    // MARK: - Search Users
    
    func searchUsers(query: String) async throws {
        guard !query.isEmpty else { 
            searchResults = []
            return 
        }
        
        let snapshot = try await db.collection("users")
            .whereField("displayName", isGreaterThanOrEqualTo: query)
            .whereField("displayName", isLessThan: query + "\u{f8ff}")
            .limit(to: 20)
            .getDocuments()
        
        let profiles = snapshot.documents.compactMap { doc in
            UserProfile.fromFirestore(doc.data(), id: doc.documentID)
        }
        
        DispatchQueue.main.async {
            self.searchResults = profiles
        }
    }
    
    // MARK: - Remove Friend
    
    func removeFriend(_ friendId: String) async throws {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw FriendsError.notAuthenticated
        }
        
        // Find and delete friendship
        let friendshipQuery = db.collection("friendships")
            .whereField("participants", arrayContains: currentUserId)
            .whereField("participants", arrayContains: friendId)
            .whereField("status", isEqualTo: "accepted")
        
        let snapshot = try await friendshipQuery.getDocuments()
        
        for document in snapshot.documents {
            try await document.reference.delete()
        }
        
        // Update friend counts
        try await updateFriendCount(currentUserId)
        try await updateFriendCount(friendId)
        
        // Reload friends
        loadFriends()
    }
}
