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
    
    var body: some View {
        ZStack {
            // Thêm gradient từ AppTheme
            AppTheme.mainGradient
                .ignoresSafeArea()
            
        VStack(spacing: 25) {
            // Thông tin về ứng dụng
            VStack(spacing: 10) {
                Text("SnapArt")
                    .font(.headline)
                        .foregroundColor(.white) // Thay đổi màu chữ
                Text("Ứng dụng chỉnh sửa ảnh với bộ lọc khuôn mặt")
                    .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8)) // Thay đổi màu chữ
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 40)
            // Logo và tiêu đề
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                    .foregroundColor(.white) // Thay đổi màu biểu tượng
                .padding(.top, 50)
            
            Text("Đăng Nhập")
                .font(.largeTitle)
                .fontWeight(.bold)
                    .foregroundColor(.white) // Thay đổi màu chữ
                .padding(.bottom, 20)
            
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
                        Text("Đăng nhập")
                            .font(.headline)
                    }
                }
                    .buttonStyle(AppTheme.primaryButtonStyle()) // Sử dụng style từ AppTheme
                
                Button(action: {
                    showSignUpSheet = true
                }) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                            .font(.headline)
                        Text("Đăng ký")
                            .font(.headline)
                    }
                    }
                    .buttonStyle(AppTheme.secondaryButtonStyle()) // Sử dụng style từ AppTheme
            }
            
            Spacer()
        }
        .padding()
        }
        .sheet(isPresented: $showLoginSheet) {
            NavigationView {
                LoginView()
                    .environmentObject(authViewModel)
                    .navigationBarTitle("Đăng nhập", displayMode: .inline)
                    .navigationBarItems(leading: Button(action: {
                        showLoginSheet = false
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(AppTheme.primaryColor)
                    })
            }
        }
        .sheet(isPresented: $showSignUpSheet) {
            NavigationView {
                SignUpView()
                    .environmentObject(authViewModel)
                    .navigationBarTitle("Đăng ký", displayMode: .inline)
                    .navigationBarItems(leading: Button(action: {
                        showSignUpSheet = false
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(AppTheme.primaryColor)
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
                    
                    Text("Quá thời gian chờ")
                        .font(.headline)
                        .foregroundColor(.white) // Thay đổi màu chữ
                    
                    Text("Không thể kết nối đến máy chủ")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8)) // Thay đổi màu chữ
                        .multilineTextAlignment(.center)
                    
                    Button("Thử lại") {
                        onTimeout()
                    }
                    .buttonStyle(AppTheme.primaryButtonStyle()) // Sử dụng style từ AppTheme
                }
                .padding()
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white)) // Thay đổi màu
                    .scaleEffect(2)
                Text("Đang tải...")
                    .font(.headline)
                    .foregroundColor(.white) // Thay đổi màu chữ
                    .padding(.top, 20)
            }
        }
    }
}

