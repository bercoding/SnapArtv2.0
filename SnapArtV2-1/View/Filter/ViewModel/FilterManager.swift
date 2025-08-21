import UIKit
import Foundation
import MediaPipeTasksVision

/**
 * FilterManager - Lớp quản lý filter duy nhất trong ứng dụng
 * Quản lý việc lựa chọn filter và áp dụng filter lên hình ảnh
 */
class FilterManager {
    // Singleton instance
    static let shared = FilterManager()
    
    // Filter hiện tại đang áp dụng
    private(set) var currentFilter: FilterType?
    
    // Danh sách các filter có sẵn
    private(set) var availableFilters: [FilterType] = [
        .dogFace, .glasses, .mustache, .hat, .beauty,
        .funnyBigEyes, .funnyTinyNose, .funnyWideMouth,
        .funnyPuffyCheeks, .funnySwirl, .funnyLongChin, .funnyMegaFace, .funnyAlienHead, .funnyWarp,
        .xmasWarm, .xmasSanta
    ]

    
    // Các ảnh filter đã được load
    private var filterImages: [FilterType: UIImage] = [:]
    
    // Lock để bảo vệ truy cập đồng thời
    private let filterLock = NSLock()
    
    private init() {
        loadFilterImages()
    }
    
    // Load tất cả ảnh filter
    private func loadFilterImages() {
        for filterType in availableFilters {
            let name = filterType.imageName
            if name.isEmpty { continue } // bỏ qua filter biến dạng không dùng ảnh
            if let image = UIImage(named: name) {
                filterImages[filterType] = image
            } else {
                print("⚠️ Filter image not found: \(name)")
            }
        }
    }
    
    // Thiết lập filter hiện tại
    func setFilter(_ filter: FilterType?) {
        filterLock.lock()
        defer { filterLock.unlock() }
        
        currentFilter = filter
        print("🎭 Filter set: \(filter?.displayName ?? "None")")
    }
    
    // Lấy danh sách tất cả filter
    func getAllFilters() -> [FilterType] {
        return availableFilters
    }
    
    // Lấy filter hiện tại
    func getCurrentFilter() -> FilterType? {
        return currentFilter
    }
    
    // Kiểm tra xem filter có sẵn hay không
    func isFilterAvailable(_ filter: FilterType) -> Bool {
        return UIImage(named: filter.imageName) != nil
    }
    
    // Áp dụng filter lên hình ảnh - phiên bản đơn giản hóa không sử dụng landmarks
    func applyFilter(to image: UIImage, with landmarks: Any? = nil) -> UIImage {
        guard let filter = currentFilter else {
            return image
        }
        
        // Nếu có landmarks và đúng kiểu, sử dụng phương thức động
        if let faceLandmarks = landmarks as? FaceLandmarkerResult,
           !faceLandmarks.faceLandmarks.isEmpty {
            if let filteredImage = applyDynamicFilter(to: image, with: faceLandmarks, type: filter) {
                return filteredImage
            }
        }
        
        // Fallback to static filter if landmarks not available or dynamic filter failed
        return applyStaticFilter(to: image, type: filter)
    }
    
    // Áp dụng filter tĩnh (đặt ở vị trí cố định)
    func applyStaticFilter(to image: UIImage, type: FilterType) -> UIImage {
        if let filteredImage = applyStaticFilter(to: image, type: type, viewSize: image.size) {
            return filteredImage
        }
        return image
    }
    
    // Áp dụng filter tĩnh với kích thước view tùy chỉnh
    func applyStaticFilter(to image: UIImage, type: FilterType, viewSize: CGSize) -> UIImage? {
        guard let filterImage = filterImages[type] else {
            return image
        }
        
        // Tạo context để vẽ
        UIGraphicsBeginImageContextWithOptions(viewSize, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        // Vẽ ảnh gốc nếu cần
        if image.size.width > 1 && image.size.height > 1 {
            image.draw(at: .zero)
        }
        
        // Tính toán kích thước và vị trí filter tùy theo loại
        var filterRect = CGRect.zero
        
        switch type {
        case .dogFace:
            // Vị trí mặt chó - phía trên giữa
            let width = viewSize.width * 0.7
            let height = width * 0.8
            let x = (viewSize.width - width) / 2
            let y = viewSize.height * 0.1
            filterRect = CGRect(x: x, y: y, width: width, height: height)
            
        case .glasses:
            // Vị trí kính - giữa trên
            let width = viewSize.width * 0.8
            let height = width * 0.4
            let x = (viewSize.width - width) / 2
            let y = viewSize.height * 0.33
            filterRect = CGRect(x: x, y: y, width: width, height: height)
            
        case .mustache:
            // Vị trí râu - giữa dưới
            let width = viewSize.width * 0.5
            let height = width * 0.3
            let x = (viewSize.width - width) / 2
            let y = viewSize.height * 0.55
            filterRect = CGRect(x: x, y: y, width: width, height: height)
            
        case .hat:
            // Vị trí mũ - trên đỉnh đầu
            let width = viewSize.width * 0.8
            let height = width * 0.6
            let x = (viewSize.width - width) / 2
            let y = viewSize.height * 0.05
            filterRect = CGRect(x: x, y: y, width: width, height: height)
        
        case .xmasSanta:
            // Không vẽ static (cần landmarks cho mũ + râu)
            return image
        case .xmasBeard:
            // Không vẽ static (cần landmarks)
            return image
        case .beauty, .funnyBigEyes, .funnyTinyNose, .funnyWideMouth, .funnyPuffyCheeks, .funnySwirl, .funnyLongChin, .funnyMegaFace, .funnyAlienHead, .funnyWarp, .xmasWarm:
            // Filter beauty/biến dạng, không dùng overlay ảnh
            return image
        case .none:
            return image
        }
        
        // Vẽ filter
        filterImage.draw(in: filterRect)
        
        // Lấy ảnh kết quả
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    // Áp dụng filter động dựa trên landmarks
    func applyDynamicFilter(to image: UIImage, with landmarks: FaceLandmarkerResult, type: FilterType, isFrontCamera: Bool = false) -> UIImage? {
        guard !landmarks.faceLandmarks.isEmpty, 
              let firstFace = landmarks.faceLandmarks.first,
              let filterImage = filterImages[type] else {
            return nil
        }
        
        // Tạo context để vẽ
        UIGraphicsBeginImageContextWithOptions(image.size, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }
        
        // Vẽ ảnh gốc
        image.draw(at: .zero)
        
        // Tính toán kích thước và vị trí filter dựa trên landmarks
        var filterRect = CGRect.zero
        
        switch type {
        case .dogFace:
            // Tính toán hình chữ nhật bao quanh khuôn mặt
            if let faceRect = getFaceRect(from: firstFace, in: image.size, isFrontCamera: isFrontCamera) {
                let width = faceRect.width * 1.5
                let height = width * 0.8
                filterRect = CGRect(
                    x: faceRect.midX - width/2,
                    y: faceRect.minY - height * 0.2,
                    width: width,
                    height: height
                )
                print("🐶 Dog face filter rect: \(filterRect)")
            }
            
        case .glasses:
            // Sử dụng các điểm landmarks mắt
            if firstFace.count >= 468 {
                let leftEyeIdx = 33  // Điểm ngoài cùng bên trái của mắt trái
                let rightEyeIdx = 263 // Điểm ngoài cùng bên phải của mắt phải
                let leftEyeBottomIdx = 145  // Điểm dưới của mắt trái
                let rightEyeBottomIdx = 374 // Điểm dưới của mắt phải
                
                let leftEye = convertLandmarkToPoint(firstFace[leftEyeIdx], in: image.size, isFrontCamera: isFrontCamera)
                let rightEye = convertLandmarkToPoint(firstFace[rightEyeIdx], in: image.size, isFrontCamera: isFrontCamera)
                let leftEyeBottom = convertLandmarkToPoint(firstFace[leftEyeBottomIdx], in: image.size, isFrontCamera: isFrontCamera)
                let rightEyeBottom = convertLandmarkToPoint(firstFace[rightEyeBottomIdx], in: image.size, isFrontCamera: isFrontCamera)
                
                let eyeDistance = distance(from: leftEye, to: rightEye)
                let width = eyeDistance * 2.2
                let height = width * 0.5
                
                // Vị trí Y dựa trên điểm dưới mắt
                let yPosition = (leftEyeBottom.y + rightEyeBottom.y) / 2
                
                filterRect = CGRect(
                    x: (leftEye.x + rightEye.x)/2 - width/2,
                    y: yPosition - height * 0.35,
                    width: width,
                    height: height
                )
                print("👓 Glasses filter rect: \(filterRect), eye distance: \(eyeDistance)")
            }
            
        case .mustache:
            // Sử dụng các điểm landmarks miệng và mũi
            if firstFace.count >= 468 {
                let noseBottomIdx = 2   // Điểm dưới mũi (ước lượng)
                let mouthTopIdx = 0     // Điểm giữa trên của miệng
                let leftMouthIdx = 61   // Điểm trái của miệng
                let rightMouthIdx = 291 // Điểm phải của miệng
                
                let noseBottom = convertLandmarkToPoint(firstFace[noseBottomIdx], in: image.size, isFrontCamera: isFrontCamera)
                let mouthTop = convertLandmarkToPoint(firstFace[mouthTopIdx], in: image.size, isFrontCamera: isFrontCamera)
                let leftMouth = convertLandmarkToPoint(firstFace[leftMouthIdx], in: image.size, isFrontCamera: isFrontCamera)
                let rightMouth = convertLandmarkToPoint(firstFace[rightMouthIdx], in: image.size, isFrontCamera: isFrontCamera)
                
                let mouthWidth = distance(from: leftMouth, to: rightMouth)
                let width = mouthWidth * 1.5
                let height = width * 0.35
                let centerX = (leftMouth.x + rightMouth.x) / 2
                
                // Đặt theo tâm râu để ổn định giữa live và ảnh: nội suy giữa môi trên và đáy mũi
                let lipToNose = max(noseBottom.y - mouthTop.y, 0)
                let centerY = mouthTop.y + lipToNose * 0.42
                
                filterRect = CGRect(
                    x: centerX - width/2,
                    y: centerY - height/2,
                    width: width,
                    height: height
                )
                print("👨 Mustache filter rect: \(filterRect), mouth width: \(mouthWidth)")
            } else {
                print("⚠️ firstFace.count < 468: \(firstFace.count)")
            }
            
        case .hat:
            // Sử dụng các landmark cụ thể cho mũ
            if firstFace.count >= 468 {
                let topHeadIdx = 10    // Điểm đỉnh đầu
                let foreheadIdx = 151  // Điểm giữa trán
                
                let topHead = convertLandmarkToPoint(firstFace[topHeadIdx], in: image.size, isFrontCamera: isFrontCamera)
                let forehead = convertLandmarkToPoint(firstFace[foreheadIdx], in: image.size, isFrontCamera: isFrontCamera)
                
                // Tính toán kích thước khuôn mặt để xác định kích thước mũ
                if let faceRect = getFaceRect(from: firstFace, in: image.size, isFrontCamera: isFrontCamera) {
                    let faceWidth = faceRect.width
                    
                    // Tính toán chiều cao đầu
                    _ = distance(from: topHead, to: forehead)
                    
                    let width = faceWidth * 1.8
                    let height = width * 0.8
                    
                    filterRect = CGRect(
                        x: topHead.x - width/2,
                        y: topHead.y - height * 0.7, // Điều chỉnh vị trí mũ lên cao hơn
                        width: width,
                        height: height
                    )
                    print("🎩 Hat filter rect: \(filterRect)")
                }
            }
        
        case .xmasSanta:
            if firstFace.count >= 468,
               let faceRect = getFaceRect(from: firstFace, in: image.size, isFrontCamera: isFrontCamera) {
                // 1) Mũ Noel (dựa vào 159/386)
                if let santaHat = UIImage(named: FilterType.xmasSanta.imageName) {
                    let leftBrow = convertLandmarkToPoint(firstFace[159], in: image.size, isFrontCamera: isFrontCamera)
                    let rightBrow = convertLandmarkToPoint(firstFace[386], in: image.size, isFrontCamera: isFrontCamera)
                    let browCenter = CGPoint(x: (leftBrow.x + rightBrow.x)/2.0, y: (leftBrow.y + rightBrow.y)/2.0)
                    let hatWidth = faceRect.width * 1.9
                    let hatAspect = santaHat.size.height / max(1, santaHat.size.width)
                    let hatHeight = hatWidth * hatAspect
                    let hatTopY = browCenter.y - hatHeight
                    santaHat.draw(in: CGRect(x: faceRect.midX - hatWidth/2, y: hatTopY, width: hatWidth, height: hatHeight))
                }
                // 2) Râu Noel (midpoint môi trên–cằm)
                if let beard = UIImage(named: "filter_chrismas_beard") {
                    let upperLip = convertLandmarkToPoint(firstFace[0], in: image.size, isFrontCamera: isFrontCamera)
                    let chin = convertLandmarkToPoint(firstFace[152], in: image.size, isFrontCamera: isFrontCamera)
                    let center = CGPoint(x: (upperLip.x + chin.x)/2.0, y: (upperLip.y + chin.y)/2.0)
                    let lipToChin = distance(from: upperLip, to: chin)
                    let beardHeight = lipToChin * 1.2
                    let beardWidth = max(faceRect.width * 1.7, beardHeight) // giữ tỉ lệ rộng
                    let beardAspect = beard.size.height / max(1, beard.size.width)
                    let finalBeardHeight = beardWidth * beardAspect
                    let beardRect = CGRect(x: center.x - beardWidth/2,
                                           y: center.y - finalBeardHeight/2,
                                           width: beardWidth,
                                           height: finalBeardHeight)
                    beard.draw(in: beardRect)
                }
                return UIGraphicsGetImageFromCurrentImageContext()
            }
        case .xmasBeard:
            // Không xử lý trong hàm này (đã có overlay/live path); giữ nguyên ảnh
            return image
        
        case .beauty, .funnyBigEyes, .funnyTinyNose, .funnyWideMouth, .funnyPuffyCheeks, .funnySwirl, .funnyLongChin, .funnyMegaFace, .funnyAlienHead, .funnyWarp, .xmasWarm:
            // Filter biến dạng, không vẽ overlay ảnh ở pipeline này
            return image
        case .none:
            return image
        }
        
        // Vẽ filter nếu có vị trí hợp lệ
        if filterRect.width > 0 && filterRect.height > 0 {
            filterImage.draw(in: filterRect)
            return UIGraphicsGetImageFromCurrentImageContext()
        } else {
            print("⚠️ Could not calculate filter position")
            return image
        }
    }
    
    // Helper method để chuyển đổi landmark thành điểm CGPoint
    private func convertLandmarkToPoint(_ landmark: NormalizedLandmark, in viewSize: CGSize, isFrontCamera: Bool = false) -> CGPoint {
        // Đảm bảo điểm nằm trong khoảng [0, 1]
        let x = min(max(CGFloat(landmark.x), 0), 1)
        let y = min(max(CGFloat(landmark.y), 0), 1)
        
        // Xử lý tọa độ dựa vào camera
        var pointX = x
        
        // Đối với camera trước, cần phản chiếu tọa độ x
        if isFrontCamera {
            pointX = 1 - x
        }
        
        // Quy đổi tọa độ normalized [0-1] thành tọa độ điểm ảnh thực tế
        // Đối với camera trước, cần điều chỉnh tỉ lệ và vị trí
        let finalX = pointX * viewSize.width
        
        // Điều chỉnh tọa độ Y để phù hợp với tỉ lệ khung hình
        // MediaPipe trả về tọa độ Y từ trên xuống dưới, UIKit cũng vậy
        let finalY = y * viewSize.height
        
        // Debug log
        print("🔍 Converting landmark (\(x), \(y)) to point (\(finalX), \(finalY)) with isFrontCamera=\(isFrontCamera)")
        
        return CGPoint(x: finalX, y: finalY)
    }
    
    // Helper method để tính khoảng cách giữa hai điểm
    private func distance(from point1: CGPoint, to point2: CGPoint) -> CGFloat {
        return sqrt(pow(point2.x - point1.x, 2) + pow(point2.y - point1.y, 2))
    }
    
    // Helper method để tính rectangle bao quanh khuôn mặt
    private func getFaceRect(from landmarks: [NormalizedLandmark], in viewSize: CGSize, isFrontCamera: Bool = false) -> CGRect? {
        guard !landmarks.isEmpty else { return nil }
        
        // Tìm giá trị min/max cho các điểm landmark
        var minX: CGFloat = 1.0
        var minY: CGFloat = 1.0
        var maxX: CGFloat = 0.0
        var maxY: CGFloat = 0.0
        
        for landmark in landmarks {
            let x = CGFloat(landmark.x)
            let y = CGFloat(landmark.y)
            
            minX = min(minX, x)
            minY = min(minY, y)
            maxX = max(maxX, x)
            maxY = max(maxY, y)
        }
        
        // Xử lý phản chiếu cho camera trước
        var left = minX
        var right = maxX
        
        if isFrontCamera {
            left = 1 - maxX
            right = 1 - minX
        }
        
        // Chuyển đổi sang tọa độ view
        let viewLeft = left * viewSize.width
        let viewTop = minY * viewSize.height
        let viewWidth = (right - left) * viewSize.width
        let viewHeight = (maxY - minY) * viewSize.height
        
        let rect = CGRect(x: viewLeft, y: viewTop, width: viewWidth, height: viewHeight)
        print("📐 Face rect: \(rect) (isFrontCamera=\(isFrontCamera))")
        
        return rect
    }
    
    // Phương thức mới để cập nhật filter overlay với tỉ lệ khung hình chính xác
    func updateFilterOverlayWithCorrectAspectRatio(_ filterOverlay: UIImageView, with landmarksResult: FaceLandmarkerResult?, viewSize: CGSize, frameSize: CGSize, isFrontCamera: Bool = false) {
        // Đảm bảo luôn chạy trên main thread để dùng UIGraphics an toàn
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.updateFilterOverlayWithCorrectAspectRatio(filterOverlay, with: landmarksResult, viewSize: viewSize, frameSize: frameSize, isFrontCamera: isFrontCamera)
            }
            return
        }
        guard let filterType = currentFilter else {
            filterOverlay.image = nil
            return
        }
        print("🧩 updateOverlay: type=\(filterType.displayName) front=\(isFrontCamera) view=\(viewSize) frame=\(frameSize) hasLandmarks=\(!(landmarksResult?.faceLandmarks.isEmpty ?? true))")
        
        // Tạo context để vẽ
        UIGraphicsBeginImageContextWithOptions(viewSize, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }
        
        // Trường hợp đặc biệt: Ông già Noel (mũ + râu) tự vẽ, không phụ thuộc filterImage chung
        if filterType == .xmasSanta {
            if let landmarks = landmarksResult, let firstFace = landmarks.faceLandmarks.first {
                let faceRect: CGRect? = { () -> CGRect? in
                    // Map nhanh face rect từ landmarks đã chuẩn hóa
                    var minX: CGFloat = 1, minY: CGFloat = 1, maxX: CGFloat = 0, maxY: CGFloat = 0
                    for lm in firstFace { minX = min(minX, CGFloat(lm.x)); minY = min(minY, CGFloat(lm.y)); maxX = max(maxX, CGFloat(lm.x)); maxY = max(maxY, CGFloat(lm.y)) }
                    var left = minX, right = maxX
                    if isFrontCamera { left = 1 - maxX; right = 1 - minX }
                    let scale = max(viewSize.width / frameSize.width, viewSize.height / frameSize.height)
                    let scaledSize = CGSize(width: frameSize.width * scale, height: frameSize.height * scale)
                    let offsetX = (viewSize.width - scaledSize.width) / 2.0
                    let offsetY = (viewSize.height - scaledSize.height) / 2.0
                    let leftFrame = left * frameSize.width
                    let topFrame = minY * frameSize.height
                    let widthFrame = (right - left) * frameSize.width
                    let heightFrame = (maxY - minY) * frameSize.height
                    return CGRect(x: leftFrame * scale + offsetX,
                                  y: topFrame * scale + offsetY,
                                  width: widthFrame * scale,
                                  height: heightFrame * scale)
                }()
                if let faceRectUnwrapped = faceRect {
                    func mapPoint(_ lm: NormalizedLandmark) -> CGPoint {
                        let scale = max(viewSize.width / frameSize.width, viewSize.height / frameSize.height)
                        let scaledSize = CGSize(width: frameSize.width * scale, height: frameSize.height * scale)
                        let offsetX = (viewSize.width - scaledSize.width) / 2.0
                        let offsetY = (viewSize.height - scaledSize.height) / 2.0
                        let xNorm0 = CGFloat(lm.x)
                        let xNorm = isFrontCamera ? (1 - xNorm0) : xNorm0
                        let yNorm = CGFloat(lm.y)
                        let xFrame = xNorm * frameSize.width
                        let yFrame = yNorm * frameSize.height
                        return CGPoint(x: xFrame * scale + offsetX, y: yFrame * scale + offsetY)
                    }
                    // Vẽ mũ (chỉ khi đủ landmarks)
                    if let santaHat = UIImage(named: FilterType.xmasSanta.imageName), firstFace.count > 386 {
                        let leftBrow = mapPoint(firstFace[159])
                        let rightBrow = mapPoint(firstFace[386])
                        let browCenter = CGPoint(x: (leftBrow.x + rightBrow.x)/2.0, y: (leftBrow.y + rightBrow.y)/2.0)
                        let hatWidth = faceRectUnwrapped.width * 1.9
                        let hatAspect = santaHat.size.height / max(1, santaHat.size.width)
                        let hatHeight = hatWidth * hatAspect
                        let hatTopY = browCenter.y - hatHeight
                        santaHat.draw(in: CGRect(x: faceRectUnwrapped.midX - hatWidth/2, y: hatTopY, width: hatWidth, height: hatHeight))
                    }
                    // Vẽ râu (chỉ khi đủ landmarks)
                    if let beard = UIImage(named: "filter_chrismas_beard"), firstFace.count > 152 {
                        let upperLip = mapPoint(firstFace[0])
                        let chin = mapPoint(firstFace[152])
                        let center = CGPoint(x: (upperLip.x + chin.x)/2.0, y: (upperLip.y + chin.y)/2.0)
                        let beardAspect = beard.size.height / max(1, beard.size.width)
                        let beardWidth = faceRectUnwrapped.width * 1.25
                        let finalBeardHeight = beardWidth * beardAspect
                        let offsetDown = faceRectUnwrapped.height * 0.10
                        let rect = CGRect(x: center.x - beardWidth/2, y: center.y - finalBeardHeight/2 + offsetDown, width: beardWidth, height: finalBeardHeight)
                        beard.draw(in: rect)
                    }
                    filterOverlay.image = UIGraphicsGetImageFromCurrentImageContext()
                    filterOverlay.isHidden = false
                    print("✅ Applied Santa overlay (early path)")
                    return
                } else {
            filterOverlay.image = nil
            return
        }
            }
        }
        
        // Early path cho các overlay cơ bản: glasses, mustache, hat, dogFace
        if let landmarks = landmarksResult, let firstFace = landmarks.faceLandmarks.first,
           [.glasses, .mustache, .hat, .dogFace].contains(filterType) {
            func mapPoint(_ lm: NormalizedLandmark) -> CGPoint {
                let scale = max(viewSize.width / frameSize.width, viewSize.height / frameSize.height)
                let scaledSize = CGSize(width: frameSize.width * scale, height: frameSize.height * scale)
                let offsetX = (viewSize.width - scaledSize.width) / 2.0
                let offsetY = (viewSize.height - scaledSize.height) / 2.0
                let xNorm0 = CGFloat(lm.x)
                let xNorm = isFrontCamera ? (1 - xNorm0) : xNorm0
                let yNorm = CGFloat(lm.y)
                let xFrame = xNorm * frameSize.width
                let yFrame = yNorm * frameSize.height
                return CGPoint(x: xFrame * scale + offsetX, y: yFrame * scale + offsetY)
            }
            func faceRectFromLandmarks(_ points: [NormalizedLandmark]) -> CGRect? {
                var minX: CGFloat = 1, minY: CGFloat = 1, maxX: CGFloat = 0, maxY: CGFloat = 0
                for lm in points { minX = min(minX, CGFloat(lm.x)); minY = min(minY, CGFloat(lm.y)); maxX = max(maxX, CGFloat(lm.x)); maxY = max(maxY, CGFloat(lm.y)) }
                var left = minX, right = maxX
                if isFrontCamera { left = 1 - maxX; right = 1 - minX }
                let scale = max(viewSize.width / frameSize.width, viewSize.height / frameSize.height)
                let scaledSize = CGSize(width: frameSize.width * scale, height: frameSize.height * scale)
                let offsetX = (viewSize.width - scaledSize.width) / 2.0
                let offsetY = (viewSize.height - scaledSize.height) / 2.0
                let leftFrame = left * frameSize.width
                let topFrame = minY * frameSize.height
                let widthFrame = (right - left) * frameSize.width
                let heightFrame = (maxY - minY) * frameSize.height
                return CGRect(x: leftFrame * scale + offsetX,
                              y: topFrame * scale + offsetY,
                              width: widthFrame * scale,
                              height: heightFrame * scale)
            }
            switch filterType {
            case .glasses:
                guard let overlay = UIImage(named: FilterType.glasses.imageName) else { print("⚠️ Missing image for glasses (early path)"); break }
                if firstFace.count >= 468 {
                    let leftEye = mapPoint(firstFace[33])
                    let rightEye = mapPoint(firstFace[263])
                    let leftEyeBottom = mapPoint(firstFace[145])
                    let rightEyeBottom = mapPoint(firstFace[374])
                    let eyeDistance = distance(from: leftEye, to: rightEye)
                    let width = eyeDistance * 2.2
                    let height = width * 0.5
                    let yPosition = (leftEyeBottom.y + rightEyeBottom.y) / 2
                    let rect = CGRect(x: (leftEye.x + rightEye.x)/2 - width/2,
                                      y: yPosition - height * 0.35,
                                      width: width,
                                      height: height)
                    overlay.draw(in: rect)
                    print("✅ Applied glasses (early) at: \(rect)")
                    filterOverlay.image = UIGraphicsGetImageFromCurrentImageContext()
                    filterOverlay.isHidden = false
                    return
                }
            case .mustache:
                guard let overlay = UIImage(named: FilterType.mustache.imageName) else { print("⚠️ Missing image for mustache (early path)"); break }
                if firstFace.count >= 468 {
                    let noseBottom = mapPoint(firstFace[2])
                    let mouthTop = mapPoint(firstFace[0])
                    let leftMouth = mapPoint(firstFace[61])
                    let rightMouth = mapPoint(firstFace[291])
                    let mouthWidth = distance(from: leftMouth, to: rightMouth)
                    let width = mouthWidth * 1.5
                    let height = width * 0.35
                    let centerX = (leftMouth.x + rightMouth.x) / 2
                    let y = mouthTop.y + height * 0.10
                    let rect = CGRect(x: centerX - width/2, y: y, width: width, height: height)
                    overlay.draw(in: rect)
                    print("✅ Applied mustache (early) at: \(rect)")
                    filterOverlay.image = UIGraphicsGetImageFromCurrentImageContext()
                    filterOverlay.isHidden = false
                    return
                }
            case .hat:
                guard let overlay = UIImage(named: FilterType.hat.imageName) else { print("⚠️ Missing image for hat (early path)"); break }
                if let fr = faceRectFromLandmarks(firstFace) {
                    let width = fr.width * 1.8
                    let height = width * 0.8
                    let topHead = mapPoint(firstFace[10])
                    let rect = CGRect(x: topHead.x - width/2,
                                      y: topHead.y - height * 0.7,
                                      width: width,
                                      height: height)
                    overlay.draw(in: rect)
                    print("✅ Applied hat (early) at: \(rect)")
                    filterOverlay.image = UIGraphicsGetImageFromCurrentImageContext()
                    filterOverlay.isHidden = false
                    return
                }
            case .dogFace:
                guard let overlay = UIImage(named: FilterType.dogFace.imageName) else { print("⚠️ Missing image for dogFace (early path)"); break }
                if let fr = faceRectFromLandmarks(firstFace) {
                    let width = fr.width * 1.25
                    let height = width * 0.75
                    let rect = CGRect(x: fr.midX - width/2,
                                      y: fr.minY - height * 0.15,
                                      width: width,
                                      height: height)
                    overlay.draw(in: rect)
                    print("✅ Applied dogFace (early) at: \(rect)")
                    filterOverlay.image = UIGraphicsGetImageFromCurrentImageContext()
                    filterOverlay.isHidden = false
                    return
                }
            default:
                break
            }
        }
        
        // Ảnh overlay mặc định cho các filter overlay dùng 1 ảnh (dog, glasses, mustache, hat)
        let baseFilterImage = UIImage(named: filterType.imageName)
        print("🧾 baseFilterImage name=\(filterType.imageName) exists=\(baseFilterImage != nil)")
        
        // Nếu không có landmarks, sử dụng filter tĩnh
        if landmarksResult == nil || landmarksResult!.faceLandmarks.isEmpty {
            if let staticFilterImage = applyStaticFilter(to: UIImage(), type: filterType, viewSize: viewSize) {
                filterOverlay.image = staticFilterImage
            } else {
                filterOverlay.image = nil
            }
            return
        }
        
        // Nếu có landmarks, sử dụng dữ liệu landmarks để vẽ filter
        guard let firstFace = landmarksResult!.faceLandmarks.first else {
            filterOverlay.image = nil
            return
        }
        print("🧮 firstFace.count=\(firstFace.count) for type=\(filterType.displayName)")
        
        // Tính toán tỉ lệ khung hình thực tế của camera preview
        // Điều này quan trọng vì tọa độ MediaPipe được chuẩn hóa trong khoảng [0,1]
        // nhưng khung hình camera có thể có tỉ lệ khác với UIImageView
        
        // Map tọa độ từ frame camera sang preview (aspectFill)
        let scale = max(viewSize.width / frameSize.width, viewSize.height / frameSize.height)
        let scaledSize = CGSize(width: frameSize.width * scale, height: frameSize.height * scale)
        let offsetX = (viewSize.width - scaledSize.width) / 2.0
        let offsetY = (viewSize.height - scaledSize.height) / 2.0
        
        func mapPoint(_ landmark: NormalizedLandmark) -> CGPoint {
            let xNormOriginal = CGFloat(landmark.x)
            let xNorm = isFrontCamera ? (1 - xNormOriginal) : xNormOriginal
            let yNorm = CGFloat(landmark.y)
            let xFrame = xNorm * frameSize.width
            let yFrame = yNorm * frameSize.height
            return CGPoint(x: xFrame * scale + offsetX, y: yFrame * scale + offsetY)
        }
        
        func mapFaceRect(_ landmarks: [NormalizedLandmark]) -> CGRect? {
            guard !landmarks.isEmpty else { return nil }
            var minX: CGFloat = 1, minY: CGFloat = 1, maxX: CGFloat = 0, maxY: CGFloat = 0
            for lm in landmarks {
                let xNormOriginal = CGFloat(lm.x)
                let xNorm = isFrontCamera ? (1 - xNormOriginal) : xNormOriginal
                let yNorm = CGFloat(lm.y)
                minX = min(minX, xNorm)
                minY = min(minY, yNorm)
                maxX = max(maxX, xNorm)
                maxY = max(maxY, yNorm)
            }
            let left = minX
            let right = maxX
            let top = minY
            let bottom = maxY
            let leftFrame = left * frameSize.width
            let topFrame = top * frameSize.height
            let widthFrame = (right - left) * frameSize.width
            let heightFrame = (bottom - top) * frameSize.height
            return CGRect(x: leftFrame * scale + offsetX,
                          y: topFrame * scale + offsetY,
                          width: widthFrame * scale,
                          height: heightFrame * scale)
        }
        
        // Tính toán kích thước và vị trí filter dựa trên landmarks
        var filterRect = CGRect.zero
        print("🚩 entering switch for type=\(filterType.displayName)")
        
        switch filterType {
        case .dogFace:
            guard let _ = baseFilterImage else { print("⚠️ Missing image for dogFace: \(filterType.imageName)"); break }
            // Tính toán hình chữ nhật bao quanh khuôn mặt
            if let faceRect = mapFaceRect(firstFace) {
                let width = faceRect.width * 1.25
                let height = width * 0.75
                filterRect = CGRect(
                    x: faceRect.midX - width/2,
                    y: faceRect.minY - height * 0.15,
                    width: width,
                    height: height
                )
                print("🐶 Dog face filter rect: \(filterRect)")
            }
            
        case .glasses:
            print("🚩 inside case .glasses")
            guard let _ = baseFilterImage else { print("⚠️ Missing image for glasses: \(filterType.imageName)"); break }
            // Sử dụng các điểm landmarks mắt
            if firstFace.count >= 468 {
                let leftEyeIdx = 33  // Điểm ngoài cùng bên trái của mắt trái
                let rightEyeIdx = 263 // Điểm ngoài cùng bên phải của mắt phải
                let leftEyeBottomIdx = 145  // Điểm dưới của mắt trái
                let rightEyeBottomIdx = 374 // Điểm dưới của mắt phải
                
                let leftEye = mapPoint(firstFace[leftEyeIdx])
                let rightEye = mapPoint(firstFace[rightEyeIdx])
                let leftEyeBottom = mapPoint(firstFace[leftEyeBottomIdx])
                let rightEyeBottom = mapPoint(firstFace[rightEyeBottomIdx])
                
                let eyeDistance = distance(from: leftEye, to: rightEye)
                let width = eyeDistance * 1.6
                let height = width * 0.5
                
                // Vị trí Y dựa trên điểm dưới mắt
                let yPosition = (leftEyeBottom.y + rightEyeBottom.y) / 2
                
                filterRect = CGRect(
                    x: (leftEye.x + rightEye.x)/2 - width/2,
                    y: yPosition - height * 0.3,
                    width: width,
                    height: height
                )
                print("👓 Glasses filter rect: \(filterRect), eye distance: \(eyeDistance)")
            }
            
        case .mustache:
            guard let _ = baseFilterImage else { print("⚠️ Missing image for mustache: \(filterType.imageName)"); break }
            print("🧪 Enter mustache case")
            // Sử dụng các điểm landmarks miệng và mũi
            if firstFace.count >= 468 {
                let noseBottomIdx = 2   // Điểm dưới mũi (ước lượng)
                let mouthTopIdx = 0     // Điểm giữa trên của miệng
                let leftMouthIdx = 61   // Điểm trái của miệng
                let rightMouthIdx = 291 // Điểm phải của miệng
                
                let noseBottom = mapPoint(firstFace[noseBottomIdx])
                let mouthTop = mapPoint(firstFace[mouthTopIdx])
                let leftMouth = mapPoint(firstFace[leftMouthIdx])
                let rightMouth = mapPoint(firstFace[rightMouthIdx])
                print("🧪 Points noseBottom=\(noseBottom) mouthTop=\(mouthTop) leftMouth=\(leftMouth) rightMouth=\(rightMouth)")
                
                let mouthWidth = distance(from: leftMouth, to: rightMouth)
                let width = mouthWidth * 1.5
                let height = width * 0.35
                let centerX = (leftMouth.x + rightMouth.x) / 2
                
                // Đặt râu ngay dưới mũi, không chạm môi
                let y = min(noseBottom.y + height * 0.05, mouthTop.y - height * 0.25)
                
                filterRect = CGRect(
                    x: centerX - width/2,
                    y: y,
                    width: width,
                    height: height
                )
                print("👨 Mustache filter rect: \(filterRect), mouth width: \(mouthWidth)")
            } else {
                print("⚠️ firstFace.count < 468: \(firstFace.count)")
            }
            
        case .hat:
            guard let _ = baseFilterImage else { print("⚠️ Missing image for hat: \(filterType.imageName)"); break }
            // Sử dụng các landmark cụ thể cho mũ
            if firstFace.count >= 468 {
                let topHeadIdx = 10    // Điểm đỉnh đầu
                let foreheadIdx = 151  // Điểm giữa trán
                
                let topHead = mapPoint(firstFace[topHeadIdx])
                let forehead = mapPoint(firstFace[foreheadIdx])
                
                // Tính toán kích thước khuôn mặt để xác định kích thước mũ
                if let faceRect = mapFaceRect(firstFace) {
                    let faceWidth = faceRect.width
                    
                    // Tính toán chiều cao đầu
                    let headHeight = distance(from: topHead, to: forehead)
                    _ = headHeight
                    
                    let width = faceWidth * 1.8
                    let height = width * 0.8
                    
                    filterRect = CGRect(
                        x: topHead.x - width/2,
                        y: topHead.y - height * 0.7, // Điều chỉnh vị trí mũ lên cao hơn
                        width: width,
                        height: height
                    )
                    print("🎩 Hat filter rect: \(filterRect)")
                }
            }
        
        case .xmasSanta:
            if firstFace.count >= 468,
               let faceRect = mapFaceRect(firstFace) {
                // 1) Mũ Noel (dựa vào 159/386)
                if let santaHat = UIImage(named: FilterType.xmasSanta.imageName) {
                    let leftBrow = mapPoint(firstFace[159])
                    let rightBrow = mapPoint(firstFace[386])
                    let browCenter = CGPoint(x: (leftBrow.x + rightBrow.x)/2.0, y: (leftBrow.y + rightBrow.y)/2.0)
                    let hatWidth = faceRect.width * 1.9
                    let hatAspect = santaHat.size.height / max(1, santaHat.size.width)
                    let hatHeight = hatWidth * hatAspect
                    let hatTopY = browCenter.y - hatHeight
                    santaHat.draw(in: CGRect(x: faceRect.midX - hatWidth/2, y: hatTopY, width: hatWidth, height: hatHeight))
                }
                // 2) Râu Noel (midpoint môi trên–cằm)
                if let beard = UIImage(named: FilterType.xmasBeard.imageName) {
                    let upperLip = mapPoint(firstFace[0])
                    let chin = mapPoint(firstFace[152])
                    let center = CGPoint(x: (upperLip.x + chin.x)/2.0, y: (upperLip.y + chin.y)/2.0)
                    let lipToChin = distance(from: upperLip, to: chin)
                    let beardHeight = lipToChin * 1.2
                    let beardWidth = max(faceRect.width * 1.7, beardHeight) // giữ tỉ lệ rộng
                    let beardAspect = beard.size.height / max(1, beard.size.width)
                    let finalBeardHeight = beardWidth * beardAspect
                    let beardRect = CGRect(x: center.x - beardWidth/2,
                                           y: center.y - finalBeardHeight/2,
                                           width: beardWidth,
                                           height: finalBeardHeight)
                    beard.draw(in: beardRect)
                }
                filterOverlay.image = UIGraphicsGetImageFromCurrentImageContext()
                filterOverlay.isHidden = false
                print(" Applied Santa overlay")
                return
            } else {
                filterOverlay.image = nil
            }
        case .xmasBeard:
            if firstFace.count > 152,
               let faceRect = mapFaceRect(firstFace),
               let beard = UIImage(named: FilterType.xmasBeard.imageName) {
                let upperLip = mapPoint(firstFace[0])
                let chin = mapPoint(firstFace[152])
                let center = CGPoint(x: (upperLip.x + chin.x)/2.0, y: (upperLip.y + chin.y)/2.0)
                let aspect = beard.size.height / max(1, beard.size.width)
                let beardWidth = faceRect.width * 1.25
                let finalHeight = beardWidth * aspect
                let offsetDown = faceRect.height * 0.10
                let rect = CGRect(x: center.x - beardWidth/2,
                                  y: center.y - finalHeight/2 + offsetDown,
                                  width: beardWidth,
                                  height: finalHeight)
                beard.draw(in: rect)
                print(" Applied XmasBeard overlay at: \(rect)")
                filterOverlay.image = UIGraphicsGetImageFromCurrentImageContext()
                filterOverlay.isHidden = false
                return
            } else {
                filterOverlay.image = nil
                return
            }
        case .funnyBigEyes, .funnyTinyNose, .funnyWideMouth, .funnyPuffyCheeks, .funnySwirl, .funnyLongChin, .funnyMegaFace, .funnyAlienHead, .funnyWarp, .beauty, .xmasWarm:
            // Filter biến dạng, không vẽ overlay ảnh ở pipeline overlay
            filterOverlay.image = nil
            return
        case .none:
            filterOverlay.image = nil
            return
        }
        print(" after switch, filterRect=\(filterRect)")
        
        // Vẽ filter nếu có vị trí hợp lệ và có ảnh base
        if filterRect.width > 0 && filterRect.height > 0, let overlayImage = baseFilterImage {
            print(" Drawing overlay image size=\(overlayImage.size) at rect=\(filterRect)")
            overlayImage.draw(in: filterRect)
            filterOverlay.image = UIGraphicsGetImageFromCurrentImageContext()
            filterOverlay.isHidden = false
            print(" Applied filter to overlay at: \(filterRect)")
        } else {
            print(" Could not calculate filter position or missing base image. rect=\(filterRect) hasImage=\(baseFilterImage != nil)")
            // Vẽ ô debug để kiểm tra mapping nếu có rect nhưng thiếu ảnh hoặc rect vẫn hợp lệ
            if filterRect.width > 0 && filterRect.height > 0 {
                UIColor.red.withAlphaComponent(0.2).setFill()
                UIBezierPath(rect: filterRect).fill()
                filterOverlay.image = UIGraphicsGetImageFromCurrentImageContext()
                filterOverlay.isHidden = false
                print("Drew debug rect at: \(filterRect)")
            } else {
            filterOverlay.image = nil
            }
        }
    }
    
    // Cập nhật filter overlay với dữ liệu landmarks
    func updateFilterOverlay(_ filterOverlay: UIImageView, with landmarksResult: FaceLandmarkerResult?, viewSize: CGSize, isFrontCamera: Bool = false) {
        updateFilterOverlay(filterOverlay, with: landmarksResult, viewSize: viewSize, frameSize: viewSize, isFrontCamera: isFrontCamera)
    }
    
    // API mới: truyền thêm frameSize để map đúng khi preview dùng aspectFill
    func updateFilterOverlay(_ filterOverlay: UIImageView, with landmarksResult: FaceLandmarkerResult?, viewSize: CGSize, frameSize: CGSize, isFrontCamera: Bool = false) {
        updateFilterOverlayWithCorrectAspectRatio(filterOverlay, with: landmarksResult, viewSize: viewSize, frameSize: frameSize, isFrontCamera: isFrontCamera)
    }
} 
