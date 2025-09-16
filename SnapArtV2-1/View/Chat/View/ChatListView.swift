import SwiftUI
import FirebaseAuth
import FirebaseDatabase
import FirebaseCore
import FirebaseFirestore

struct ChatListView: View {
    @StateObject private var viewModel = ChatListViewModel()
    @ObservedObject private var chatManager = ChatManager.shared
    @ObservedObject private var friendsManager = FriendsManager.shared
    @State private var selectedTab = 0
    @State private var selectedFriend: UserProfile?
    @State private var showChatSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.mainGradient
                    .ignoresSafeArea()
                
                VStack {
                    // Tab Picker
                    Picker("", selection: $selectedTab) {
                        Text("Tin nhắn").tag(0)
                        Text("Bạn bè").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    searchBar
                    
                    // Tab Content
                    if selectedTab == 0 {
                        // Tin nhắn Tab
                        if viewModel.showingSearchResults {
                            searchResultsList
                        } else {
                            conversationsList
                        }
                    } else {
                        // Bạn bè Tab
                        friendsList
                    }
                    
                    if viewModel.isInitializing {
                        ProgressView("Đang khởi tạo database...")
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    if let errorMessage = chatManager.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(10)
                            .padding()
                    }
                }
            }
            .navigationTitle(selectedTab == 0 ? "Tin nhắn" : "Bạn bè")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            chatManager.loadConversations()
                            friendsManager.loadFriends()
                        }) {
                            Label("Làm mới", systemImage: "arrow.clockwise")
                        }
                        
                        Button(action: {
                            viewModel.initializeDatabase()
                        }) {
                            Label("Khởi tạo Database", systemImage: "square.and.pencil")
                        }
                        
                        #if DEBUG
                        Button(action: {
                            chatManager.debugDatabaseStructure()
                        }) {
                            Label("Kiểm tra cấu trúc DB", systemImage: "magnifyingglass")
                        }
                        
                        Button(action: {
                            showDebugAlert = true
                        }) {
                            Label("Xóa toàn bộ dữ liệu", systemImage: "trash")
                        }
                        #endif
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.white)
                    }
                }
            }
            .onAppear {
                chatManager.loadConversations()
                friendsManager.loadFriends()
                friendsManager.loadFriendRequests()
            }
            .onReceive(NotificationCenter.default.publisher(for: .newMessageReceived)) { _ in
                // Tự động làm mới danh sách khi có tin nhắn mới
                chatManager.loadConversations()
            }
            .alert("Xóa dữ liệu", isPresented: $showDebugAlert) {
                Button("Xóa", role: .destructive) {
                    chatManager.debugClearAllData { _ in }
                }
                Button("Hủy", role: .cancel) {}
            } message: {
                Text("Bạn có chắc chắn muốn xóa toàn bộ dữ liệu chat không? Hành động này không thể hoàn tác.")
            }
            .sheet(item: $selectedFriend) { friend in
                NavigationView {
                    ChatView(otherUserId: friend.id, otherUserName: friend.displayName)
                }
            }
        }
    }
    
    // MARK: - UI Components
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.7))
            
            TextField(selectedTab == 0 ? "Tìm kiếm tin nhắn..." : "Tìm kiếm bạn bè...", text: $viewModel.searchText)
                .foregroundColor(.white)
                .onChange(of: viewModel.searchText) { newValue in
                    if selectedTab == 0 {
                        viewModel.performSearch()
                    } else {
                        // Tìm kiếm bạn bè
                        Task {
                            try? await friendsManager.searchUsers(query: newValue)
                        }
                    }
                }
            
            if !viewModel.searchText.isEmpty {
                Button(action: {
                    viewModel.clearSearch()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.2))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var conversationsList: some View {
        Group {
            if chatManager.isLoading && chatManager.conversations.isEmpty {
                loadingView
            } else if chatManager.conversations.isEmpty {
                emptyConversationsView
            } else {
                List {
                    ForEach(chatManager.conversations.sorted(by: { $0.updatedAt > $1.updatedAt })) { conversation in
                        NavigationLink {
                            if let otherUserId = chatManager.getOtherParticipantId(in: conversation) {
                                ChatView(
                                    otherUserId: otherUserId,
                                    otherUserName: getUserName(userId: otherUserId)
                                )
                            }
                        } label: {
                            ConversationRow(conversation: conversation)
                        }
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(PlainListStyle())
                .background(Color.clear)
            }
        }
    }
    
    private var friendsList: some View {
        Group {
            if friendsManager.isLoading && friendsManager.friends.isEmpty {
                loadingView
            } else if friendsManager.friends.isEmpty {
                emptyFriendsView
            } else {
                List {
                    // Danh sách bạn bè
                    Section(header: Text("Bạn bè").foregroundColor(.white)) {
                        ForEach(friendsManager.friends) { friend in
                            Button(action: {
                                selectedFriend = friend
                            }) {
                                FriendRow(friend: friend)
                            }
                            .listRowBackground(Color.clear)
                        }
                    }
                    
                    // Lời mời kết bạn
                    if !friendsManager.friendRequests.isEmpty {
                        Section(header: Text("Lời mời kết bạn").foregroundColor(.white)) {
                            ForEach(friendsManager.friendRequests) { request in
                                FriendRequestRow(request: request)
                                    .listRowBackground(Color.clear)
                            }
                        }
                    }
                    
                    // Kết quả tìm kiếm
                    if !viewModel.searchText.isEmpty && !friendsManager.searchResults.isEmpty {
                        Section(header: Text("Kết quả tìm kiếm").foregroundColor(.white)) {
                            ForEach(friendsManager.searchResults) { user in
                                UserSearchRow(user: user)
                                    .listRowBackground(Color.clear)
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .background(Color.clear)
            }
        }
        .refreshable {
            friendsManager.loadFriends()
            friendsManager.loadFriendRequests()
        }
    }
    
    private var searchResultsList: some View {
        Group {
            if viewModel.searchText.isEmpty {
                EmptyView()
            } else if viewModel.searchResults.isEmpty && !viewModel.searchText.isEmpty {
                VStack {
                    Text("Không tìm thấy người dùng")
                        .foregroundColor(.white)
                        .padding()
                    
                    Spacer()
                }
            } else {
                List {
                    ForEach(viewModel.searchResults) { user in
                        NavigationLink {
                            ChatView(
                                otherUserId: user.id,
                                otherUserName: user.displayName
                            )
                        } label: {
                            UserSearchRow(user: user)
                        }
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(PlainListStyle())
                .background(Color.clear)
            }
        }
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            Text(selectedTab == 0 ? "Đang tải cuộc trò chuyện..." : "Đang tải danh sách bạn bè...")
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyConversationsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 70))
                .foregroundColor(.white.opacity(0.7))
            
            Text("Không có cuộc trò chuyện nào")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Tìm kiếm người dùng để bắt đầu trò chuyện")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyFriendsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2")
                .font(.system(size: 70))
                .foregroundColor(.white.opacity(0.7))
            
            Text("Chưa có bạn bè nào")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Tìm kiếm người dùng để kết bạn và trò chuyện")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helpers
    
    func getUserName(userId: String) -> String {
        // Tìm cuộc trò chuyện có chứa người dùng này
        if let conversation = chatManager.conversations.first(where: { conv in
            conv.participants.contains(userId)
        }) {
            // Tìm row view model tương ứng để lấy tên
            let viewModel = ConversationRowViewModel(conversation: conversation)
            return viewModel.otherUserDisplayName
        }
        return "Người dùng"
    }
    
    // MARK: - State
    
    @State private var showDebugAlert = false
}

// Để UserProfile có thể được sử dụng với @State
extension UserProfile: Hashable {
    public static func == (lhs: UserProfile, rhs: UserProfile) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct FriendRow: View {
    let friend: UserProfile
    @State private var showActionSheet = false
    @ObservedObject private var friendsManager = FriendsManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            AsyncImage(url: URL(string: friend.avatarURL ?? "")) { phase in
                switch phase {
                case .empty:
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                        )
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                case .failure:
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                        )
                @unknown default:
                    EmptyView()
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Name
                Text(friend.displayName)
                    .font(.headline)
                    .foregroundColor(.white)
                
                // Status
                HStack {
                    Circle()
                        .fill(friend.isOnline ? .green : .gray)
                        .frame(width: 8, height: 8)
                    
                    Text(friend.isOnline ? "Online" : "Offline")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Spacer()
            
            Button(action: {
                showActionSheet = true
            }) {
                Image(systemName: "ellipsis")
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.vertical, 8)
        .confirmationDialog("Tùy chọn", isPresented: $showActionSheet) {
            Button("Nhắn tin", role: .none) {
                // Đã được xử lý bởi NavigationLink
            }
            
            Button("Hủy kết bạn", role: .destructive) {
                Task {
                    try? await friendsManager.removeFriend(friend.id)
                }
            }
            
            Button("Hủy", role: .cancel) { }
        }
    }
}

struct FriendRequestRow: View {
    let request: FriendRequest
    @State private var isLoading = false
    @ObservedObject private var friendsManager = FriendsManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar placeholder
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(.gray)
                )
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text("Lời mời kết bạn")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Từ: \(request.fromUserId)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 8) {
                Button(action: {
                    acceptRequest()
                }) {
                    Text("Đồng ý")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(isLoading)
                
                Button(action: {
                    rejectRequest()
                }) {
                    Text("Từ chối")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(isLoading)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func acceptRequest() {
        isLoading = true
        Task {
            try? await friendsManager.acceptFriendRequest(request.id)
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
    
    private func rejectRequest() {
        isLoading = true
        Task {
            try? await friendsManager.rejectFriendRequest(request.id)
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
}

struct ConversationRow: View {
    let conversation: ChatConversation
    @StateObject private var viewModel: ConversationRowViewModel
    
    init(conversation: ChatConversation) {
        self.conversation = conversation
        _viewModel = StateObject(wrappedValue: ConversationRowViewModel(conversation: conversation))
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            if viewModel.isLoadingProfile {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.7)
                    )
            } else {
                AsyncImage(url: URL(string: viewModel.otherUserProfile?.avatarURL ?? "")) { phase in
                    switch phase {
                    case .empty:
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.gray)
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    case .failure:
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Name
                Text(viewModel.otherUserProfile?.displayName ?? "Người dùng")
                    .font(.headline)
                    .foregroundColor(.white)
                
                // Last message
                if let lastMessage = conversation.lastMessage {
                    HStack {
                        if lastMessage.type == .image {
                            Image(systemName: "photo")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            Text("Hình ảnh")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(1)
                        } else {
                            Text(lastMessage.content)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(1)
                        }
                    }
                } else {
                    Text("Bắt đầu cuộc trò chuyện")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.5))
                        .italic()
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                // Time
                if let lastMessage = conversation.lastMessage {
                    Text(formatTime(lastMessage.date))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Unread count
                if conversation.unreadCount > 0 {
                    Text("\(conversation.unreadCount)")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // Helper để định dạng thời gian
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct UserSearchRow: View {
    let user: UserProfile
    @ObservedObject private var friendsManager = FriendsManager.shared
    @State private var isSendingRequest = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            AsyncImage(url: URL(string: user.avatarURL ?? "")) { phase in
                switch phase {
                case .empty:
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                        )
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                case .failure:
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                        )
                @unknown default:
                    EmptyView()
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Name
                Text(user.displayName)
                    .font(.headline)
                    .foregroundColor(.white)
                
                // Email
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Button(action: {
                sendFriendRequest()
            }) {
                Text("Kết bạn")
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(isSendingRequest)
        }
        .padding(.vertical, 8)
    }
    
    private func sendFriendRequest() {
        isSendingRequest = true
        Task {
            try? await friendsManager.sendFriendRequest(to: user.id)
            DispatchQueue.main.async {
                self.isSendingRequest = false
            }
        }
    }
}

struct ChatListView_Previews: PreviewProvider {
    static var previews: some View {
        ChatListView()
    }
} 
