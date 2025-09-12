import SwiftUI

struct FriendsView: View {
    @StateObject private var friendsManager = FriendsManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    @State private var searchText = ""
    @State private var showSearch = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Tab Picker
                Picker("Friends", selection: $selectedTab) {
                    Text("Friends").tag(0)
                    Text("Requests").tag(1)
                    Text("Search").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content
                TabView(selection: $selectedTab) {
                    // Friends List
                    friendsList
                        .tag(0)
                    
                    // Friend Requests
                    friendRequestsList
                        .tag(1)
                    
                    // Search Users
                    searchUsersView
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                       dismiss()
                    }
                }
            }
        }
    }
    
    private var friendsList: some View {
        List {
            if friendsManager.friends.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.2")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text("No friends yet")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text("Add friends to start sharing your photos!")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .listRowBackground(Color.clear)
            } else {
                ForEach(friendsManager.friends) { friend in
                    FriendRowView(friend: friend)
                }
            }
        }
        .refreshable {
            friendsManager.loadFriends()
        }
    }
    
    private var friendRequestsList: some View {
        List {
            if friendsManager.friendRequests.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text("No friend requests")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text("Friend requests will appear here")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .listRowBackground(Color.clear)
            } else {
                ForEach(friendsManager.friendRequests) { request in
                    FriendRequestRowView(request: request)
                }
            }
        }
        .refreshable {
            friendsManager.loadFriendRequests()
        }
    }
    
    private var searchUsersView: some View {
        VStack {
            // Search Bar
            HStack {
                TextField("Search users...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        searchUsers()
                    }
                
                Button("Search") {
                    searchUsers()
                }
                .disabled(searchText.isEmpty)
            }
            .padding()
            
            // Search Results
            List(friendsManager.searchResults) { user in
                UserSearchRowView(user: user)
            }
        }
    }
    
    private func searchUsers() {
        Task {
            try? await friendsManager.searchUsers(query: searchText)
        }
    }
}

// MARK: - Supporting Views

struct FriendRowView: View {
    let friend: UserProfile
    @State private var showRemoveAlert = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            AsyncImage(url: URL(string: friend.avatarURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.displayName)
                    .font(.headline)
                
                HStack {
                    Circle()
                        .fill(friend.isOnline ? .green : .gray)
                        .frame(width: 8, height: 8)
                    
                    Text(friend.isOnline ? "Online" : "Offline")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Actions
            Menu {
                Button("Remove Friend", role: .destructive) {
                    showRemoveAlert = true
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
            }
        }
        .alert("Remove Friend", isPresented: $showRemoveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                removeFriend()
            }
        } message: {
            Text("Are you sure you want to remove \(friend.displayName) from your friends?")
        }
    }
    
    private func removeFriend() {
        Task {
            try? await FriendsManager.shared.removeFriend(friend.id)
        }
    }
}

struct FriendRequestRowView: View {
    let request: FriendRequest
    @State private var isLoading = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar placeholder
            Circle()
                .fill(.gray.opacity(0.3))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(.gray)
                )
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text("Friend Request")
                    .font(.headline)
                
                Text("From: \(request.fromUserId)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 8) {
                Button("Accept") {
                    acceptRequest()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading)
                
                Button("Reject") {
                    rejectRequest()
                }
                .buttonStyle(.bordered)
                .disabled(isLoading)
            }
        }
    }
    
    private func acceptRequest() {
        isLoading = true
        Task {
            try? await FriendsManager.shared.acceptFriendRequest(request.id)
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
    
    private func rejectRequest() {
        isLoading = true
        Task {
            try? await FriendsManager.shared.rejectFriendRequest(request.id)
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
}

struct UserSearchRowView: View {
    let user: UserProfile
    @State private var isSendingRequest = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            AsyncImage(url: URL(string: user.avatarURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName)
                    .font(.headline)
                
                if let bio = user.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Add Friend Button
            Button("Add Friend") {
                sendFriendRequest()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSendingRequest)
        }
    }
    
    private func sendFriendRequest() {
        isSendingRequest = true
        Task {
            try? await FriendsManager.shared.sendFriendRequest(to: user.id)
            DispatchQueue.main.async {
                self.isSendingRequest = false
            }
        }
    }
}

#Preview {
    FriendsView()
}
