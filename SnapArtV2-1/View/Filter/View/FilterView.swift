import SwiftUI
import AVFoundation
import UIKit

// Import các View khác cần thiết
import struct SnapArtV2_1.MediaPipeTestButton

struct FilterView: View {
    @EnvironmentObject var filterManager: FilterManager
    @StateObject private var galleryViewModel = GalleryViewModel()
    @State private var showCamera = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Thêm gradient từ AppTheme
                AppTheme.mainGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Tiêu đề
                    Text(NSLocalizedString("Chọn Filter", comment: "Select Filter"))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    // Hiển thị filter hiện tại
                    Text(NSLocalizedString("Filter hiện tại: \(filterManager.currentFilter?.displayName ?? "Không có")", comment: "Current Filter"))
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.bottom, 10)
                    
                    // Nút mở camera
                    Button(action: {
                        checkCameraPermissionAndOpen()
                    }) {
                        VStack(spacing: 10) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                            Text(NSLocalizedString("Mở Camera", comment: "Open Camera"))
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.blue.opacity(0.6))
                        )
                    }
                    .buttonStyle(AppTheme.primaryButtonStyle()) // Sử dụng style từ AppTheme
                    
                    // Nút thử nghiệm MediaPipe
                    Button(action: {
                        // Không cần làm gì vì NavigationLink sẽ xử lý điều hướng
                    }) {
                        HStack {
                            Image(systemName: "face.dashed")
                                .font(.system(size: 20))
                            Text(NSLocalizedString("Thử nghiệm Filter với ảnh", comment: "Test Filter with image"))
                                .font(.headline)
                        }
                    }
                    .buttonStyle(AppTheme.secondaryButtonStyle()) // Sử dụng style từ AppTheme
                    
                    // Thêm NavigationLink ẩn để điều hướng
                    NavigationLink(destination: MediaPipeTestButtonView()) {
                        EmptyView()
                    }
                    .opacity(0) // Ẩn NavigationLink
                }
                .padding()
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraViewControllerRepresentable(isPresented: $showCamera)
            }
        }
    }
    
    // Kiểm tra quyền truy cập camera và mở camera
    private func checkCameraPermissionAndOpen() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            showCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        showCamera = true
                    }
                }
            }
        case .denied, .restricted:
            showCameraPermissionAlert()
        @unknown default:
            break
        }
    }
    
    // Hiển thị alert yêu cầu quyền camera
    private func showCameraPermissionAlert() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            
            let alert = UIAlertController(
                title: NSLocalizedString("Cần quyền truy cập Camera", comment: "Camera access required"),
                message: NSLocalizedString("Vui lòng cho phép ứng dụng truy cập camera trong Cài đặt để sử dụng tính năng này", comment: "Please allow the app to access camera in Settings to use this feature"),
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("Hủy", comment: "Cancel"), style: .cancel))
            alert.addAction(UIAlertAction(title: NSLocalizedString("Mở Cài đặt", comment: "Open Settings"), style: .default) { _ in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            })
            
            rootViewController.present(alert, animated: true)
        }
    }
}

// Wrapper để hiển thị MediaPipeTestButton trong SwiftUI
struct MediaPipeTestButtonView: View {
    var body: some View {
        ZStack {
            // Thêm gradient từ AppTheme
            AppTheme.mainGradient
                .ignoresSafeArea()
            
            MediaPipeTestButton()
        }
    }
}

// Wrapper để hiển thị UIViewController trong SwiftUI
struct CameraViewControllerRepresentable: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @EnvironmentObject var galleryViewModel: GalleryViewModel // Thêm EnvironmentObject
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let cameraVC = CameraViewController()
        cameraVC.onDismiss = {
            isPresented = false
        }
        cameraVC.saveImageAction = { image, filterType in // Truyền action lưu ảnh
            // Hiện Interstitial Ad trước khi lưu ảnh
            InterstitialAdManager.shared.showInterstitialAd()
            // Sau khi ad đóng, lưu ảnh và chuyển sang Gallery
            galleryViewModel.saveImage(image, filterType: filterType)
        }
        return cameraVC
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}
