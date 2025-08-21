import Foundation
import UIKit
import CoreImage
import MediaPipeTasksVision

final class BigEyesFilter {
    private let context = CIContext(options: nil)
    
    func apply(to image: UIImage, landmarks: FaceLandmarkerResult) -> UIImage? {
        guard let cg = image.cgImage,
              let first = landmarks.faceLandmarks.first else { return image }
        let ci = CIImage(cgImage: cg)
        let size = CGSize(width: cg.width, height: cg.height)
        
        func avg(_ indices: [Int]) -> CGPoint {
            var sx: CGFloat = 0, sy: CGFloat = 0
            let n = CGFloat(indices.count)
            for i in indices { sx += CGFloat(first[i].x); sy += CGFloat(first[i].y) }
            return CGPoint(x: sx/n * size.width, y: sy/n * size.height)
        }
        let leftEyeIdx = [33, 133, 159, 145, 153, 154, 155]
        let rightEyeIdx = [263, 362, 386, 374, 380, 381, 382]
        let left = avg(leftEyeIdx)
        let right = avg(rightEyeIdx)
        let eyeDist = hypot(right.x-left.x, right.y-left.y)
        let radius = max(eyeDist * 0.6, 20)
        
        guard let bumpL = CIFilter(name: "CIBumpDistortion"),
              let bumpR = CIFilter(name: "CIBumpDistortion") else { return image }
        bumpL.setValue(ci, forKey: kCIInputImageKey)
        bumpL.setValue(CIVector(x: left.x, y: size.height-left.y), forKey: kCIInputCenterKey)
        bumpL.setValue(radius, forKey: kCIInputRadiusKey)
        bumpL.setValue(0.5, forKey: kCIInputScaleKey)
        guard let outL = bumpL.outputImage else { return image }
        
        bumpR.setValue(outL, forKey: kCIInputImageKey)
        bumpR.setValue(CIVector(x: right.x, y: size.height-right.y), forKey: kCIInputCenterKey)
        bumpR.setValue(radius, forKey: kCIInputRadiusKey)
        bumpR.setValue(0.5, forKey: kCIInputScaleKey)
        guard let out = bumpR.outputImage,
              let final = context.createCGImage(out, from: out.extent) else { return image }
        return UIImage(cgImage: final, scale: image.scale, orientation: image.imageOrientation)
    }
} 