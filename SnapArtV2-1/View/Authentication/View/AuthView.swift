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
                    Text(String(localized: "SnapArt"))
                        .font(.headline)
                        .foregroundColor(.white)
                        .id(languageViewModel.refreshID)
                    Text(String(localized: "Ứng dụng chỉnh sửa ảnh với bộ lọc khuôn mặt"))
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
            
                Text(String(localized: "Đăng Nhập"))
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
                            Text(String(localized: "Đăng nhập"))
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
                            Text(String(localized: "Đăng ký"))
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
                    .navigationBarTitle(String(localized: "Đăng nhập"), displayMode: .inline)
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
                    .navigationBarTitle(String(localized: "Đăng ký"), displayMode: .inline)
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
                    
                    Text(String(localized: "Quá thời gian chờ"))
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(String(localized: "Không thể kết nối đến máy chủ"))
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    Button(String(localized: "Thử lại")) {
                        onTimeout()
                    }
                    .buttonStyle(AppTheme.primaryButtonStyle())
                }
                .padding()
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(2)
                Text(String(localized: "Đang tải..."))
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.top, 20)
            }
        }
    }
}
