import SwiftUI
import GoogleMobileAds

struct LanguageView: View {
    @EnvironmentObject private var viewModel: LanguageViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var nativeAdManager = NativeAdManager.shared
    @StateObject private var profileManager = UserProfileManager.shared
    @State private var pendingCode: String = ""
    @State private var showDebugAd = false
    
    var body: some View {
        ZStack {
            AppTheme.mainGradient
                .ignoresSafeArea()
            VStack(spacing: 0) {
                // Header
                Header
                
                // Language Display
                scrollView
                
                Spacer(minLength: 0)
                
                // Native Ad ở dưới cùng
                if profileManager.currentUser?.stats.premiumStatus == true {
                    // Không hiển thị quảng cáo cho người dùng premium
                    EmptyView()
                } else {
                    nativeAdView
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10) // Giảm padding dọc
                        .frame(maxHeight: 220) // Giới hạn chiều cao tối đa
                        .onTapGesture(count: 3) {
                            showDebugAd.toggle()
                            print("[LanguageView] Debug ad: \(showDebugAd)")
                            
                            if showDebugAd {
                                // Reset và tải lại quảng cáo
                                nativeAdManager.resetAndReloadAd()
                            }
                        }
                }
            }
        }
        .navigationBarTitle("Ngôn ngữ", displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(
            leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.primary)
            },
            trailing: Button(action: {
                // Áp dụng ngôn ngữ khi nhấn OK (UIKit bundle override)
                if !pendingCode.isEmpty { viewModel.selectedCode = pendingCode }
                viewModel.applyLanguage()
                NotificationCenter.default.post(name: .languageChanged, object: nil)
                presentationMode.wrappedValue.dismiss()
            }) {
                Text(NSLocalizedString("Xong", comment: "Done"))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
        )
        .id(viewModel.refreshID) // Force reload toàn bộ view khi refreshID thay đổi
        .onAppear {
            pendingCode = viewModel.selectedCode
            
            // Hủy tất cả các yêu cầu quảng cáo đang chờ xử lý
            nativeAdManager.cancelLoading()
            
            // Tải quảng cáo khi view xuất hiện nếu không phải là premium
            if profileManager.currentUser?.stats.premiumStatus != true {
                print("[LanguageView] onAppear - Will load native ad after delay")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    nativeAdManager.resetAndReloadAd()
                }
            }
        }
        .onDisappear {
            // Hủy tất cả các yêu cầu quảng cáo đang chờ xử lý khi rời khỏi view
            nativeAdManager.cancelLoading()
        }
    }
    
    // MARK: - UI Components
    
    private var nativeAdView: some View {
        Group {
            if let _ = nativeAdManager.nativeAd {
                NativeAdViewContainer()
                    .frame(height: 200) // Giảm chiều cao từ 300 xuống 200
            } else if showDebugAd {
                // Debug view
                VStack(spacing: 8) {
                    Text("Debug Quảng Cáo")
                        .font(.headline)
                    
                    Text("Trạng thái: \(nativeAdManager.isLoading ? "Đang tải" : "Chưa tải")")
                    
                    if let error = nativeAdManager.lastError {
                        Text("Lỗi: \(error)")
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                    
                    Button("Tải lại quảng cáo") {
                        nativeAdManager.resetAndReloadAd()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
                .frame(height: 120) // Giảm chiều cao từ 150 xuống 120
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            } else {
                // Loading view
                VStack(spacing: 8) {
                    ProgressView()
                    
                    Text("Đang tải quảng cáo...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(height: 60) // Giảm chiều cao từ 80 xuống 60
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    var Header: some View {
        VStack(spacing: 16) {
            Text(NSLocalizedString("Chọn ngôn ngữ cho ứng dụng", comment: "Choose language for app"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .id(viewModel.refreshID) // Force reload khi refreshID thay đổi
                .padding(.top, 10)
        }
        .padding(.horizontal, 20)
    }
    
    var scrollView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.languages) { language in
                    LanguageRowView(
                        language: language,
                        isSelected: pendingCode == language.code
                    ) {
                        pendingCode = language.code
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
}

struct LanguageRowView: View {
    let language: Language
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Hiệu ứng haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            // Thực hiện action
            onTap()
        }) {
            HStack(spacing: 16) {
                // Flag ở góc trái ngoài cùng
                Text(language.flag)
                    .font(.system(size: 32))
                    .frame(width: 40)
                
                // Thông tin ngôn ngữ
                VStack(alignment: .leading, spacing: 4) {
                    // Tên ngôn ngữ
                    Text(language.name)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)
                    
                    // Tên quốc gia hoặc "selected language"
                    Text(isSelected ? NSLocalizedString("Đã chọn", comment: "Selected") : language.englishName)
                        .font(.subheadline)
                        .foregroundColor(isSelected ? .blue : .secondary)
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Radio button ở góc phải
                Circle()
                    .stroke(isSelected ? Color.blue : Color.gray, lineWidth: 2)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .fill(isSelected ? Color.blue : Color.clear)
                            .frame(width: 12, height: 12)
                    )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

//#Preview {
//    LanguageView()
//        .environmentObject(LanguageViewModel())
//}
