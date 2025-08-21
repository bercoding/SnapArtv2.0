import Foundation
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth
import UIKit

enum FirebaseImageError: Error, LocalizedError {
    case noUserLoggedIn
    case uploadFailed(Error)
    case downloadFailed(Error)
    case deleteFailed(Error)
    case metadataSaveFailed(Error)
    case metadataFetchFailed(Error)
    case imageNotFound
    case dataConversionFailed
    var errorDescription: String? {
        switch self {
        case .noUserLoggedIn: return "Không có người dùng nào đang đăng nhập."
        case .uploadFailed(let error): return "Tải ảnh lên Firebase Storage thất bại: \(error.localizedDescription)"
        case .downloadFailed(let error): return "Tải ảnh từ Firebase Storage thất bại: \(error.localizedDescription)"
        case .deleteFailed(let error): return "Xóa ảnh trên Firebase Storage thất bại: \(error.localizedDescription)"
        case .metadataSaveFailed(let error): return "Lưu thông tin ảnh lên Firestore thất bại: \(error.localizedDescription)"
        case .metadataFetchFailed(let error): return "Tải thông tin ảnh từ Firestore thất bại: \(error.localizedDescription)"
        case .imageNotFound: return "Không tìm thấy ảnh trên Firebase Storage."
        case .dataConversionFailed: return "Không thể chuyển đổi dữ liệu ảnh."
        }
    }
}

class FirebaseImageService {
    static let shared = FirebaseImageService() // Singleton
    
    private let storage = Storage.storage()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Upload Image
    func uploadImage(image: UIImage, id: UUID, filterType: String?, createdAt: Date) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FirebaseImageError.noUserLoggedIn
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw FirebaseImageError.dataConversionFailed
        }
        
        let storageRef = storage.reference().child("users/\(userId)/images/\(id.uuidString).jpg")
        
        do {
            _ = try await storageRef.putDataAsync(imageData)
            print("Ảnh đã được tải lên Firebase Storage với ID: \(id)")
            
            // Lưu metadata vào Firestore
            let metadata: [String: Any] = [
                "id": id.uuidString,
                "storagePath": storageRef.fullPath,
                "createdAt": Timestamp(date: createdAt),
                "filterType": filterType ?? NSNull(), // Lưu NSNull nếu không có filterType
                "userId": userId // Thêm userId vào metadata
            ]
            
            try await db.collection("NhanFirestore").document(id.uuidString).setData(metadata) // Thay đổi collection name
            print("Metadata của ảnh \(id) đã được lưu vào Firestore.")
            
        } catch {
            print("Lỗi khi tải ảnh/metadata lên Firebase: \(error.localizedDescription)")
            throw FirebaseImageError.uploadFailed(error)
        }
    }
    
    // MARK: - Download Images Metadata
    func fetchImageMetadata() async throws -> [[String: Any]] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FirebaseImageError.noUserLoggedIn
        }
        
        do {
            // Thay đổi collection name và thêm điều kiện lọc theo userId
            let querySnapshot = try await db.collection("NhanFirestore")
                                            .whereField("userId", isEqualTo: userId)
                                            .order(by: "createdAt", descending: true)
                                            .getDocuments()
            let metadata = querySnapshot.documents.map { $0.data() }
            print(" Đã tải \(metadata.count) metadata ảnh từ Firestore.")
            return metadata
        } catch {
            print(" Lỗi khi tải metadata ảnh từ Firestore: \(error.localizedDescription)")
            throw FirebaseImageError.metadataFetchFailed(error)
        }
    }
    
    // MARK: - Download Image Data
    func downloadImage(from storagePath: String) async throws -> UIImage {
        let storageRef = storage.reference(withPath: storagePath)
        
        do {
            let maxDownloadSize: Int64 = 5 * 1024 * 1024 // 5MB limit
            let data = try await storageRef.data(maxSize: maxDownloadSize)
            guard let image = UIImage(data: data) else {
                throw FirebaseImageError.dataConversionFailed
            }
            print(" Đã tải ảnh từ Firebase Storage: \(storagePath)")
            return image
        } catch {
            print("Lỗi khi tải ảnh từ Firebase Storage \(storagePath): \(error.localizedDescription)")
            throw FirebaseImageError.downloadFailed(error)
        }
    }
    
    // MARK: - Delete Image
    func deleteImage(id: UUID) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FirebaseImageError.noUserLoggedIn
        }
        
        // Xóa metadata trước
        do {
            // Thay đổi collection name và đảm bảo chỉ xóa của user hiện tại
            try await db.collection("NhanFirestore").document(id.uuidString).delete()
            print(" Metadata của ảnh \(id) đã được xóa khỏi Firestore.")
        } catch {
            print(" Lỗi khi xóa metadata ảnh \(id) khỏi Firestore: \(error.localizedDescription)")
            // Cố gắng tiếp tục xóa file ngay cả khi xóa metadata thất bại
        }
        
        // Sau đó xóa file trong Storage
        let storageRef = storage.reference().child("users/\(userId)/images/\(id.uuidString).jpg")
        do {
            try await storageRef.delete()
            print("Ảnh \(id) đã được xóa khỏi Firebase Storage.")
        } catch {
            print("Lỗi khi xóa ảnh \(id) khỏi Firebase Storage: \(error.localizedDescription)")
            throw FirebaseImageError.deleteFailed(error)
        }
    }
} 
