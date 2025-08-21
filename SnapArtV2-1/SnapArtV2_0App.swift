//
//  SnapArtV2_0App.swift
//  SnapArtV2-0
//
//  Created by Le Thanh Nhan on 24/7/25.
//

import SwiftUI
import FirebaseCore
import MediaPipeTasksVision

@main
struct SnapArtV2_0App: App {
    // Use CoreDataManager instead of PersistenceController
    let coreDataManager = CoreDataManager.shared
    
    // Tạo AuthViewModel ở cấp ứng dụng để quản lý trạng thái đăng nhập
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var onboardingManager = OnboardingManager() // Added StateObject for OnboardingManager
    @StateObject private var galleryViewModel = GalleryViewModel() // Thêm GalleryViewModel
    @StateObject private var languageViewModel = LanguageViewModel()
    
    // Thêm trạng thái để theo dõi quá trình khởi tạo
    @State private var isInitialized = false
    
    init() {
        print("SnapArtV2_0App init bắt đầu")
        
        // Khởi tạo Firebase trực tiếp, đảm bảo chạy đầu tiên
        do {
            if FirebaseApp.app() == nil {
                FirebaseApp.configure()
                print("Firebase đã được khởi tạo thành công")
            } else {
                print("Firebase đã được khởi tạo trước đó")
            }
        } catch {
            print("Lỗi khi khởi tạo Firebase: \(error.localizedDescription)")
        }
        
        // Không cần gọi FirebaseManager.shared.configure() nữa
        print("Firebase configuration completed")
        
        // Khởi tạo sẵn MediaPipeFaceMeshManager
        do {
            _ = MediaPipeFaceMeshManager.shared
            print("MediaPipe Face Mesh được khởi tạo")
        } catch {
            print(" Lỗi khi khởi tạo MediaPipeFaceMeshManager: \(error.localizedDescription)")
        }
        
        print("SnapArtV2_0App init hoàn thành")
    }

    var body: some Scene {
        WindowGroup {
            SplashView()
                .environment(\.managedObjectContext, coreDataManager.persistentContainer.viewContext) // Đảm bảo sử dụng viewContext
                .environmentObject(authViewModel)
                .environmentObject(onboardingManager)
                .environmentObject(galleryViewModel) // Cung cấp GalleryViewModel
//                .onAppear {
//                    print("SplashView xuất hiện")
//                }
        }
    }
}
