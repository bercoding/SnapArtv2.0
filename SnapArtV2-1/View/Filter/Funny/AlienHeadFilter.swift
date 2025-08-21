import Foundation
import UIKit
import CoreImage
import MediaPipeTasksVision

final class AlienHeadFilter {
    private let context = CIContext(options: nil)
    
    func apply(to image: UIImage, landmarks: FaceLandmarkerResult) -> UIImage? {
        guard let first = landmarks.faceLandmarks.first,
              let cg = image.cgImage else { return image }
        var ci = CIImage(cgImage: cg)
        let size = CGSize(width: cg.width, height: cg.height)
        
        // Dùng trán (151), đỉnh đầu (10), cằm (152) để ước lượng chiều dọc
        let forehead = CGPoint(x: CGFloat(first[151].x) * size.width,
                               y: CGFloat(first[151].y) * size.height)
        let topHead = CGPoint(x: CGFloat(first[10].x) * size.width,
                              y: CGFloat(first[10].y) * size.height)
        let chin = CGPoint(x: CGFloat(first[152].x) * size.width,
                           y: CGFloat(first[152].y) * size.height)
        let faceH = abs(chin.y - topHead.y)
        let faceW = abs(CGFloat(first[454].x - first[234].x)) * size.width
        
        // 1) Co hẹp phần dưới (hai bên má dưới) để tạo cảm giác đầu nhọn
        if let pinchLower = CIFilter(name: "CIPinchDistortion") {
            let lowerCenter = CGPoint(x: (forehead.x + chin.x)/2, y: min(size.height - 1, chin.y - faceH * 0.15))
            pinchLower.setValue(ci, forKey: kCIInputImageKey)
            pinchLower.setValue(CIVector(x: lowerCenter.x, y: size.height - lowerCenter.y), forKey: kCIInputCenterKey)
            pinchLower.setValue(max(faceW * 0.6, 60), forKey: kCIInputRadiusKey)
            pinchLower.setValue(-0.45, forKey: kCIInputScaleKey)
            ci = pinchLower.outputImage ?? ci
        }
        // 2) Phồng to phần trán rộng (đầu to)
        if let bumpUpper = CIFilter(name: "CIBumpDistortion") {
            let upperCenter = CGPoint(x: forehead.x, y: max(0, forehead.y - faceH * 0.25))
            bumpUpper.setValue(ci, forKey: kCIInputImageKey)
            bumpUpper.setValue(CIVector(x: upperCenter.x, y: size.height - upperCenter.y), forKey: kCIInputCenterKey)
            bumpUpper.setValue(max(faceW * 0.9, 80), forKey: kCIInputRadiusKey)
            bumpUpper.setValue(0.6, forKey: kCIInputScaleKey)
            ci = bumpUpper.outputImage ?? ci
        }
        // 3) Pinch nhẹ ở gần chân tóc để tạo dáng “quả lê”
        if let pinchTop = CIFilter(name: "CIPinchDistortion") {
            let topCenter = CGPoint(x: topHead.x, y: max(0, topHead.y - faceH * 0.05))
            pinchTop.setValue(ci, forKey: kCIInputImageKey)
            pinchTop.setValue(CIVector(x: topCenter.x, y: size.height - topCenter.y), forKey: kCIInputCenterKey)
            pinchTop.setValue(max(faceW * 0.6, 60), forKey: kCIInputRadiusKey)
            pinchTop.setValue(-0.25, forKey: kCIInputScaleKey)
            ci = pinchTop.outputImage ?? ci
        }
        guard let out = context.createCGImage(ci, from: ci.extent) else { return image }
        return UIImage(cgImage: out, scale: image.scale, orientation: image.imageOrientation)
    }
} 