import Foundation
import UIKit
import CoreData
import FirebaseAuth // Thêm import FirebaseAuth
import Combine // Thêm import Combine
import FirebaseFirestore // Thêm import FirebaseFirestore

class GalleryViewModel: ObservableObject {
    @Published var images: [GalleryImage] = []
    @Published var selectedImage: GalleryImage?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let coreDataManager = CoreDataManager.shared
    private let firebaseImageService = FirebaseImageService.shared // Thêm Firebase Image Service
    
    private var signInObserver: AnyCancellable?
    private var signOutObserver: AnyCancellable? // Để quản lý observers cho NotificationCenter
    private var syncTimer: Timer? // Thêm Timer để đồng bộ định kỳ
    
    init() {
        setupObservers()
        // Gọi fetchSavedImages để tải ảnh cục bộ trước
        fetchSavedImages()
        // Sau đó, gọi syncImages để đồng bộ với Firebase nếu có người dùng đăng nhập
        if Auth.auth().currentUser != nil {
            syncImages()
        }
    }
    
    deinit {
        signInObserver?.cancel()
        signOutObserver?.cancel()
        stopSyncTimer() // Dừng timer khi đối tượng được giải phóng
    }
    
    private func setupObservers() {
        signInObserver = NotificationCenter.default.publisher(for: .userDidSignIn)
            .sink { [weak self] _ in
                print("🔔 User signed in. Starting Firebase sync...")
                self?.syncImages() // Bắt đầu đồng bộ khi đăng nhập
                self?.startSyncTimer() // Bắt đầu timer đồng bộ
            }
        
        signOutObserver = NotificationCenter.default.publisher(for: .userDidSignOut)
            .sink { [weak self] _ in
                print("🔔 User signed out. Clearing gallery...")
                // Clear gallery khi đăng xuất để hiển thị ảnh của tài khoản khác
                self?.images = []
                // Nếu bạn muốn xóa tất cả ảnh cục bộ khi đăng xuất, hãy gọi: 
                // self?.coreDataManager.deleteAllSavedImages() 
                // Tuy nhiên, cẩn thận với trải nghiệm người dùng.
                self?.stopSyncTimer() // Dừng timer đồng bộ khi đăng xuất
            }
    }
    
    // MARK: - Sync Timer Management
    private func startSyncTimer() {
        // Đảm bảo dừng timer cũ nếu có
        syncTimer?.invalidate()
        syncTimer = nil
        
        // Bắt đầu timer mới chạy mỗi 5 giây
        syncTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            print("⏳ Timer kích hoạt: Đang đồng bộ Firebase...")
            self.syncImages()
        }
        RunLoop.current.add(syncTimer!, forMode: .common)
    }
    
    private func stopSyncTimer() {
        syncTimer?.invalidate()
        syncTimer = nil
        print("⏹️ Timer đồng bộ đã dừng.")
    }
    
    // MARK: - CoreData Operations
    
    // Lấy danh sách ảnh đã lưu từ CoreData
    func fetchSavedImages() {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let savedImages = try self.coreDataManager.fetchSavedImages()
                
                let galleryImages = savedImages.compactMap { GalleryImage.from(savedImage: $0) }
                    .sorted(by: { $0.createdAt > $1.createdAt })
                
                DispatchQueue.main.async {
                    self.images = galleryImages
                    self.isLoading = false
                    print("✅ Đã tải \(galleryImages.count) ảnh từ CoreData. (UI updated)")
                    print("ℹ️ GalleryViewModel: Số ảnh trên UI sau fetchSavedImages: \(self.images.count)")
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Không thể tải ảnh: \(error.localizedDescription)"
                    self.isLoading = false
                    print("❌ Lỗi tải ảnh từ CoreData: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Lưu một ảnh mới vào CoreData và Firebase
    func saveImage(_ image: UIImage, filterType: String? = nil) {
        isLoading = true
        errorMessage = nil
        
        Task.detached(priority: .background) { [weak self] in // Sử dụng Task.detached để chạy bất đồng bộ
            guard let self = self else { return }
            
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                await MainActor.run { self.errorMessage = "Không thể chuyển đổi ảnh thành dữ liệu" }
                return
            }
            
            let newId = UUID()
            let createdAt = Date()
            
            // Lưu vào CoreData trước
            do {
                var metadata: Data? = nil
                if let filterType = filterType {
                    let metadataDict: [String: Any] = ["filterType": filterType]
                    metadata = try? JSONSerialization.data(withJSONObject: metadataDict)
                }
                
                _ = try self.coreDataManager.saveSavedImage(imageData: imageData, id: newId, createdAt: createdAt, metadata: metadata)
                print("✅ Ảnh đã được lưu vào CoreData với ID: \(newId).")
                
                // Cập nhật UI ngay lập tức với ảnh CoreData
                if let galleryImage = GalleryImage.from(savedImage: try self.coreDataManager.fetchSavedImage(withId: newId)!) {
                    await MainActor.run { 
                        print("ℹ️ Cập nhật UI với ảnh mới ID: \(galleryImage.id)")
                        self.images.insert(galleryImage, at: 0)
                        self.isLoading = false
                        print("ℹ️ GalleryViewModel: Số ảnh trên UI sau khi lưu ảnh mới: \(self.images.count)")
                    }
                }
                
                // Sau đó, tải lên Firebase (chỉ khi có user đăng nhập)
                if Auth.auth().currentUser != nil {
                    print("ℹ️ Đang cố gắng tải ảnh ID: \(newId) lên Firebase...")
                    do {
                        try await self.firebaseImageService.uploadImage(image: image, id: newId, filterType: filterType, createdAt: createdAt)
                        print("✅ Ảnh \(newId) đã được tải lên Firebase thành công.")
                    } catch {
                        print("❌ Lỗi khi tải ảnh \(newId) lên Firebase: \(error.localizedDescription)")
                        await MainActor.run { self.errorMessage = "Lỗi tải ảnh lên đám mây: \(error.localizedDescription)" }
                    }
                }
            } catch {
                print("❌ Lỗi khi lưu ảnh vào CoreData: \(error.localizedDescription)")
                await MainActor.run { 
                    self.errorMessage = "Không thể lưu ảnh cục bộ: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    // Xóa một ảnh dựa trên ID từ CoreData và Firebase
    func deleteImage(withId id: UUID) {
        isLoading = true
        errorMessage = nil
        Task.detached(priority: .background) { [weak self] in
            guard let self = self else { return }
            
            do {
                try self.coreDataManager.deleteSavedImage(withId: id)
                print("✅ Ảnh với ID \(id) đã được xóa khỏi CoreData.")
                
                // Xóa ảnh trên Firebase (chỉ khi có user đăng nhập)
                if Auth.auth().currentUser != nil {
                    do {
                        try await self.firebaseImageService.deleteImage(id: id)
                        print("✅ Ảnh \(id) đã được xóa khỏi Firebase.")
                    } catch {
                        print("❌ Lỗi khi xóa ảnh \(id) khỏi Firebase: \(error.localizedDescription)")
                        await MainActor.run { self.errorMessage = "Lỗi xóa ảnh trên đám mây: \(error.localizedDescription)" }
                    }
                }
                
                await MainActor.run { // Cập nhật UI trên MainActor
                    self.images.removeAll { $0.id == id }
                    if self.selectedImage?.id == id {
                        self.selectedImage = nil
                    }
                    self.isLoading = false
            }
        } catch {
                print("❌ Lỗi khi xóa ảnh khỏi CoreData: \(error.localizedDescription)")
                await MainActor.run { 
                    self.errorMessage = "Không thể xóa ảnh cục bộ: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    // Xóa tất cả ảnh từ CoreData và Firebase
    func deleteAllImages() {
        isLoading = true
        errorMessage = nil
        Task.detached(priority: .background) { [weak self] in
            guard let self = self else { return }
            
            let imagesToDelete = self.images // Lấy bản sao trước khi xóa khỏi CoreData
            
            do {
                try self.coreDataManager.deleteAllSavedImages()
                print("✅ Đã xóa tất cả ảnh khỏi CoreData.")
                
                // Xóa tất cả ảnh trên Firebase (chỉ khi có user đăng nhập)
                if Auth.auth().currentUser != nil {
                    for image in imagesToDelete {
                        do {
                            try await self.firebaseImageService.deleteImage(id: image.id)
                            print("✅ Ảnh \(image.id) đã được xóa khỏi Firebase.")
                        } catch {
                            print("❌ Lỗi khi xóa ảnh \(image.id) khỏi Firebase: \(error.localizedDescription)")
                            // Tiếp tục xóa các ảnh khác ngay cả khi có lỗi
                        }
                    }
                    await MainActor.run { self.errorMessage = nil } // Clear error nếu có
                }
                
                await MainActor.run { // Cập nhật UI trên MainActor
                    self.images = []
                    self.selectedImage = nil
                    self.isLoading = false
                }
        } catch {
                print("❌ Lỗi khi xóa tất cả ảnh khỏi CoreData: \(error.localizedDescription)")
                await MainActor.run { 
                    self.errorMessage = "Không thể xóa tất cả ảnh cục bộ: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Firebase Sync
    func syncImages() {
        guard Auth.auth().currentUser != nil else {
            print("Không có người dùng nào đăng nhập, bỏ qua đồng bộ Firebase.")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self = self else { return }
            
            do {
                // 1. Tải metadata từ Firebase
                let firebaseMetadataList = try await self.firebaseImageService.fetchImageMetadata()
                let coreDataImages = try self.coreDataManager.fetchSavedImages()
                let coreDataImageIds = Set(coreDataImages.compactMap { $0.id })
                
                let firebaseImageIds = Set(firebaseMetadataList.compactMap { $0["id"] as? String }.compactMap { UUID(uuidString: $0) })

                // 2. Xóa ảnh khỏi CoreData nếu không có trên Firebase (để đồng bộ hóa việc xóa)
                for coreDataImage in coreDataImages {
                    if let id = coreDataImage.id, !firebaseImageIds.contains(id) {
                        // Kiểm tra nếu ảnh mới được tạo (ví dụ: trong vòng5 giây gần đây)
                        // Nếu là ảnh rất mới, giả định nó vẫn đang tải lên và chưa xóa.
                        if Date().timeIntervalSince(coreDataImage.createdAt ?? Date.distantPast) < 5 {
                            print("ℹ️ Giữ ảnh cục bộ \(id) vì mới được tạo và có thể đang tải lên Firebase.")
                            continue // Bỏ qua việc xóa ảnh mới được tạo
                        }
                        print("⚠️ Xóa ảnh cục bộ \(id) vì không tìm thấy trên Firebase và không phải ảnh mới.")
                        try self.coreDataManager.deleteSavedImage(withId: id)
                    }
                }

                // 3. Xử lý ảnh cần tải từ Firebase về CoreData
                for metadata in firebaseMetadataList {
                    // Extract required non-optional values first
                    guard let idString = metadata["id"] as? String,
                          let id = UUID(uuidString: idString),
                          let storagePath = metadata["storagePath"] as? String,
                          let createdAtTimestamp = metadata["createdAt"] as? Timestamp
                    else {
                        print("Skipping Firebase metadata due to missing required fields: \(metadata)")
                        continue
                    }
                    
                    // Check if image already exists in CoreData
                    if coreDataImageIds.contains(id) {
                        print("Ảnh \(id) đã tồn tại trong CoreData, bỏ qua tải về.")
                        // Kiểm tra xem ảnh đã có trong danh sách ảnh hiện tại chưa
                        if !self.images.contains(where: { $0.id == id }) {
                            if let galleryImage = GalleryImage.from(savedImage: try self.coreDataManager.fetchSavedImage(withId: id)!) {
                                await MainActor.run { 
                                    print("ℹ️ Cập nhật UI với ảnh \(id) đã tồn tại trong CoreData nhưng chưa có trên UI.")
                                    self.images.insert(galleryImage, at: 0)
                                }
                            }
                        }
                        continue
                    }
                    print("ℹ️ Tải ảnh ID: \(id) từ Firebase về CoreData...")
                    // Extract optional filterType
                    let firebaseFilterType = metadata["filterType"] as? String // This is String?
                    
                    do {
                        let downloadedImage = try await self.firebaseImageService.downloadImage(from: storagePath)
                        
                        var metadataDict: [String: Any] = [:]
                        if let ft = firebaseFilterType { // Use the optional filterType here
                            metadataDict["filterType"] = ft
                        }
                        let metadataData = try? JSONSerialization.data(withJSONObject: metadataDict)
                        
                        _ = try self.coreDataManager.saveSavedImage(imageData: downloadedImage.jpegData(compressionQuality: 0.8)!, id: id, createdAt: createdAtTimestamp.dateValue(), metadata: metadataData)
                        print("✅ Đã tải ảnh \(id) từ Firebase về CoreData. (Lưu cục bộ)")
                        // Cập nhật UI ngay lập tức với ảnh vừa tải về
                        if let galleryImage = GalleryImage.from(savedImage: try self.coreDataManager.fetchSavedImage(withId: id)!) {
                            await MainActor.run { 
                                print("ℹ️ Cập nhật UI với ảnh vừa tải về ID: \(galleryImage.id)")
                    self.images.insert(galleryImage, at: 0)
                }
            }
        } catch {
                        print("❌ Lỗi khi tải ảnh \(id) từ Firebase: \(error.localizedDescription)")
                        // Không cần hiển thị lỗi cho người dùng ở đây, chỉ log
                    }
                }
                
                // 4. Xử lý ảnh cần tải từ CoreData lên Firebase (nếu muốn đồng bộ 2 chiều)
                // (Logic này đã được xử lý trong `saveImage`, nên không cần thêm ở đây)

                // 5. Cập nhật UI sau khi đồng bộ
                await MainActor.run {
                    print("ℹ️ Đồng bộ Firebase hoàn tất. Tải lại ảnh CoreData để cập nhật UI.")
                    self.fetchSavedImages() // Tải lại danh sách ảnh từ CoreData để hiển thị các ảnh mới được đồng bộ
                    self.isLoading = false
                    print("ℹ️ GalleryViewModel: Số ảnh trên UI sau syncImages: \(self.images.count)")
                }
                
            } catch {
                print("❌ Lỗi đồng bộ Firebase tổng quát: \(error.localizedDescription)")
                await MainActor.run {
                    self.errorMessage = "Lỗi đồng bộ hóa ảnh: \(error.localizedDescription)"
                    self.isLoading = false
        }
    }
        }
    }
} 
