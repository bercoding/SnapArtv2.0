import Foundation
import UIKit
import CoreData

// Mô hình dữ liệu cho một ảnh trong gallery
struct GalleryImage: Identifiable {
    let id: UUID
    let imageData: Data
    let createdAt: Date
    let filterType: String?
    
    // Tạo UIImage từ imageData
    var image: UIImage? {
        return imageData.isEmpty ? nil : UIImage(data: imageData)
    }
    
    // Tạo thumbnail từ imageData để hiển thị trong grid
    var thumbnail: UIImage? {
        guard let originalImage = image else { return nil }
        
        let size = CGSize(width: 200, height: 200)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        originalImage.draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    // Tạo GalleryImage từ đối tượng SavedImage trong CoreData
    static func from(savedImage: SavedImage) -> GalleryImage? {
        guard let id = savedImage.id,
              let imageData = savedImage.imageData,
              let createdAt = savedImage.createdAt else {
            return nil
        }
        
        // Giải nén metadata để lấy thông tin filter nếu có
        var filterType: String? = nil
        if let metadataData = savedImage.metadata {
            if let metadata = try? JSONSerialization.jsonObject(with: metadataData, options: JSONSerialization.ReadingOptions(rawValue: 0)) as? [String: Any] {
                filterType = metadata["filterType"] as? String
            }
        }
        
        return GalleryImage(
            id: id,
            imageData: imageData,
            createdAt: createdAt,
            filterType: filterType
        )
    }
} 