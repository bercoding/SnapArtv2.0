import FirebaseAuth
import FirebaseDatabase
import FirebaseFirestore
import PhotosUI
import SwiftUI

struct ChatView: View {
    let otherUserId: String
    let otherUserName: String
    
    @StateObject private var chatManager = ChatManager.shared
    @StateObject private var profileManager = UserProfileManager.shared
    @State private var messageText = ""
    @State private var selectedImage: UIImage?
    @State private var isShowingImagePicker = false
    @State private var conversationId: String?
    @State private var scrollToBottom = false
    @State private var showError = false
    @State private var isInitializing = false
    @State private var lastMessageId: String?
    @State private var otherUserProfile: UserProfile?
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "chevron.left")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal)

                }
               
                chatHeader
                Spacer()
            }
            
            if isInitializing {
                initializingView
            } else if chatManager.isLoading && chatManager.messages.isEmpty {
                loadingView
            } else if let errorMessage = chatManager.errorMessage {
                errorView(message: errorMessage)
            } else {
                messagesView
            }
            
            inputView
        }
        .navigationBarBackButtonHidden(true)
        .background(AppTheme.mainGradient.ignoresSafeArea())
        .onAppear {
            setupConversation()
            loadUserProfile()
        }
        .onDisappear {
            // Khi rời khỏi màn hình, hủy đăng ký các observer
            if let messagesRef = chatManager.messagesRef {
                for handle in chatManager.messagesObservers {
                    messagesRef.removeObserver(withHandle: handle)
                }
            }
            chatManager.messagesObservers.removeAll()
        }
        .alert("Lỗi", isPresented: $showError) {
            Button("Thử lại") {
                setupConversation()
            }
            Button("Đóng", role: .cancel) {}
        } message: {
            Text(chatManager.errorMessage ?? "Không thể tải tin nhắn")
        }
        .onChange(of: chatManager.errorMessage) { newValue in
            showError = newValue != nil
        }
        .onReceive(NotificationCenter.default.publisher(for: .newMessageReceived)) { notification in
            // Kiểm tra xem tin nhắn mới có thuộc về cuộc trò chuyện hiện tại không
            if let notificationConversationId = notification.userInfo?["conversationId"] as? String,
               notificationConversationId == conversationId
            {
                // Cuộn xuống tin nhắn mới nhất
                scrollToBottom = true
            }
        }
    }
    
    private var chatHeader: some View {
        HStack(spacing: 12) {
            // Avatar
            AsyncImage(url: URL(string: otherUserProfile?.avatarURL ?? "")) { phase in
                switch phase {
                case .empty:
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                        )
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                case .failure:
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                        )
                @unknown default:
                    EmptyView()
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(otherUserProfile?.displayName ?? otherUserName)
                    .font(.headline)
                    .foregroundColor(.white)
                
                if otherUserProfile?.isOnline == true {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("Online")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
        }
    }
    
    private var initializingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            Text("Đang khởi tạo database...")
                .foregroundColor(.white)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            Text("Đang tải tin nhắn...")
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 70))
                .foregroundColor(.red)
            
            Text("Lỗi")
                .font(.headline)
                .foregroundColor(.white)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                setupConversation()
            }) {
                Text("Thử lại")
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var messagesView: some View {
        ScrollViewReader { scrollView in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(chatManager.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // Anchor view for scrolling to bottom
                    Color.clear
                        .frame(height: 1)
                        .id("bottomID")
                }
            }
            .onChange(of: chatManager.messages.count) { _ in
                // Kiểm tra xem có tin nhắn mới không
                if let lastMessage = chatManager.messages.last, lastMessage.id != lastMessageId {
                    lastMessageId = lastMessage.id
                    withAnimation {
                        scrollView.scrollTo("bottomID", anchor: .bottom)
                    }
                }
            }
            .onChange(of: scrollToBottom) { newValue in
                if newValue {
                    withAnimation {
                        scrollView.scrollTo("bottomID", anchor: .bottom)
                    }
                    scrollToBottom = false
                }
            }
            .onAppear {
                // Cuộn xuống dưới khi view xuất hiện
                if let lastMessage = chatManager.messages.last {
                    lastMessageId = lastMessage.id
                }
                withAnimation {
                    scrollView.scrollTo("bottomID", anchor: .bottom)
                }
            }
        }
    }
    
    private var inputView: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.3))
            
            HStack(spacing: 12) {
                Button(action: {
                    isShowingImagePicker = true
                }) {
                    Image(systemName: "photo")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                .disabled(isInitializing || chatManager.isLoading)
                
                TextField("Nhập tin nhắn...", text: $messageText)
                    .padding(10)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(20)
                    .foregroundColor(.white)
                    .disabled(isInitializing || chatManager.isLoading)
                
                Button(action: {
                    sendTextMessage()
                }) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20))
                        .foregroundColor(messageText.isEmpty ? .gray : .white)
                }
                .disabled(messageText.isEmpty || isInitializing || chatManager.isLoading)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .sheet(isPresented: $isShowingImagePicker) {
            ImagePicker(image: $selectedImage, onImagePicked: { image in
                if let image = image {
                    sendImageMessage(image: image)
                }
            })
        }
    }
    
    private func loadUserProfile() {
        Task {
            do {
                let profile = try await profileManager.getUserProfile(userId: otherUserId)
                await MainActor.run {
                    self.otherUserProfile = profile
                }
            } catch {
                print("Error loading user profile: \(error.localizedDescription)")
            }
        }
    }
    
    private func setupConversation() {
        chatManager.errorMessage = nil
        isInitializing = true
        
        // Khởi tạo database và tải tin nhắn
        chatManager.initializeDatabaseIfNeeded { success in
            if success {
                chatManager.createOrGetConversation(with: otherUserId) { result in
                    DispatchQueue.main.async {
                        self.isInitializing = false
                        
                        switch result {
                        case .success(let conversation):
                            self.conversationId = conversation.id
                            // Tải tin nhắn và thiết lập observer
                            chatManager.loadMessages(for: conversation.id)
                            
                            // Đảm bảo đã thiết lập observer cho tin nhắn mới
                            self.setupMessageObserver(for: conversation.id)
                        case .failure(let error):
                            chatManager.isLoading = false
                            chatManager.errorMessage = "Không thể tạo cuộc trò chuyện: \(error.localizedDescription)"
                            showError = true
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.isInitializing = false
                    chatManager.isLoading = false
                    chatManager.errorMessage = "Không thể khởi tạo database. Vui lòng thử lại."
                    showError = true
                }
            }
        }
    }
    
    private func setupMessageObserver(for conversationId: String) {
        // Kiểm tra xem đã có observer chưa
        if chatManager.messagesObservers.isEmpty {
            // Thiết lập observer cho tin nhắn mới
            let messagesRef = Database.database().reference().child("messages").child(conversationId)
            
            let handle = messagesRef.observe(.childAdded) { snapshot, _ in
                if let message = ChatMessage.fromSnapshot(snapshot) {
                    DispatchQueue.main.async {
                        // Kiểm tra xem tin nhắn đã tồn tại trong danh sách chưa
                        if !chatManager.messages.contains(where: { $0.id == message.id }) {
                            chatManager.messages.append(message)
                            // Sắp xếp tin nhắn theo thời gian
                            chatManager.messages.sort { $0.timestamp < $1.timestamp }
                            // Cuộn xuống tin nhắn mới nhất
                            scrollToBottom = true
                        }
                    }
                }
            }
            
            chatManager.messagesObservers.append(handle)
        }
    }
    
    private func sendTextMessage() {
        guard !messageText.isEmpty, let conversationId = conversationId else { return }
        
        let text = messageText
        messageText = ""
        
        // Cuộn xuống dưới khi gửi tin nhắn
        scrollToBottom = true
        
        chatManager.sendTextMessage(text, to: otherUserId, in: conversationId) { result in
            switch result {
            case .success(let message):
                // Thêm tin nhắn vào danh sách ngay lập tức
                DispatchQueue.main.async {
                    if !chatManager.messages.contains(where: { $0.id == message.id }) {
                        chatManager.messages.append(message)
                        // Sắp xếp tin nhắn theo thời gian
                        chatManager.messages.sort { $0.timestamp < $1.timestamp }
                        // Cuộn xuống tin nhắn mới nhất
                        scrollToBottom = true
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    chatManager.errorMessage = "Không thể gửi tin nhắn: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    private func sendImageMessage(image: UIImage) {
        guard let conversationId = conversationId else { return }
        
        // Cuộn xuống dưới khi gửi tin nhắn
        scrollToBottom = true
        
        chatManager.sendImageMessage(image, to: otherUserId, in: conversationId) { result in
            switch result {
            case .success(let message):
                // Thêm tin nhắn vào danh sách ngay lập tức
                DispatchQueue.main.async {
                    if !chatManager.messages.contains(where: { $0.id == message.id }) {
                        chatManager.messages.append(message)
                        // Sắp xếp tin nhắn theo thời gian
                        chatManager.messages.sort { $0.timestamp < $1.timestamp }
                        // Cuộn xuống tin nhắn mới nhất
                        scrollToBottom = true
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    chatManager.errorMessage = "Không thể gửi hình ảnh: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    private var isFromCurrentUser: Bool {
        return message.senderId == Auth.auth().currentUser?.uid
    }
    
    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer() }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 5) {
                if message.type == .image {
                    AsyncImage(url: URL(string: message.content)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 200, height: 200)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: 200, maxHeight: 200)
                                .cornerRadius(10)
                        case .failure:
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .frame(width: 200, height: 200)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(10)
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Text(message.content)
                        .padding(10)
                        .background(isFromCurrentUser ? Color.blue : Color.gray.opacity(0.4))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Text(formatTime(message.date))
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            if !isFromCurrentUser { Spacer() }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var onImagePicked: (UIImage?) -> Void
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            guard let provider = results.first?.itemProvider else {
                parent.onImagePicked(nil)
                return
            }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.image = image as? UIImage
                        self.parent.onImagePicked(image as? UIImage)
                    }
                }
            }
        }
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ChatView(otherUserId: "previewUserId", otherUserName: "Người dùng")
        }
    }
}
