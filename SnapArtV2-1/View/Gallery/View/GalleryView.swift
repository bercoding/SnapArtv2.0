
import SwiftUI

struct GalleryView: View {
    @StateObject private var viewModel = GalleryViewModel()
    @StateObject private var interstitialAdManager = InterstitialAdManager.shared
    @State private var showingImageDetail = false
    @State private var showingDeleteConfirmation = false
    @State private var imageToDelete: UUID?
    @State private var gridColumns = [GridItem(.adaptive(minimum: 100))]
    @Environment(\.dismiss) var dismiss
    @State private var showAlert: Bool = false
    @EnvironmentObject private var languageViewModel: LanguageViewModel
    
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
                            ProgressView(NSLocalizedString("Đang tải ảnh...", comment: "Loading photos"))
                                .padding()
                                .foregroundColor(.white)
                                .id(languageViewModel.refreshID)
                        } else if viewModel.images.isEmpty {
                            emptyGalleryView
                        } else {
                            imageGridView
                        }
                    }
                    .refreshable {
                        // Hiện Interstitial Ad khi refresh Gallery
                        if UserProfileManager.shared.currentUser?.stats.premiumStatus != true {
                            print("Attempting to show interstitial ad from GalleryView")
                            interstitialAdManager.showInterstitialAd()
                        }
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
            .navigationTitle(NSLocalizedString("Thư viện ảnh", comment: "Gallery"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            gridColumns = [GridItem(.adaptive(minimum: 100))]
                        }) {
                            Label(NSLocalizedString("Hiển thị nhỏ", comment: "Small grid"), systemImage: "square.grid.3x3")
                                .id(languageViewModel.refreshID)
                        }
                        
                        Button(action: {
                            gridColumns = [GridItem(.adaptive(minimum: 150))]
                        }) {
                            Label(NSLocalizedString("Hiển thị vừa", comment: "Medium grid"), systemImage: "square.grid.2x2")
                                .id(languageViewModel.refreshID)
                        }
                        
                        Button(action: {
                            showingDeleteConfirmation = true
                        }) {
                            Label(NSLocalizedString("Xóa tất cả", comment: "Delete all"), systemImage: "trash")
                                .id(languageViewModel.refreshID)
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.white)
                    }
                }
            }
            .alert(NSLocalizedString("Xác nhận xóa", comment: "Delete confirmation"), isPresented: $showingDeleteConfirmation) {
                Button(NSLocalizedString("Hủy", comment: "Cancel"), role: .cancel) {}
                Button(NSLocalizedString("Xóa tất cả", comment: "Delete all"), role: .destructive) {
                    viewModel.deleteAllImages()
                }
            } message: {
                Text(NSLocalizedString("Bạn có chắc muốn xóa tất cả ảnh? Hành động này không thể hoàn tác.", comment: "Delete all confirmation message"))
            }
           
        }
        .id(languageViewModel.refreshID)
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
        .withBannerAd(adUnitId: "ca-app-pub-3940256099942544/2934735716")
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
            
            Text(NSLocalizedString("Chưa có ảnh nào", comment: "No photos yet"))
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .id(languageViewModel.refreshID)
            
            Text(NSLocalizedString("Chụp ảnh từ camera để lưu vào thư viện", comment: "Take photos from camera to save to gallery"))
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .id(languageViewModel.refreshID)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct GalleryView_Previews: PreviewProvider {
    static var previews: some View {
        GalleryView()
            .environmentObject(LanguageViewModel())
    }
}

