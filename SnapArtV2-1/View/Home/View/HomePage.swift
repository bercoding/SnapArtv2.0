import SwiftUI

struct HomePage: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var path = NavigationPath()
    @State private var selectedCategory: FilterCategory? = nil
    @State private var showCamera = false
    @State private var selectedFilter: FilterType? = nil
    
    var body: some View {
        ZStack {
            // Thêm background gradient từ AppTheme
            AppTheme.mainGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header + Category chips (điều hướng sang màn category)
                header
                CategoryChipsView(selectedCategory: $selectedCategory)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                Group {
                    if let cat = selectedCategory {
                        FiltersGrid(category: cat, onSelect: { ft in
                            selectedFilter = ft
                            FilterManager.shared.setFilter(ft)
                            showCamera = true
                        })
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 42, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Chọn một danh mục phía trên để xem các filter")
                                .font(.callout)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white.opacity(0.1)) // Nền mờ cho trạng thái rỗng
                                .padding() // Đệm cho hình chữ nhật
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.clear)

                // Thanh điều hướng dưới cùng
                bottomBar
            }
        }
        .navigationBarBackButtonHidden(true)
        .fullScreenCover(isPresented: $showCamera) {
            CameraViewControllerRepresentable(isPresented: $showCamera)
        }
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("SnapArt")
                    .font(.system(size: 28, weight: .bold, design: .rounded)) // Font lớn và đậm hơn
                    .foregroundColor(.white)
                Text("Tạo ảnh vui theo thời gian thực")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            Spacer()
            
            // Nút đăng xuất (di chuyển lên header)
            Button {
                authViewModel.signOut()
            } label: {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10) // Điều chỉnh padding
        .background(.ultraThinMaterial)
    }
    
    private var bottomBar: some View {
        HStack(spacing: 16) {
            NavigationLink {
                GalleryView()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "photo.on.rectangle")
                        .foregroundColor(.white)
                    Text("Bộ sưu tập") // Đổi tên cho rõ ràng hơn
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            
            // NavigationLink cho FilterView đã được xóa bỏ
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}
