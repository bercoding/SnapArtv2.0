import Foundation
import UIKit
import CoreImage
import MediaPipeTasksVision

final class SwirlFaceFilter {
    private let context = CIContext(options: nil)
    
    func apply(to image: UIImage, landmarks: FaceLandmarkerResult) -> UIImage? {
        guard let first = landmarks.faceLandmarks.first,
              let cg = image.cgImage else { return image }
        let ci = CIImage(cgImage: cg)
        let size = CGSize(width: cg.width, height: cg.height)
        
        // Trung điểm giữa mũi (2) và miệng trên (0)
        let nose = CGPoint(x: CGFloat(first[2].x) * size.width, y: CGFloat(first[2].y) * size.height)
        let mouthTop = CGPoint(x: CGFloat(first[0].x) * size.width, y: CGFloat(first[0].y) * size.height)
        let center = CGPoint(x: (nose.x + mouthTop.x)/2, y: (nose.y + mouthTop.y)/2)
        let faceH: CGFloat = abs(mouthTop.y - nose.y) * 4.0
        let radius = max(faceH * 0.35, 30)
        
        guard let twirl = CIFilter(name: "CITwirlDistortion") else { return image }
        twirl.setValue(ci, forKey: kCIInputImageKey)
        twirl.setValue(CIVector(x: center.x, y: size.height - center.y), forKey: kCIInputCenterKey)
        twirl.setValue(radius, forKey: kCIInputRadiusKey)
        twirl.setValue(NSNumber(value: Double.pi * 0.6), forKey: kCIInputAngleKey)
        guard let out = twirl.outputImage,
              let final = context.createCGImage(out, from: out.extent) else { return image }
        return UIImage(cgImage: final, scale: image.scale, orientation: image.imageOrientation)
    }
} 
