import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import UIKit

class UserProfileManager: ObservableObject {
    static let shared = UserProfileManager()
    
    @Published var currentUser: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private var userProfileCache: [String: UserProfile] = [:]
    private var loadingTasks: [String: Task<Void, Never>] = [:]
    private let cacheQueue = DispatchQueue(label: "profile.cache", qos: .userInitiated)
    private let maxCacheSize = 100
    
    // Cache keys for UserDefaults
    private let currentUserCacheKey = "current_user_profile"
    private let userProfilesCacheKey = "user_profiles_cache"
    
    private init() {
        loadCachedData()
        setupAuthStateListener()
        setupNotificationObservers()
    }
    
    // MARK: - Cache Management
    
    private func loadCachedData() {
        // Load current user from cache immediately
        if let currentUserData = UserDefaults.standard.data(forKey: currentUserCacheKey),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: currentUserData) {
            DispatchQueue.main.async {
                self.currentUser = profile
            }
        }
        
        // Load user profiles cache
        if let cacheData = UserDefaults.standard.data(forKey: userProfilesCacheKey),
           let profiles = try? JSONDecoder().decode([String: UserProfile].self, from: cacheData) {
            userProfileCache = profiles
        }
    }
    
    private func saveCachedData() {
        cacheQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Save current user
            if let currentUser = self.currentUser,
               let data = try? JSONEncoder().encode(currentUser) {
                UserDefaults.standard.set(data, forKey: self.currentUserCacheKey)
            }
            
            // Save user profiles cache (limit size)
            let limitedCache = Dictionary(uniqueKeysWithValues: Array(self.userProfileCache.prefix(self.maxCacheSize))) 
            if let data = try? JSONEncoder().encode(limitedCache) {
                UserDefaults.standard.set(data, forKey: self.userProfilesCacheKey)
            }
        }
    }
    
    private func setupNotificationObservers() {
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
        
        // Listen for app lifecycle events
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
    
    @objc private func appDidEnterBackground() {
        saveCachedData()
    }
    
    private func setupAuthStateListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                self?.loadCurrentUserOptimized()
            } else {
                DispatchQueue.main.async {
                    self?.currentUser = nil
                    self?.userProfileCache.removeAll()
                }
            }
        }
    }
    
    @objc private func handleUserSignIn() {
        loadCurrentUserOptimized()
    }
    
    @objc private func handleUserSignOut() {
        DispatchQueue.main.async {
            self.currentUser = nil
            self.userProfileCache.removeAll()
            self.loadingTasks.removeAll()
        }
        UserDefaults.standard.removeObject(forKey: currentUserCacheKey)
        UserDefaults.standard.removeObject(forKey: userProfilesCacheKey)
    }
    
    // MARK: - Optimized Profile Loading
    
    func loadCurrentUserOptimized() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // 1. Return cached data immediately if available
        if let cachedProfile = userProfileCache[userId] {
            DispatchQueue.main.async {
                self.currentUser = cachedProfile
            }
        }
        
        // 2. Load from Firebase in background
        Task {
            await loadCurrentUserFromFirebase(userId: userId)
        }
    }
    
    private func loadCurrentUserFromFirebase(userId: String) async {
        // Cancel any existing loading task
        loadingTasks[userId]?.cancel()
        
        let task = Task {
            do {
                let snapshot = try await db.collection("users").document(userId).getDocument()
                
                if let data = snapshot.data(), let profile = UserProfile.fromFirestore(data, id: userId) {
                    await MainActor.run {
                        self.currentUser = profile
                        self.userProfileCache[userId] = profile
                        self.isLoading = false
                        self.errorMessage = nil
                    }
                    saveCachedData()
                } else {
                    // Create new profile
                    await createNewProfile()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
            }
        }
        }
        
        loadingTasks[userId] = task
    }
    
    private func createNewProfile() async {
        guard let user = Auth.auth().currentUser else { return }
        
        let newProfile = UserProfile(
            id: user.uid,
            email: user.email ?? "",
            displayName: user.displayName ?? "User"
        )
        
        await saveProfile(newProfile)
    }
    
    // MARK: - Async Profile Management
        
    func saveProfile(_ profile: UserProfile) async {
        do {
        let data = profile.toFirestore()
            try await db.collection("users").document(profile.id).setData(data)
            
            await MainActor.run {
                self.currentUser = profile
                self.userProfileCache[profile.id] = profile
                self.isLoading = false
                self.errorMessage = nil
            }
            saveCachedData()
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func updateProfile(displayName: String? = nil, bio: String? = nil, avatar: UIImage? = nil) async throws {
        guard let currentProfile = currentUser else {
            throw ProfileError.noCurrentUser
        }
        
        // Tạo profile mới với các thay đổi
        var updatedProfile = UserProfile(
            id: currentProfile.id,
            email: currentProfile.email,
            displayName: displayName ?? currentProfile.displayName,
            avatarURL: currentProfile.avatarURL,
            bio: bio ?? currentProfile.bio,
            joinDate: currentProfile.joinDate,
            isOnline: currentProfile.isOnline,
            lastSeen: currentProfile.lastSeen,
            stats: currentProfile.stats
        )
        
        // Nếu có avatar mới, upload và cập nhật URL
        if let avatar = avatar {
            let avatarURL = try await uploadAvatar(avatar)
            updatedProfile = UserProfile(
                id: updatedProfile.id,
                email: updatedProfile.email,
                displayName: updatedProfile.displayName,
                avatarURL: avatarURL,
                bio: updatedProfile.bio,
                joinDate: updatedProfile.joinDate,
                isOnline: updatedProfile.isOnline,
                lastSeen: updatedProfile.lastSeen,
                stats: updatedProfile.stats
            )
        }
        
        await saveProfile(updatedProfile)
    }
    
    private func uploadAvatar(_ image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8),
              let userId = Auth.auth().currentUser?.uid else {
            throw ProfileError.uploadFailed
        }
        
        let storageRef = storage.reference().child("avatars/\(userId).jpg")
        _ = try await storageRef.putDataAsync(imageData)
        return try await storageRef.downloadURL().absoluteString
    }
    
    // MARK: - Optimized User Loading
    
    func getUserProfile(userId: String) async throws -> UserProfile {
        // 1. Check cache first
        if let cachedProfile = userProfileCache[userId] {
            return cachedProfile
        }
        
        // 2. Check if already loading
        if loadingTasks[userId] != nil {
            // Wait for existing task
            try await loadingTasks[userId]?.value
            if let profile = userProfileCache[userId] {
                return profile
            }
        }
        
        // 3. Load from Firebase
        let task = Task {
            do {
                let snapshot = try await db.collection("users").document(userId).getDocument()
                
                guard let data = snapshot.data(),
                      let profile = UserProfile.fromFirestore(data, id: userId) else {
                    throw ProfileError.userNotFound
                }
                
                await MainActor.run {
                    self.userProfileCache[userId] = profile
                }
                saveCachedData()
                return profile
            } catch {
                throw error
            }
        }
        
        // Lưu task vào một biến tạm thời, không gán trực tiếp vào loadingTasks
        let loadingTask = Task<Void, Never> {
            do {
                _ = try await task.value
            } catch {
                print("Error loading user profile: \(error)")
            }
        }
        
        loadingTasks[userId] = loadingTask
        let profile = try await task.value
        loadingTasks.removeValue(forKey: userId)
        return profile
    }
    
    // MARK: - Batch Loading with Optimization
    
    func fetchUserProfiles(userIds: [String]) async throws -> [String: UserProfile] {
        let uniqueIds = Array(Set(userIds))
        var profiles: [String: UserProfile] = [:]
        var idsToFetch: [String] = []
        
        // 1. Get from cache first
        for id in uniqueIds {
            if let cachedProfile = userProfileCache[id] {
                profiles[id] = cachedProfile
            } else {
                idsToFetch.append(id)
            }
        }
        
        // 2. If all cached, return immediately
        if idsToFetch.isEmpty {
            return profiles
        }
        
        // 3. Fetch missing profiles concurrently
        let fetchTasks = idsToFetch.map { userId in
            Task<(String, UserProfile?), Error> {
                do {
                    let profile = try await getUserProfile(userId: userId)
                    return (userId, profile)
                } catch {
                    // Trả về nil nhưng phải chỉ định rõ kiểu dữ liệu
                    return (userId, nil as UserProfile?)
                }
            }
        }
        
        let results = await withTaskGroup(of: (String, UserProfile?).self) { group in
            for task in fetchTasks {
                group.addTask {
                    do {
                        return try await task.value
                    } catch {
                        // Xử lý lỗi và trả về một giá trị mặc định
                        print("Error fetching profile: \(error)")
                        return ("", nil)
                    }
                }
            }
            
            var results: [(String, UserProfile?)] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
            
        // 4. Add successful results
        for (userId, profile) in results {
            if let profile = profile {
                profiles[userId] = profile
            }
        }
        
        return profiles
    }
    
    // MARK: - Stats Updates (Optimized)
    
    func incrementPhotosCount() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        Task {
            do {
                try await db.collection("users").document(userId).updateData([
                    "stats.photosCount": FieldValue.increment(Int64(1))
                ])
                
                // Update local cache
                if let currentProfile = currentUser {
                    // Tạo một bản sao mới của UserStats
                    var updatedStats = currentProfile.stats
                    updatedStats.photosCount += 1
                    
                    // Tạo một bản sao mới của UserProfile với stats đã cập nhật
                    let updatedProfile = UserProfile(
                        id: currentProfile.id,
                        email: currentProfile.email,
                        displayName: currentProfile.displayName,
                        avatarURL: currentProfile.avatarURL,
                        bio: currentProfile.bio,
                        joinDate: currentProfile.joinDate,
                        isOnline: currentProfile.isOnline,
                        lastSeen: currentProfile.lastSeen,
                        stats: updatedStats
                    )
                    
                    await MainActor.run {
                        self.currentUser = updatedProfile
                        self.userProfileCache[userId] = updatedProfile
                    }
                    saveCachedData()
                }
            } catch {
                print("Error incrementing photos count: \(error)")
            }
        }
    }
    
    func incrementFiltersUsed() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        Task {
            do {
                try await db.collection("users").document(userId).updateData([
                    "stats.filtersUsed": FieldValue.increment(Int64(1))
                ])
                
                // Update local cache
                if let currentProfile = currentUser {
                    // Tạo một bản sao mới của UserStats
                    var updatedStats = currentProfile.stats
                    updatedStats.filtersUsed += 1
                    
                    // Tạo một bản sao mới của UserProfile với stats đã cập nhật
                    let updatedProfile = UserProfile(
                        id: currentProfile.id,
                        email: currentProfile.email,
                        displayName: currentProfile.displayName,
                        avatarURL: currentProfile.avatarURL,
                        bio: currentProfile.bio,
                        joinDate: currentProfile.joinDate,
                        isOnline: currentProfile.isOnline,
                        lastSeen: currentProfile.lastSeen,
                        stats: updatedStats
                    )
                    
                    await MainActor.run {
                        self.currentUser = updatedProfile
                        self.userProfileCache[userId] = updatedProfile
                    }
                    saveCachedData()
                }
            } catch {
                print("Error incrementing filters used: \(error)")
            }
        }
    }
    
    func updatePremiumStatus(_ isPremium: Bool) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        Task {
            do {
                try await db.collection("users").document(userId).updateData([
                    "stats.premiumStatus": isPremium
                ])
                
                // Update local cache
                if let currentProfile = currentUser {
                    // Tạo một bản sao mới của UserStats
                    var updatedStats = currentProfile.stats
                    updatedStats.premiumStatus = isPremium
                    
                    // Tạo một bản sao mới của UserProfile với stats đã cập nhật
                    let updatedProfile = UserProfile(
                        id: currentProfile.id,
                        email: currentProfile.email,
                        displayName: currentProfile.displayName,
                        avatarURL: currentProfile.avatarURL,
                        bio: currentProfile.bio,
                        joinDate: currentProfile.joinDate,
                        isOnline: currentProfile.isOnline,
                        lastSeen: currentProfile.lastSeen,
                        stats: updatedStats
                    )
                    
                    await MainActor.run {
                        self.currentUser = updatedProfile
                        self.userProfileCache[userId] = updatedProfile
                    }
                    saveCachedData()
                }
            } catch {
                print("Error updating premium status: \(error)")
            }
        }
    }
    
    // MARK: - Optimized Search
    
    func searchUsers(query: String) async throws -> [UserProfile] {
        guard query.count >= 2 else { return [] }
        
        let queryLowercase = query.lowercased()
        
        return try await withCheckedThrowingContinuation { continuation in
            db.collection("users")
                .order(by: "displayName")
                .limit(to: 20)
                .getDocuments { snapshot, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        continuation.resume(returning: [])
                        return
                    }
                    
                    let users = documents.compactMap { document -> UserProfile? in
                        let data = document.data()
                        let profile = UserProfile.fromFirestore(data, id: document.documentID)
                        
                        if profile?.displayName.lowercased().contains(queryLowercase) == true ||
                           profile?.email.lowercased().contains(queryLowercase) == true {
                            return profile
                        }
                        return nil
                    }
                    
                    let sortedUsers = users.sorted { user1, user2 in
                        let name1StartsWithQuery = user1.displayName.lowercased().hasPrefix(queryLowercase)
                        let name2StartsWithQuery = user2.displayName.lowercased().hasPrefix(queryLowercase)
                        
                        if name1StartsWithQuery && !name2StartsWithQuery {
                            return true
                        } else if !name1StartsWithQuery && name2StartsWithQuery {
                            return false
                        }
                        
                        return user1.displayName < user2.displayName
                    }
                    
                    continuation.resume(returning: sortedUsers)
                }
        }
    }
    
    // MARK: - Cache Management
    
    func clearCache() {
        userProfileCache.removeAll()
        loadingTasks.removeAll()
        UserDefaults.standard.removeObject(forKey: currentUserCacheKey)
        UserDefaults.standard.removeObject(forKey: userProfilesCacheKey)
    }
    
    func preloadUserProfiles(userIds: [String]) {
        Task {
            _ = try? await fetchUserProfiles(userIds: userIds)
        }
    }
}

enum ProfileError: LocalizedError {
    case noCurrentUser
    case uploadFailed
    case userNotFound
    
    var errorDescription: String? {
        switch self {
        case .noCurrentUser:
            return NSLocalizedString("Không tìm thấy người dùng hiện tại. Vui lòng đăng nhập lại.", comment: "ProfileError: No current user")
        case .uploadFailed:
            return NSLocalizedString("Không thể tải lên ảnh đại diện. Vui lòng thử lại.", comment: "ProfileError: Upload failed")
        case .userNotFound:
            return NSLocalizedString("Không tìm thấy thông tin người dùng này.", comment: "ProfileError: User not found")
        }
    }
}

// Extension để chia mảng thành các mảng con
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
