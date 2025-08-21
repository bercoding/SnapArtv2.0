import Foundation
import UIKit
import CoreImage
import MediaPipeTasksVision

final class LongChinFilter {
    private let context = CIContext(options: nil)
    
    func apply(to image: UIImage, landmarks: FaceLandmarkerResult) -> UIImage? {
        guard let first = landmarks.faceLandmarks.first,
              let cg = image.cgImage else { return image }
        var ci = CIImage(cgImage: cg)
        let size = CGSize(width: cg.width, height: cg.height)
        
        // 152 (cằm giữa), 151 (trán) dùng để ước lượng chiều dài mặt
        let chin = CGPoint(x: CGFloat(first[152].x) * size.width,
                           y: CGFloat(first[152].y) * size.height)
        let forehead = CGPoint(x: CGFloat(first[151].x) * size.width,
                               y: CGFloat(first[151].y) * size.height)
        let faceH = abs(chin.y - forehead.y)
        
        // Pinch dọc cằm: mạnh hơn, vùng hẹp hơn để thu gọn cằm rõ rệt
        if let pinch = CIFilter(name: "CIPinchDistortion") {
            pinch.setValue(ci, forKey: kCIInputImageKey)
            pinch.setValue(CIVector(x: chin.x, y: size.height - chin.y), forKey: kCIInputCenterKey)
            pinch.setValue(max(faceH * 0.22, 22), forKey: kCIInputRadiusKey)
            pinch.setValue(-0.7, forKey: kCIInputScaleKey)
            ci = pinch.outputImage ?? ci
        }
        // Bump thứ nhất: ngay dưới cằm để kéo dài xuống
        if let bump1 = CIFilter(name: "CIBumpDistortion") {
            let belowChin1 = CGPoint(x: chin.x, y: min(size.height - 1, chin.y + faceH * 0.30))
            bump1.setValue(ci, forKey: kCIInputImageKey)
            bump1.setValue(CIVector(x: belowChin1.x, y: size.height - belowChin1.y), forKey: kCIInputCenterKey)
            bump1.setValue(max(faceH * 0.34, 28), forKey: kCIInputRadiusKey)
            bump1.setValue(0.60, forKey: kCIInputScaleKey)
            ci = bump1.outputImage ?? ci
        }
        // Bump thứ hai: sâu hơn để tăng cảm giác dài
        if let bump2 = CIFilter(name: "CIBumpDistortion") {
            let belowChin2 = CGPoint(x: chin.x, y: min(size.height - 1, chin.y + faceH * 0.46))
            bump2.setValue(ci, forKey: kCIInputImageKey)
            bump2.setValue(CIVector(x: belowChin2.x, y: size.height - belowChin2.y), forKey: kCIInputCenterKey)
            bump2.setValue(max(faceH * 0.26, 22), forKey: kCIInputRadiusKey)
            bump2.setValue(0.45, forKey: kCIInputScaleKey)
            ci = bump2.outputImage ?? ci
        }
        guard let out = context.createCGImage(ci, from: ci.extent) else { return image }
        return UIImage(cgImage: out, scale: image.scale, orientation: image.imageOrientation)
    }
} 