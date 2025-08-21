import UIKit
import CoreImage

final class BeautyFilter {
    private let context = CIContext()
    
    // intensity 0..1
    func apply(to image: UIImage, smooth: CGFloat, brighten: CGFloat) -> UIImage? {
        guard let cg = image.cgImage else { return image }
        let input = CIImage(cgImage: cg)
        let size = input.extent.size
        
        // 1) Làm mịn bằng bilateral-like: Gaussian blur + high-pass preserve edges
        // Blur
        let blurRadius = max(0, smooth) * 6.0 // 0..6 px
        var smoothed = input
        if blurRadius > 0.01, let gauss = CIFilter(name: "CIGaussianBlur") {
            gauss.setValue(input, forKey: kCIInputImageKey)
            gauss.setValue(blurRadius, forKey: kCIInputRadiusKey)
            smoothed = gauss.outputImage?.cropped(to: input.extent) ?? input
        }
        
        // High-pass: input - median(blur) để giữ chi tiết biên, mix nhẹ vào smoothed
        var blended = smoothed
        if let median = CIFilter(name: "CIMedianFilter") {
            median.setValue(input, forKey: kCIInputImageKey)
            let medianImg = median.outputImage ?? input
            if let subtract = CIFilter(name: "CIColorDodgeBlendMode") { // dodge để khôi phục highlights
                subtract.setValue(smoothed, forKey: kCIInputBackgroundImageKey)
                subtract.setValue(medianImg, forKey: kCIInputImageKey)
                blended = subtract.outputImage?.cropped(to: input.extent) ?? smoothed
            }
        }
        // Mix giữa smoothed và blended theo smooth
        if let mix = CIFilter(name: "CIBlendWithAlphaMask") {
            // tạo mask mềm theo smooth: dùng constant color gray = smooth
            let alpha = CIFilter(name: "CIConstantColorGenerator",
                                 parameters: [kCIInputColorKey: CIColor(red: 1, green: 1, blue: 1, alpha: smooth)])?.outputImage?
                .cropped(to: input.extent)
            mix.setValue(blended, forKey: kCIInputImageKey)
            mix.setValue(input, forKey: kCIInputBackgroundImageKey)
            mix.setValue(alpha, forKey: kCIInputMaskImageKey)
            blended = mix.outputImage?.cropped(to: input.extent) ?? blended
        }
        
        // 2) Làm sáng nhẹ và nâng nền: exposure + vibrance nhẹ
        var tone = blended
        if brighten > 0.001 {
            if let exposure = CIFilter(name: "CIExposureAdjust") {
                exposure.setValue(tone, forKey: kCIInputImageKey)
                exposure.setValue(brighten * 0.8, forKey: kCIInputEVKey) // EV tăng nhẹ
                tone = exposure.outputImage ?? tone
            }
            if let gamma = CIFilter(name: "CIGammaAdjust") {
                gamma.setValue(tone, forKey: kCIInputImageKey)
                gamma.setValue(1.0 - brighten * 0.15, forKey: "inputPower") // kéo sáng vùng tối
                tone = gamma.outputImage ?? tone
            }
            if let vibrance = CIFilter(name: "CIVibrance") {
                vibrance.setValue(tone, forKey: kCIInputImageKey)
                vibrance.setValue(brighten * 0.25, forKey: "inputAmount")
                tone = vibrance.outputImage ?? tone
            }
        }
        
        guard let out = context.createCGImage(tone, from: tone.extent) else { return image }
        return UIImage(cgImage: out, scale: image.scale, orientation: image.imageOrientation)
    }
} 