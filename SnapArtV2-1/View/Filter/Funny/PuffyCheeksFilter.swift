import Foundation
import UIKit
import CoreImage
import MediaPipeTasksVision

final class PuffyCheeksFilter {
    private let context = CIContext(options: nil)
    
    func apply(to image: UIImage, landmarks: FaceLandmarkerResult) -> UIImage? {
        guard let first = landmarks.faceLandmarks.first,
              let cg = image.cgImage else { return image }
        var ci = CIImage(cgImage: cg)
        let size = CGSize(width: cg.width, height: cg.height)
        
        // 234 (má trái), 454 (má phải) theo MediaPipe FaceMesh
        let leftCheek = CGPoint(x: CGFloat(first[234].x) * size.width,
                                 y: CGFloat(first[234].y) * size.height)
        let rightCheek = CGPoint(x: CGFloat(first[454].x) * size.width,
                                  y: CGFloat(first[454].y) * size.height)
        let faceWidth: CGFloat = abs(rightCheek.x - leftCheek.x)
        let radius = max(faceWidth * 0.35, 28)
        
        if let bumpL = CIFilter(name: "CIBumpDistortion"), let bumpR = CIFilter(name: "CIBumpDistortion") {
            bumpL.setValue(ci, forKey: kCIInputImageKey)
            bumpL.setValue(CIVector(x: leftCheek.x, y: size.height - leftCheek.y), forKey: kCIInputCenterKey)
            bumpL.setValue(radius, forKey: kCIInputRadiusKey)
            bumpL.setValue(0.45, forKey: kCIInputScaleKey)
            ci = bumpL.outputImage ?? ci
            
            bumpR.setValue(ci, forKey: kCIInputImageKey)
            bumpR.setValue(CIVector(x: rightCheek.x, y: size.height - rightCheek.y), forKey: kCIInputCenterKey)
            bumpR.setValue(radius, forKey: kCIInputRadiusKey)
            bumpR.setValue(0.45, forKey: kCIInputScaleKey)
            ci = bumpR.outputImage ?? ci
        }
        guard let out = context.createCGImage(ci, from: ci.extent) else { return image }
        return UIImage(cgImage: out, scale: image.scale, orientation: image.imageOrientation)
    }
} 