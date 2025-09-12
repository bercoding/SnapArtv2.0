import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @StateObject private var profileManager = UserProfileManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var displayName: String = ""
    @State private var bio: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var avatarImage: UIImage?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingAlert = false
    
    // Gradient colors
    private let gradientColors = [Color.blue, Color.purple]
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.mainGradient
                .ignoresSafeArea()
             
                
                ScrollView {
                    VStack(spacing: 24) {
                        avatarSectionView
                        profileInformationView
                    }
                    .padding(.bottom, 30)
                }
            }
          
            .navigationTitle("Chỉnh sửa hồ sơ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
//                    closeButton
                }
            }
            .onAppear {
                loadCurrentProfile()
            }
            .onChange(of: selectedPhoto) { newValue in
                Task {
                    await loadSelectedPhoto()
                }
            }
            .alert("Lỗi", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "Đã xảy ra lỗi không xác định")
            }
        }
    }
    
    // MARK: - UI Components
    
  
    
//    private var closeButton: some View {
//        Button {
//            dismiss()
//        } label: {
//            Image(systemName: "xmark.circle.fill")
//                .font(.system(size: 20))
//                .foregroundColor(.gray)
//        }
//    }
    
    private var avatarSectionView: some View {
        VStack(spacing: 16) {
            ZStack {
                avatarImageView
                avatarRingView
                cameraPickerButton
            }
            .padding(.top, 20)
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: gradientColors[0]))
            }
        }
        .padding(.bottom, 10)
    }
    
    private var avatarImageView: some View {
        Group {
            if let avatarImage = avatarImage {
                Image(uiImage: avatarImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
            } else {
                AsyncImage(url: URL(string: profileManager.currentUser?.avatarURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 120, height: 120)
                .clipShape(Circle())
            }
        }
    }
    
    private var avatarRingView: some View {
        Circle()
            .stroke(
                LinearGradient(
                    gradient: Gradient(colors: gradientColors),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 3
            )
            .frame(width: 130, height: 130)
    }
    
    private var cameraPickerButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: gradientColors),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 36, height: 36)
                            .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
                        
                        Image(systemName: "camera.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .frame(width: 130, height: 130)
    }
    
    private var profileInformationView: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Thông tin cá nhân")
                .font(.headline)
                .foregroundColor(colorScheme == .dark ? .white : .black.opacity(0.7))
                .padding(.horizontal)
            
            displayNameFieldView
            bioFieldView
            
            if let errorMessage = errorMessage {
                errorMessageView(message: errorMessage)
            }
            
            saveButtonView
        }
        .padding(.vertical)
        .background(colorScheme == .dark ? Color.black.opacity(0.2) : Color.white.opacity(0.7))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
    }
    
    private var displayNameFieldView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tên hiển thị")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            TextField("Nhập tên hiển thị", text: $displayName)
                .padding()
                .background(colorScheme == .dark ? Color.black.opacity(0.2) : Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                .padding(.horizontal)
        }
    }
    
    private var bioFieldView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tiểu sử")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            TextEditor(text: $bio)
                .frame(minHeight: 120)
                .padding(10)
                .background(colorScheme == .dark ? Color.black.opacity(0.2) : Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                .padding(.horizontal)
        }
    }
    
    private func errorMessageView(message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            Text(message)
                .foregroundColor(.red)
                .font(.caption)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var saveButtonView: some View {
        Button {
            Task {
                await saveProfile()
            }
        } label: {
            HStack {
                Spacer()
                Text("Lưu thay đổi")
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: displayName.isEmpty ? [Color.gray] : gradientColors),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .disabled(isLoading || displayName.isEmpty)
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    // MARK: - Helper Methods
    
    private func loadCurrentProfile() {
        if let currentUser = profileManager.currentUser {
            displayName = currentUser.displayName
            bio = currentUser.bio ?? ""
        }
    }
    
    private func loadSelectedPhoto() async {
        guard let selectedPhoto = selectedPhoto else { return }
        
        do {
            if let data = try await selectedPhoto.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    self.avatarImage = image
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Không thể tải ảnh đã chọn: \(error.localizedDescription)"
                self.showingAlert = true
            }
        }
    }
    
    private func saveProfile() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await profileManager.updateProfile(
                displayName: displayName,
                bio: bio.isEmpty ? nil : bio,
                avatar: avatarImage
            )
            
            await MainActor.run {
                self.isLoading = false
                self.dismiss()
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
                self.showingAlert = true
            }
        }
    }
}

#Preview {
    EditProfileView()
}
