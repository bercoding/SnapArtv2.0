import Foundation
import SwiftUI
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage
import FirebaseCore
import FirebaseFirestore // Added for loadUserInfoForConversations

class ChatManager: ObservableObject {
    static let shared = ChatManager()
    
    @Published var conversations: [ChatConversation] = []
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentConversation: ChatConversation?
    @Published var unreadConversationsCount: Int = 0
    
    private lazy var db = Database.database().reference()
    private let storage = Storage.storage()
    var messagesRef: DatabaseReference?
    var messagesObservers: [DatabaseHandle] = []
    private var conversationsRef: DatabaseReference?
    private var conversationsObserver: DatabaseHandle?
    
    private init() {
        setupAuthStateListener()
        
        // Đăng ký lắng nghe thông báo khi có tin nhắn mới
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNewMessage),
            name: .newMessageReceived,
            object: nil
        )
    }
    
    // MARK: - Database Setup
    
    // Hàm này có thể được gọi từ bên ngoài để thiết lập cấu trúc ban đầu cho Realtime Database
    static func setupInitialDatabaseStructure() {
        guard FirebaseApp.app() != nil else {
            return
        }
        
        let db = Database.database().reference()
        
        // Chỉ tạo nút "conversations" nếu nó chưa tồn tại
        db.child("conversations").observeSingleEvent(of: .value) { snapshot in
            if !snapshot.exists() {
                db.child("conversations").setValue([:])
            }
        }
        
        // Chỉ tạo nút "messages" nếu nó chưa tồn tại
        db.child("messages").observeSingleEvent(of: .value) { snapshot in
            if !snapshot.exists() {
                db.child("messages").setValue([:])
            }
        }
    }
    
    // Khởi tạo cấu trúc dữ liệu nếu cần
    func initializeDatabaseIfNeeded(completion: @escaping (Bool) -> Void) {
        // Đặt timeout để tránh treo vô hạn
        var hasCompleted = false
        
        // Tạo timer để hủy sau 5 giây nếu không có phản hồi
        let timeoutTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            if !hasCompleted {
                hasCompleted = true
                completion(false)
            }
        }
        
        // Kiểm tra người dùng đã đăng nhập chưa
        guard let currentUser = Auth.auth().currentUser else {
            timeoutTimer.invalidate()
            if !hasCompleted {
                hasCompleted = true
                completion(false)
            }
            return
        }
        
        // Kiểm tra kết nối internet trước
        let url = URL(string: "https://www.google.com")!
        let task = URLSession.shared.dataTask(with: url) { [weak self] _, response, error in
            guard let self = self else {
                timeoutTimer.invalidate()
                if !hasCompleted {
                    hasCompleted = true
                    completion(false)
                }
                return
            }
            
            if let error = error {
                timeoutTimer.invalidate()
                if !hasCompleted {
                    hasCompleted = true
                    completion(false)
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                timeoutTimer.invalidate()
                if !hasCompleted {
                    hasCompleted = true
                    completion(false)
                }
                return
            }
            
            // Kiểm tra kết nối đến Firebase
            self.db.child(".info/connected").observeSingleEvent(of: .value) { snapshot in
                if let error = snapshot.value as? NSError {
                    // Kiểm tra lỗi quyền truy cập
                    timeoutTimer.invalidate()
                    if !hasCompleted {
                        hasCompleted = true
                        completion(false)
                    }
                    return
                }
                
                if !snapshot.exists() {
                    timeoutTimer.invalidate()
                    if !hasCompleted {
                        hasCompleted = true
                        completion(false)
                    }
                    return
                }
                
                // Kiểm tra xem database đã được khởi tạo chưa
                self.db.observeSingleEvent(of: .value) { snapshot in
                    if let error = snapshot.value as? NSError {
                        // Kiểm tra lỗi quyền truy cập
                        timeoutTimer.invalidate()
                        if !hasCompleted {
                            hasCompleted = true
                            completion(false)
                        }
                        return
                    }
                    
                    if !snapshot.exists() || snapshot.childrenCount == 0 {
                        // Tạo nút user_conversations cho người dùng hiện tại
                        self.db.child("user_conversations").child(currentUser.uid).setValue(true) { error, _ in
                            if let error = error {
                                // Kiểm tra lỗi quyền truy cập
                                timeoutTimer.invalidate()
                                if !hasCompleted {
                                    hasCompleted = true
                                    completion(false)
                                }
                                return
                            }
                            
                            // Tạo nút conversations
                            self.db.child("conversations").setValue([:]) { error, _ in
                                if let error = error {
                                    // Kiểm tra lỗi quyền truy cập
                                    timeoutTimer.invalidate()
                                    if !hasCompleted {
                                        hasCompleted = true
                                        completion(false)
                                    }
                                    return
                                }
                                
                                // Tạo nút messages
                                self.db.child("messages").setValue([:]) { error, _ in
                                    timeoutTimer.invalidate()
                                    
                                    if let error = error {
                                        // Kiểm tra lỗi quyền truy cập
                                        if !hasCompleted {
                                            hasCompleted = true
                                            completion(false)
                                        }
                                        return
                                    }
                                    
                                    // Kiểm tra lại cấu trúc database
                                    self.db.observeSingleEvent(of: .value) { snapshot in
                                        if snapshot.exists() && snapshot.hasChild("conversations") && snapshot.hasChild("messages") {
                                            if !hasCompleted {
                                                hasCompleted = true
                                                completion(true)
                                            }
                                        } else {
                                            if !hasCompleted {
                                                hasCompleted = true
                                                completion(false)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } else if !snapshot.hasChild("conversations") || !snapshot.hasChild("messages") {
                        // Tạo nút conversations nếu chưa có
                        if !snapshot.hasChild("conversations") {
                            self.db.child("conversations").setValue([:])
                        }
                        
                        // Tạo nút messages nếu chưa có
                        if !snapshot.hasChild("messages") {
                            self.db.child("messages").setValue([:])
                        }
                        
                        // Hoàn thành
                        timeoutTimer.invalidate()
                        if !hasCompleted {
                            hasCompleted = true
                            completion(true)
                        }
                    } else {
                        timeoutTimer.invalidate()
                        if !hasCompleted {
                            hasCompleted = true
                            completion(true)
                        }
                    }
                }
            }
        }
        task.resume()
    }
    
    // Hàm này trả về rules mẫu cho Realtime Database
    static func getSampleDatabaseRules() -> String {
        return """
        {
          "rules": {
            ".read": "auth != null",
            ".write": "auth != null",
            "conversations": {
              "$conversationId": {
                ".read": "auth != null && data.child('participants').val().contains(auth.uid)",
                ".write": "auth != null && (newData.child('participants').val().contains(auth.uid) || data.child('participants').val().contains(auth.uid))"
              }
            },
            "messages": {
              "$conversationId": {
                ".read": "auth != null && root.child('conversations').child($conversationId).child('participants').val().contains(auth.uid)",
                ".write": "auth != null && root.child('conversations').child($conversationId).child('participants').val().contains(auth.uid)",
                "$messageId": {
                  ".validate": "newData.child('senderId').val() === auth.uid || data.exists()"
                }
              }
            }
          }
        }
        """
    }
    
    private func setupAuthStateListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                // Tự động tải cuộc trò chuyện khi đăng nhập
                self?.loadConversations()
            } else {
                self?.clearData()
            }
        }
    }
    
    @objc private func handleNewMessage(_ notification: Notification) {
        // Cập nhật danh sách cuộc trò chuyện khi có tin nhắn mới
        loadConversations()
    }
    
    private func clearData() {
        DispatchQueue.main.async {
            self.conversations = []
            self.messages = []
            self.currentConversation = nil
            self.unreadConversationsCount = 0
            self.removeObservers()
        }
    }
    
    private func removeObservers() {
        // Xóa tất cả observers cho messages
        if let messagesRef = messagesRef {
            for handle in messagesObservers {
                messagesRef.removeObserver(withHandle: handle)
            }
        }
        messagesObservers.removeAll()
        
        // Xóa observer cho conversations
        if let conversationsRef = conversationsRef, let handle = conversationsObserver {
            conversationsRef.removeObserver(withHandle: handle)
        }
        conversationsObserver = nil
    }
    
    // MARK: - Conversations
    
    func loadConversations() {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            self.errorMessage = "Người dùng chưa đăng nhập"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        var hasCompleted = false
        let timeoutTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: false) { [weak self] _ in
            if !hasCompleted {
                hasCompleted = true
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.errorMessage = "Tải dữ liệu quá thời gian. Vui lòng thử lại."
                }
            }
        }
        
        initializeDatabaseIfNeeded { [weak self] success in
            guard let self = self else {
                timeoutTimer.invalidate()
                return
            }
            
            if !success {
                timeoutTimer.invalidate()
                if !hasCompleted {
                    hasCompleted = true
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.errorMessage = "Không thể khởi tạo database"
                    }
                }
                return
            }
            
            // Xóa observer cũ nếu có
            if let conversationsRef = self.conversationsRef, let handle = self.conversationsObserver {
                conversationsRef.removeObserver(withHandle: handle)
            }
            
            // Tham chiếu đến nút conversations
            self.conversationsRef = self.db.child("conversations")
            
            // Kiểm tra xem nút conversations có tồn tại không
            self.conversationsRef?.observeSingleEvent(of: .value) { snapshot in
                if !snapshot.exists() {
                    // Tạo nút conversations nếu chưa tồn tại
                    self.db.child("conversations").setValue([:]) { error, _ in
                        timeoutTimer.invalidate()
                        if !hasCompleted {
                            hasCompleted = true
                            if let error = error {
                                DispatchQueue.main.async {
                                    self.isLoading = false
                                    self.errorMessage = "Không thể tạo nút conversations: \(error.localizedDescription)"
                                }
                            } else {
                                DispatchQueue.main.async {
                                    self.isLoading = false
                                    self.conversations = []
                                }
                            }
                        }
                    }
                    return
                }
                
                // Lắng nghe thay đổi trong conversations
                self.conversationsObserver = self.conversationsRef?.observe(.value) { snapshot in
                    timeoutTimer.invalidate()
                    if hasCompleted { return }
                    hasCompleted = true
                    
                    var newConversations: [ChatConversation] = []
                    
                    for child in snapshot.children {
                        guard let childSnapshot = child as? DataSnapshot else {
                            continue
                        }
                        
                        guard let conversation = ChatConversation.fromSnapshot(childSnapshot) else {
                            continue
                        }
                        
                        // Chỉ lấy các cuộc trò chuyện mà người dùng hiện tại tham gia
                        if conversation.participants.contains(currentUserId) {
                            newConversations.append(conversation)
                        }
                    }
                    
                    // Sắp xếp theo thời gian cập nhật mới nhất
                    newConversations.sort { $0.updatedAt > $1.updatedAt }
                    
                    DispatchQueue.main.async {
                        self.conversations = newConversations
                        self.isLoading = false
                        self.updateUnreadCount()
                        
                        // Đảm bảo thông tin người dùng được tải
                        self.loadUserInfoForConversations()
                    }
                }
            }
        }
    }
    
    // Tải thông tin người dùng cho tất cả các cuộc trò chuyện
    private func loadUserInfoForConversations() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        for conversation in conversations {
            // Lấy ID người dùng khác trong cuộc trò chuyện
            if let otherUserId = conversation.participants.first(where: { $0 != currentUserId }) {
                // Tải thông tin người dùng từ Firestore
                let userRef = Firestore.firestore().collection("users").document(otherUserId)
                userRef.getDocument { snapshot, error in
                    if let error = error {
                        print("Error loading user info: \(error.localizedDescription)")
                        return
                    }
                    
                    if let data = snapshot?.data() {
                        // Cập nhật thông tin người dùng vào cuộc trò chuyện
                        NotificationCenter.default.post(
                            name: .userProfileLoaded,
                            object: nil,
                            userInfo: [
                                "userId": otherUserId,
                                "userData": data
                            ]
                        )
                    }
                }
            }
        }
    }
    
    func createOrGetConversation(with userId: String, completion: @escaping (Result<ChatConversation, Error>) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "ChatManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Người dùng chưa đăng nhập"])))
            return
        }
        
        // Sắp xếp ID người dùng để tạo ID cuộc trò chuyện nhất quán
        let participants = [currentUserId, userId].sorted()
        let conversationId = participants.joined(separator: "_")
        
        // Kiểm tra xem cuộc trò chuyện đã tồn tại chưa
        let conversationRef = db.child("conversations").child(conversationId)
        
        conversationRef.observeSingleEvent(of: .value) { [weak self] snapshot in
            if snapshot.exists() {
                // Cuộc trò chuyện đã tồn tại
                if let conversation = ChatConversation.fromSnapshot(snapshot) {
                    completion(.success(conversation))
                } else {
                    completion(.failure(NSError(domain: "ChatManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Không thể đọc dữ liệu cuộc trò chuyện"])))
                }
            } else {
                // Tạo cuộc trò chuyện mới
                let newConversation = ChatConversation(
                    id: conversationId,
                    participants: participants,
                    lastMessage: nil,
                    unreadCount: 0,
                    updatedAt: Date().timeIntervalSince1970
                )
                
                conversationRef.setValue(newConversation.toDict()) { error, _ in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(newConversation))
                    }
                }
            }
        }
    }
    
    // MARK: - Messages
    
    func loadMessages(for conversationId: String) {
        isLoading = true
        errorMessage = nil
        
        // Đặt timeout để tránh treo vô hạn
        var hasCompleted = false
        let timeoutTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: false) { [weak self] _ in
            if !hasCompleted {
                hasCompleted = true
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.errorMessage = "Tải tin nhắn quá thời gian. Vui lòng thử lại."
                }
            }
        }
        
        // Khởi tạo database nếu cần
        initializeDatabaseIfNeeded { [weak self] success in
            guard let self = self else {
                timeoutTimer.invalidate()
                return
            }
            
            if !success {
                timeoutTimer.invalidate()
                if !hasCompleted {
                    hasCompleted = true
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.errorMessage = "Không thể khởi tạo database"
                    }
                }
                return
            }
            
            // Xóa tất cả observers cũ nếu có
            if let messagesRef = self.messagesRef {
                for handle in self.messagesObservers {
                    messagesRef.removeObserver(withHandle: handle)
                }
            }
            self.messagesObservers.removeAll()
            
            // Tham chiếu đến nút messages của cuộc trò chuyện
            self.messagesRef = self.db.child("messages").child(conversationId)
            
            // Kiểm tra xem nút messages có tồn tại không
            self.db.child("messages").observeSingleEvent(of: .value) { snapshot in
                if !snapshot.exists() {
                    // Tạo nút messages nếu chưa tồn tại
                    self.db.child("messages").setValue([:]) { error, _ in
                        if let error = error {
                            timeoutTimer.invalidate()
                            if !hasCompleted {
                                hasCompleted = true
                                DispatchQueue.main.async {
                                    self.isLoading = false
                                    self.errorMessage = "Không thể tạo nút messages: \(error.localizedDescription)"
                                }
                            }
                        } else {
                            self.createMessagesNodeForConversation(conversationId, timeoutTimer: timeoutTimer, hasCompletedRef: &hasCompleted)
                        }
                    }
                    return
                }
                
                // Kiểm tra xem nút messages cho cuộc trò chuyện có tồn tại không
                self.messagesRef?.observeSingleEvent(of: .value) { snapshot in
                    if !snapshot.exists() {
                        self.createMessagesNodeForConversation(conversationId, timeoutTimer: timeoutTimer, hasCompletedRef: &hasCompleted)
                        return
                    }
                    
                    // Lắng nghe thay đổi trong messages
                    let handle = self.messagesRef?.observe(.value) { snapshot in
                        timeoutTimer.invalidate()
                        
                        var newMessages: [ChatMessage] = []
                        
                        for child in snapshot.children {
                            guard let childSnapshot = child as? DataSnapshot else {
                                continue
                            }
                            
                            guard let message = ChatMessage.fromSnapshot(childSnapshot) else {
                                continue
                            }
                            
                            newMessages.append(message)
                        }
                        
                        // Sắp xếp theo thời gian
                        newMessages.sort { $0.timestamp < $1.timestamp }
                        
                        DispatchQueue.main.async {
                            self.messages = newMessages
                            self.isLoading = false
                            
                            // Đánh dấu tin nhắn đã đọc
                            self.markMessagesAsRead(conversationId: conversationId)
                            
                            // Thông báo có tin nhắn mới
                            if !newMessages.isEmpty && hasCompleted {
                                NotificationCenter.default.post(name: .newMessageReceived, object: nil, userInfo: [
                                    "conversationId": conversationId,
                                    "message": newMessages.last!
                                ])
                            }
                            
                            hasCompleted = true
                        }
                    }
                    
                    if let handle = handle {
                        self.messagesObservers.append(handle)
                    }
                }
            }
        }
    }
    
    // Tạo nút messages cho cuộc trò chuyện
    private func createMessagesNodeForConversation(_ conversationId: String, timeoutTimer: Timer, hasCompletedRef: UnsafeMutablePointer<Bool>) {
        db.child("messages").child(conversationId).setValue([:]) { [weak self] error, _ in
            guard let self = self else {
                timeoutTimer.invalidate()
                return
            }
            
            timeoutTimer.invalidate()
            if !hasCompletedRef.pointee {
                hasCompletedRef.pointee = true
                
                if let error = error {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.errorMessage = "Không thể tạo nút messages cho cuộc trò chuyện: \(error.localizedDescription)"
                    }
                } else {
                    print("DEBUG: Đã tạo nút messages cho cuộc trò chuyện \(conversationId)")
                    
                    DispatchQueue.main.async {
                        self.messages = []
                        self.isLoading = false
                    }
                }
            }
        }
    }
    
    // MARK: - Sending Messages
    
    func sendTextMessage(_ text: String, to userId: String, in conversationId: String, completion: @escaping (Result<ChatMessage, Error>) -> Void) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            completion(.failure(NSError(domain: "ChatManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Tin nhắn không được để trống"])))
            return
        }
        
        sendMessage(to: userId, content: text, type: .text, conversationId: conversationId, completion: completion)
    }
    
    func sendImageMessage(_ image: UIImage, to userId: String, in conversationId: String, completion: @escaping (Result<ChatMessage, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            completion(.failure(NSError(domain: "ChatManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Không thể xử lý ảnh"])))
            return
        }
        
        uploadImage(imageData: imageData) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let imageUrl):
                self.sendMessage(to: userId, content: imageUrl, type: .image, conversationId: conversationId, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func sendTextMessage(to userId: String, text: String, completion: @escaping (Result<ChatMessage, Error>) -> Void) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            completion(.failure(NSError(domain: "ChatManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Tin nhắn không được để trống"])))
            return
        }
        
        createOrGetConversation(with: userId) { [weak self] result in
            switch result {
            case .success(let conversation):
                self?.sendMessage(to: userId, content: text, type: .text, conversationId: conversation.id, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func sendImageMessage(to userId: String, image: UIImage, completion: @escaping (Result<ChatMessage, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            completion(.failure(NSError(domain: "ChatManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Không thể xử lý ảnh"])))
            return
        }
        
        createOrGetConversation(with: userId) { [weak self] result in
            switch result {
            case .success(let conversation):
                self?.uploadImage(imageData: imageData) { result in
                    switch result {
                    case .success(let imageUrl):
                        self?.sendMessage(to: userId, content: imageUrl, type: .image, conversationId: conversation.id, completion: completion)
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func sendMessage(to userId: String, content: String, type: MessageType, conversationId: String, completion: @escaping (Result<ChatMessage, Error>) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "ChatManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Người dùng chưa đăng nhập"])))
            return
        }
        
        let message = ChatMessage(
            senderId: currentUserId,
            receiverId: userId,
            content: content,
            type: type
        )
        
        // Thêm tin nhắn vào nút messages
        let messageRef = db.child("messages").child(conversationId).child(message.id)
        messageRef.setValue(message.toDict()) { error, _ in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Cập nhật thông tin cuộc trò chuyện
            let conversationRef = self.db.child("conversations").child(conversationId)
            
            // Lấy giá trị unreadCount hiện tại
            conversationRef.child("unreadCount").observeSingleEvent(of: .value) { snapshot in
                var unreadCount = snapshot.value as? Int ?? 0
                unreadCount += 1
                
                // Cập nhật cuộc trò chuyện
                let updates: [String: Any] = [
                    "lastMessage": message.toDict(),
                    "updatedAt": message.timestamp,
                    "unreadCount": unreadCount
                ]
                
                conversationRef.updateChildValues(updates) { error, _ in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        // Phát thông báo khi gửi tin nhắn thành công
                        NotificationCenter.default.post(
                            name: .newMessageReceived, 
                            object: nil, 
                            userInfo: [
                                "message": message.toDict(),
                                "conversationId": conversationId,
                                "senderId": message.senderId
                            ]
                        )
                        completion(.success(message))
                    }
                }
            }
        }
    }
    
    private func uploadImage(imageData: Data, completion: @escaping (Result<String, Error>) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "ChatManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Người dùng chưa đăng nhập"])))
            return
        }
        
        let filename = "\(UUID().uuidString).jpg"
        let storageRef = storage.reference().child("chat_images/\(currentUserId)/\(filename)")
        
        let uploadTask = storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    completion(.success(url.absoluteString))
                } else {
                    completion(.failure(NSError(domain: "ChatManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Không thể lấy URL ảnh"])))
                }
            }
        }
    }
    
    func markMessagesAsRead(conversationId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Tham chiếu đến nút messages của cuộc trò chuyện
        let messagesRef = db.child("messages").child(conversationId)
        
        // Lấy tất cả tin nhắn chưa đọc gửi đến người dùng hiện tại
        messagesRef.queryOrdered(byChild: "receiverId").queryEqual(toValue: currentUserId).observeSingleEvent(of: .value) { [weak self] snapshot in
            var updates: [String: Any] = [:]
            
            for child in snapshot.children {
                guard let childSnapshot = child as? DataSnapshot,
                      let message = ChatMessage.fromSnapshot(childSnapshot),
                      !message.isRead else {
                    continue
                }
                
                updates["\(childSnapshot.key)/isRead"] = true
            }
            
            if !updates.isEmpty {
                // Cập nhật trạng thái đã đọc cho các tin nhắn
                messagesRef.updateChildValues(updates)
                
                // Đặt lại số lượng tin nhắn chưa đọc trong cuộc trò chuyện
                self?.db.child("conversations").child(conversationId).child("unreadCount").setValue(0)
            }
        }
    }
    
    // Cập nhật số lượng cuộc trò chuyện chưa đọc
    private func updateUnreadCount() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let unreadCount = conversations.reduce(0) { count, conversation in
            if let lastMessage = conversation.lastMessage,
               lastMessage.receiverId == currentUserId && !lastMessage.isRead {
                return count + conversation.unreadCount
            }
            return count
        }
        
        DispatchQueue.main.async {
            self.unreadConversationsCount = unreadCount
        }
    }
    
    func getOtherParticipantId(in conversation: ChatConversation) -> String? {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return nil }
        return conversation.participants.first { $0 != currentUserId }
    }
    
    // MARK: - Debug Helpers
    
    /// Kiểm tra cấu trúc dữ liệu trong Realtime Database
    func debugDatabaseStructure() {
        print("DEBUG: Bắt đầu kiểm tra cấu trúc database...")
        
        // Kiểm tra nút gốc
        db.observeSingleEvent(of: .value) { snapshot in
            print("DEBUG: Nút gốc có tồn tại: \(snapshot.exists())")
            print("DEBUG: Các nút con của nút gốc: \(snapshot.childrenCount)")
            
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot {
                    print("DEBUG: Nút con: \(childSnapshot.key)")
                }
            }
            
            // Kiểm tra nút conversations
            self.db.child("conversations").observeSingleEvent(of: .value) { snapshot in
                print("DEBUG: Nút conversations có tồn tại: \(snapshot.exists())")
                print("DEBUG: Số lượng cuộc trò chuyện: \(snapshot.childrenCount)")
            }
            
            // Kiểm tra nút messages
            self.db.child("messages").observeSingleEvent(of: .value) { snapshot in
                print("DEBUG: Nút messages có tồn tại: \(snapshot.exists())")
                print("DEBUG: Số lượng nút tin nhắn: \(snapshot.childrenCount)")
            }
        }
    }
    
    /// Xóa toàn bộ dữ liệu chat trong Realtime Database (chỉ dùng cho mục đích debug)
    func debugClearAllData(completion: @escaping (Error?) -> Void) {
        let group = DispatchGroup()
        var lastError: Error?
        
        // Xóa nút conversations
        group.enter()
        db.child("conversations").removeValue { error, _ in
            if let error = error {
                lastError = error
            }
            group.leave()
        }
        
        // Xóa nút messages
        group.enter()
        db.child("messages").removeValue { error, _ in
            if let error = error {
                lastError = error
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion(lastError)
        }
    }
} 
