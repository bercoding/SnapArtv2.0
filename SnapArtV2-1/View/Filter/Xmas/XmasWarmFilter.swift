import UIKit
import CoreImage

final class XmasWarmFilter {
    private let context = CIContext()
    
    func apply(to image: UIImage) -> UIImage? {
        guard let cg = image.cgImage else { return image }
        var ci = CIImage(cgImage: cg)
        
        // 1) Tăng nhiệt độ màu (ấm)
        if let temp = CIFilter(name: "CITemperatureAndTint") {
            temp.setValue(ci, forKey: kCIInputImageKey)
            // neutral, targetNeutral
            temp.setValue(CIVector(x: 6500, y: 0), forKey: "inputNeutral")
            temp.setValue(CIVector(x: 7500, y: 0), forKey: "inputTargetNeutral")
            ci = temp.outputImage ?? ci
        }
        
        // 2) Tăng saturation nhẹ + brightness
        if let color = CIFilter(name: "CIColorControls") {
            color.setValue(ci, forKey: kCIInputImageKey)
            color.setValue(1.15, forKey: kCIInputSaturationKey)
            color.setValue(0.03, forKey: kCIInputBrightnessKey)
            color.setValue(0.98, forKey: kCIInputContrastKey)
            ci = color.outputImage ?? ci
        }
        
        // 3) Bloom nhẹ tạo cảm giác lung linh
        if let bloom = CIFilter(name: "CIBloom") {
            bloom.setValue(ci, forKey: kCIInputImageKey)
            bloom.setValue(0.9, forKey: kCIInputIntensityKey)
            bloom.setValue(8.0, forKey: kCIInputRadiusKey)
            ci = bloom.outputImage ?? ci
        }
        
        // 4) Vignette rất nhẹ
        if let vig = CIFilter(name: "CIVignette") {
            vig.setValue(ci, forKey: kCIInputImageKey)
            vig.setValue(0.6, forKey: kCIInputIntensityKey)
            vig.setValue(1.5, forKey: kCIInputRadiusKey)
            ci = vig.outputImage ?? ci
        }
        
        guard let out = context.createCGImage(ci, from: ci.extent) else { return image }
        return UIImage(cgImage: out, scale: image.scale, orientation: image.imageOrientation)
    }
} 