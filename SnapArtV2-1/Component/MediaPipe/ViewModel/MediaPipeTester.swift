import UIKit
import MediaPipeTasksVision

class MediaPipeTester {
    private let faceMeshManager = MediaPipeFaceMeshManager.shared
    
    // Kiểm tra khởi tạo MediaPipe
    func checkMediaPipeSetup() -> String {
        if faceMeshManager.checkStatus() {
            return "MediaPipe FaceMesh đã được khởi tạo thành công!"
        } else {
            return "Lỗi: MediaPipe FaceMesh chưa được khởi tạo!"
        }
    }
    
    // Kiểm tra phát hiện khuôn mặt từ ảnh
    func testFaceDetection(on image: UIImage) -> String {
        guard let result = faceMeshManager.detectFaceMesh(in: image) else {
            return "Lỗi: Không thể phát hiện khuôn mặt!"
        }
        
        if result.faceLandmarks.isEmpty {
        return "Không tìm thấy khuôn mặt trong ảnh!"
        } else {
            return "Đã phát hiện \(result.faceLandmarks.count) khuôn mặt với \(result.faceLandmarks[0].count) điểm landmark!"
        }
    }
    
    // In ra thông tin về một số điểm landmark quan trọng
    func printKeyLandmarkInfo(result: FaceLandmarkerResult) -> String {
        guard !result.faceLandmarks.isEmpty else {
            return "Không có landmark để hiển thị!"
        }
        
        let landmarks = result.faceLandmarks[0]
        var info = "Các điểm landmark quan trọng:\n"
        
        if landmarks.count >= 1 {
            let point = landmarks[0]
            info += "- Điểm 0 (môi trên): (x: \(String(format: "%.3f", point.x)), y: \(String(format: "%.3f", point.y)))\n"
        }
        
        if landmarks.count >= 10 {
            let point = landmarks[9]
            info += "- Điểm 9 (đỉnh đầu): (x: \(String(format: "%.3f", point.x)), y: \(String(format: "%.3f", point.y)))\n"
        }
        
        if landmarks.count >= 133 {
            let point = landmarks[132]
            info += "- Điểm 132 (mắt trái): (x: \(String(format: "%.3f", point.x)), y: \(String(format: "%.3f", point.y)))\n"
        }
        
        if landmarks.count >= 362 {
            let point = landmarks[361]
            info += "- Điểm 361 (mắt phải): (x: \(String(format: "%.3f", point.x)), y: \(String(format: "%.3f", point.y)))\n"
        }
        
        return info
    }
    
    // Vẽ landmark lên ảnh để debug
    func drawDebugLandmarks(on image: UIImage, result: FaceLandmarkerResult) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // Vẽ ảnh gốc
        image.draw(at: .zero)
        
        // Nếu không có khuôn mặt, trả về ảnh gốc
        guard !result.faceLandmarks.isEmpty else { return image }
        
        // Vẽ các điểm landmark
        let landmarks = result.faceLandmarks[0]
        
        for landmark in landmarks {
            let point = CGPoint(
                x: CGFloat(landmark.x) * image.size.width,
                y: CGFloat(landmark.y) * image.size.height
            )
            
            // Vẽ điểm nhỏ màu đỏ
            context.setFillColor(UIColor.red.withAlphaComponent(0.7).cgColor)
            context.addArc(center: point, radius: 1.5, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
            context.fillPath()
        }
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
} 
