import Foundation
import UIKit
import CoreImage
import MediaPipeTasksVision

final class WideMouthFilter {
    private let context = CIContext(options: nil)
    
    func apply(to image: UIImage, landmarks: FaceLandmarkerResult) -> UIImage? {
        guard let first = landmarks.faceLandmarks.first,
              let cg = image.cgImage else { return image }
        var ci = CIImage(cgImage: cg)
        let size = CGSize(width: cg.width, height: cg.height)
        
        let leftMouthIdx = 61
        let rightMouthIdx = 291
        let mouthTopIdx = 0
        
        let left = CGPoint(x: CGFloat(first[leftMouthIdx].x) * size.width,
                           y: CGFloat(first[leftMouthIdx].y) * size.height)
        let right = CGPoint(x: CGFloat(first[rightMouthIdx].x) * size.width,
                            y: CGFloat(first[rightMouthIdx].y) * size.height)
        let mouthCenter = CGPoint(x: (left.x + right.x)/2, y: (left.y + right.y)/2)
        let width = hypot(right.x-left.x, right.y-left.y)
        let radius = max(width * 0.9, 24)
        
        // Tăng độ rộng miệng tại tâm, scale dương
        if let bump = CIFilter(name: "CIBumpDistortion") {
            bump.setValue(ci, forKey: kCIInputImageKey)
            bump.setValue(CIVector(x: mouthCenter.x, y: size.height - mouthCenter.y), forKey: kCIInputCenterKey)
            bump.setValue(radius, forKey: kCIInputRadiusKey)
            bump.setValue(0.35, forKey: kCIInputScaleKey)
            ci = bump.outputImage ?? ci
        }
        
      
        if let pinchL = CIFilter(name: "CIPinchDistortion"), let pinchR = CIFilter(name: "CIPinchDistortion") {
            pinchL.setValue(ci, forKey: kCIInputImageKey)
            pinchL.setValue(CIVector(x: left.x, y: size.height - left.y), forKey: kCIInputCenterKey)
            pinchL.setValue(radius * 0.6, forKey: kCIInputRadiusKey)
            pinchL.setValue(-0.2, forKey: kCIInputScaleKey)
            let outL = pinchL.outputImage ?? ci
            
            pinchR.setValue(outL, forKey: kCIInputImageKey)
            pinchR.setValue(CIVector(x: right.x, y: size.height - right.y), forKey: kCIInputCenterKey)
            pinchR.setValue(radius * 0.6, forKey: kCIInputRadiusKey)
            pinchR.setValue(-0.2, forKey: kCIInputScaleKey)
            ci = pinchR.outputImage ?? outL
        }
        
        guard let final = context.createCGImage(ci, from: ci.extent) else { return image }
        return UIImage(cgImage: final, scale: image.scale, orientation: image.imageOrientation)
    }
} 
