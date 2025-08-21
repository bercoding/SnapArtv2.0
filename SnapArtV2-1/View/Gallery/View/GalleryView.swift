
import SwiftUI

struct GalleryView: View {
    @StateObject private var viewModel = GalleryViewModel()
    @State private var showingImageDetail = false
    @State private var showingDeleteConfirmation = false
    @State private var imageToDelete: UUID?
    @State private var gridColumns = [GridItem(.adaptive(minimum: 100))]
    @Environment(\.dismiss) var dismiss
    @State private var showAlert: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                AppTheme.mainGradient
                    .ignoresSafeArea()
                
                // Content
                VStack {
                    ScrollView {
                        if viewModel.isLoading {
                            ProgressView("Đang tải ảnh...")
                                .padding()
                                .foregroundColor(.white)
                        } else if viewModel.images.isEmpty {
                            emptyGalleryView
                        } else {
                            imageGridView
                        }
                    }
                    .refreshable {
                        viewModel.fetchSavedImages()
                    }
                }
                
                // Error message
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(10)
                        .shadow(radius: 3)
                        .transition(.move(edge: .bottom))
                        .zIndex(1)
                        .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 100)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                viewModel.errorMessage = nil
                            }
                        }
                }
            }
            .navigationTitle("Thư viện ảnh")
            .foregroundColor(.white)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            gridColumns = [GridItem(.adaptive(minimum: 100))]
                        }) {
                            Label("Hiển thị nhỏ", systemImage: "square.grid.3x3")
                        }
                        
                        Button(action: {
                            gridColumns = [GridItem(.adaptive(minimum: 150))]
                        }) {
                            Label("Hiển thị vừa", systemImage: "square.grid.2x2")
                        }
                        
                        Button(action: {
                            showingDeleteConfirmation = true
                        }) {
                            Label("Xóa tất cả", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.white)
                    }
                }
            }
            .alert("Xác nhận xóa", isPresented: $showingDeleteConfirmation) {
                Button("Hủy", role: .cancel) {}
                Button("Xóa tất cả", role: .destructive) {
                    viewModel.deleteAllImages()
                }
            } message: {
                Text("Bạn có chắc muốn xóa tất cả ảnh? Hành động này không thể hoàn tác.")
            }
        }
        .sheet(isPresented: $showingImageDetail) {
            if let selectedImage = viewModel.selectedImage, let uiImage = selectedImage.image {
                DetailImage(image: uiImage, dateCreated: selectedImage.createdAt, filterType: selectedImage.filterType, onDelete: {
                    // Delete action
                    if let id = viewModel.selectedImage?.id {
                        viewModel.deleteImage(withId: id)
                    }
                    showingImageDetail = false
                })
            }
        }
    }
    
    // Grid view hiển thị các ảnh
    private var imageGridView: some View {
        LazyVGrid(columns: gridColumns, spacing: 3) {
            ForEach(viewModel.images, id: \.id) { galleryImage in
                if let thumbnail = galleryImage.thumbnail {
                    Button(action: {
                        viewModel.selectedImage = galleryImage
                        showingImageDetail = true
                    }) {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 100)
                            .clipped()
                            .cornerRadius(3)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(3)
    }
    
    // View khi gallery trống
    private var emptyGalleryView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.white)
                .padding()
            
            Text("Chưa có ảnh nào")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Text("Chụp ảnh từ camera để lưu vào thư viện")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct GalleryView_Previews: PreviewProvider {
    static var previews: some View {
        GalleryView()
    }
}
