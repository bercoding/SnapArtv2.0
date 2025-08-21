import Foundation
import UIKit
import CoreImage
import MediaPipeTasksVision

final class MegaFaceFilter {
    private let context = CIContext(options: nil)
    
    func apply(to image: UIImage, landmarks: FaceLandmarkerResult) -> UIImage? {
        guard let first = landmarks.faceLandmarks.first,
              let cg = image.cgImage else { return image }
        var ci = CIImage(cgImage: cg)
        let size = CGSize(width: cg.width, height: cg.height)
        
        // Tâm mắt
        func avg(_ idx: [Int]) -> CGPoint {
            var sx: CGFloat = 0, sy: CGFloat = 0
            let n = CGFloat(idx.count)
            for i in idx { sx += CGFloat(first[i].x); sy += CGFloat(first[i].y) }
            return CGPoint(x: sx/n * size.width, y: sy/n * size.height)
        }
        let leftEye = avg([33,133,159,145,153,154,155])
        let rightEye = avg([263,362,386,374,380,381,382])
        let eyeDist = hypot(rightEye.x-leftEye.x, rightEye.y-leftEye.y)
        let eyeRadius = max(eyeDist * 0.9, 26)
        
        // Miệng
        let leftMouth = CGPoint(x: CGFloat(first[61].x) * size.width,
                                 y: CGFloat(first[61].y) * size.height)
        let rightMouth = CGPoint(x: CGFloat(first[291].x) * size.width,
                                  y: CGFloat(first[291].y) * size.height)
        let mouthCenter = CGPoint(x: (leftMouth.x + rightMouth.x)/2, y: (leftMouth.y + rightMouth.y)/2)
        let mouthWidth = hypot(rightMouth.x-leftMouth.x, rightMouth.y-leftMouth.y)
        let mouthRadius = max(mouthWidth * 1.1, 30)
        
        // Bump 2 mắt to hơn bình thường
        if let bumpL = CIFilter(name: "CIBumpDistortion"), let bumpR = CIFilter(name: "CIBumpDistortion") {
            bumpL.setValue(ci, forKey: kCIInputImageKey)
            bumpL.setValue(CIVector(x: leftEye.x, y: size.height - leftEye.y), forKey: kCIInputCenterKey)
            bumpL.setValue(eyeRadius, forKey: kCIInputRadiusKey)
            bumpL.setValue(0.8, forKey: kCIInputScaleKey)
            ci = bumpL.outputImage ?? ci
            
            bumpR.setValue(ci, forKey: kCIInputImageKey)
            bumpR.setValue(CIVector(x: rightEye.x, y: size.height - rightEye.y), forKey: kCIInputCenterKey)
            bumpR.setValue(eyeRadius, forKey: kCIInputRadiusKey)
            bumpR.setValue(0.8, forKey: kCIInputScaleKey)
            ci = bumpR.outputImage ?? ci
        }
        // Bump miệng khổng lồ
        if let bumpM = CIFilter(name: "CIBumpDistortion") {
            bumpM.setValue(ci, forKey: kCIInputImageKey)
            bumpM.setValue(CIVector(x: mouthCenter.x, y: size.height - mouthCenter.y), forKey: kCIInputCenterKey)
            bumpM.setValue(mouthRadius, forKey: kCIInputRadiusKey)
            bumpM.setValue(0.6, forKey: kCIInputScaleKey)
            ci = bumpM.outputImage ?? ci
        }
        guard let out = context.createCGImage(ci, from: ci.extent) else { return image }
        return UIImage(cgImage: out, scale: image.scale, orientation: image.imageOrientation)
    }
} 