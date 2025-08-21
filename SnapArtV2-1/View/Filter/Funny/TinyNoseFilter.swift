import Foundation
import UIKit
import CoreImage
import MediaPipeTasksVision

final class TinyNoseFilter {
    private let context = CIContext(options: nil)
    
    func apply(to image: UIImage, landmarks: FaceLandmarkerResult) -> UIImage? {
        guard let first = landmarks.faceLandmarks.first,
              let cg = image.cgImage else { return image }
        let ci = CIImage(cgImage: cg)
        let size = CGSize(width: cg.width, height: cg.height)
        
        let noseIdx = 2 // tip gần dưới mũi
        let cx = CGFloat(first[noseIdx].x) * size.width
        let cy = CGFloat(first[noseIdx].y) * size.height
        let radius = max(min(size.width, size.height) * 0.12, 20)
        
        guard let pinch = CIFilter(name: "CIPinchDistortion") else { return image }
        pinch.setValue(ci, forKey: kCIInputImageKey)
        pinch.setValue(CIVector(x: cx, y: size.height - cy), forKey: kCIInputCenterKey)
        pinch.setValue(radius, forKey: kCIInputRadiusKey)
        pinch.setValue(-0.4, forKey: kCIInputScaleKey)
        guard let out = pinch.outputImage,
              let final = context.createCGImage(out, from: out.extent) else { return image }
        return UIImage(cgImage: final, scale: image.scale, orientation: image.imageOrientation)
    }
} 