import AVFoundation
import SwiftUI
import UIKit

// Import các View khác cần thiết
import struct SnapArtV2_1.MediaPipeTestButton

// Truy cập trực tiếp class CameraViewController
import class SnapArtV2_1.CameraViewController

struct AuthView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var isLoading = false
    @State private var loadingTimeout = false
    @State private var showLoginSheet = false
    @State private var showSignUpSheet = false
    @EnvironmentObject private var languageViewModel: LanguageViewModel
    
    var body: some View {
        ZStack {
            // Thêm gradient từ AppTheme
            Color(.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 25) {
                // Thông tin về ứng dụng
                VStack(spacing: 10) {
                    Text(NSLocalizedString("SnapArt", comment: "App name"))
                        .font(.headline)
                        .foregroundColor(.white)
                        .id(languageViewModel.refreshID)
                    Text(NSLocalizedString("Ứng dụng chỉnh sửa ảnh với bộ lọc khuôn mặt", comment: "App description"))
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .id(languageViewModel.refreshID)
                }
                .padding(.top, 40)
                // Logo và tiêu đề
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(.white)
                    .padding(.top, 50)
            
                Text(NSLocalizedString("Đăng Nhập", comment: "Sign In"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.bottom, 20)
                    .id(languageViewModel.refreshID)
            
                if isLoading {
                    LoadingView(timeout: $loadingTimeout) {
                        // Xử lý khi timeout
                        isLoading = false
                        loadingTimeout = false
                    }
                } else {
                    // Hiển thị các nút điều hướng
                    Button(action: {
                        showLoginSheet = true
                    }) {
                        HStack {
                            Image(systemName: "person.fill")
                                .font(.headline)
                            Text(NSLocalizedString("Đăng nhập", comment: "Sign In"))
                                .font(.headline)
                                .id(languageViewModel.refreshID)
                        }
                    }
                    .buttonStyle(AppTheme.primaryButtonStyle())
                
                    Button(action: {
                        showSignUpSheet = true
                    }) {
                        HStack {
                            Image(systemName: "person.badge.plus")
                                .font(.headline)
                            Text(NSLocalizedString("Đăng ký", comment: "Sign Up"))
                                .font(.headline)
                                .id(languageViewModel.refreshID)
                        }
                    }
                    .buttonStyle(AppTheme.secondaryButtonStyle())
                }
            
                Spacer()
            }
            .padding()
        }
        .sheet(isPresented: $showLoginSheet) {
            NavigationView {
                LoginView()
                    .environmentObject(authViewModel)
                    .environmentObject(languageViewModel)
                    .navigationBarTitle(NSLocalizedString("Đăng nhập", comment: "Sign In"), displayMode: .inline)
                    .navigationBarItems(leading: Button(action: {
                        showLoginSheet = false
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(Color(.systemBackground))
                    })
            }
        }
        .sheet(isPresented: $showSignUpSheet) {
            NavigationView {
                SignUpView()
                    .environmentObject(authViewModel)
                    .environmentObject(languageViewModel)
                    .navigationBarTitle(NSLocalizedString("Đăng ký", comment: "Sign Up"), displayMode: .inline)
                    .navigationBarItems(leading: Button(action: {
                        showSignUpSheet = false
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(Color(.systemBackground))
                    })
            }
        }
        .onReceive(authViewModel.$authState) { state in
            if state == .signedIn {
                // Nếu đăng nhập thành công, đóng các sheet
                showLoginSheet = false
                showSignUpSheet = false
            }
        }
    }
}

// Loading view with timeout functionality
struct LoadingView: View {
    @Binding var timeout: Bool
    var onTimeout: () -> Void
    
    var body: some View {
        VStack {
            if timeout {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.orange)
                    
                    Text(NSLocalizedString("Quá thời gian chờ", comment: "Timeout"))
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(NSLocalizedString("Không thể kết nối đến máy chủ", comment: "Cannot connect to server"))
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    Button(NSLocalizedString("Thử lại", comment: "Try again")) {
                        onTimeout()
                    }
                    .buttonStyle(AppTheme.primaryButtonStyle())
                }
                .padding()
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(2)
                Text(NSLocalizedString("Đang tải...", comment: "Loading..."))
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.top, 20)
            }
        }
    }
}
