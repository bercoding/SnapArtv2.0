import UIKit
import MediaPipeTasksVision

class MediaPipeFaceMeshManager {
    static let shared = MediaPipeFaceMeshManager()
    
    // Face Landmarker
    private var faceLandmarker: FaceLandmarker?
    private var isInitializing: Bool = false
    private var didInitFailOnce: Bool = false
    
    // Model path
    private let modelPath = "face_landmarker"
    
    private init() {
        setupFaceLandmarker()
        
        // Đăng ký lắng nghe thông báo khi app vào background để giải phóng tài nguyên
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil)
            
        // Đăng ký lắng nghe thông báo khi app hoạt động trở lại để khởi tạo lại nếu cần
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        cleanupFaceLandmarker()
    }
    
    @objc private func appDidEnterBackground() {
        // Giải phóng tài nguyên khi app vào background
        cleanupFaceLandmarker()
    }
    
    @objc private func appWillEnterForeground() {
        // Khởi tạo lại khi app hoạt động trở lại
        if faceLandmarker == nil {
            setupFaceLandmarker()
        }
    }
    
    // Giải phóng faceLandmarker để giảm sử dụng bộ nhớ
    private func cleanupFaceLandmarker() {
        faceLandmarker = nil
        isInitializing = false
    }
    
    // Đảm bảo đã khởi tạo trước khi sử dụng
    private func ensureInitialized() {
        if faceLandmarker == nil && !isInitializing {
            if didInitFailOnce {
                print("♻️ Re-attempting FaceLandmarker initialization after previous failure…")
            }
            setupFaceLandmarker()
        }
    }
    
    // Khởi tạo Face Landmarker
    private func setupFaceLandmarker() {
        if isInitializing { return }
        isInitializing = true
        didInitFailOnce = false
        defer { isInitializing = false }
        do {
            // Tìm đường dẫn file model - thử nhiều cách khác nhau
            var modelFilePath: String?
            
            // Cách 1: Tìm trong thư mục Resources
            if let path1 = Bundle.main.path(forResource: modelPath, 
                                           ofType: "task", 
                                           inDirectory: "Resources") {
                // Kiểm tra file có thực sự tồn tại không
                if FileManager.default.fileExists(atPath: path1) {
                    modelFilePath = path1
                    print("📁 Tìm thấy model trong thư mục Resources: \(path1)")
                } else {
                    print("⚠️ File không tồn tại mặc dù path được tìm thấy: \(path1)")
                }
            }
            // Cách 2: Tìm trực tiếp trong bundle
            else if let path2 = Bundle.main.path(forResource: modelPath, 
                                                ofType: "task") {
                if FileManager.default.fileExists(atPath: path2) {
                    modelFilePath = path2
                    print("📁 Tìm thấy model trực tiếp trong bundle: \(path2)")
                } else {
                    print("⚠️ File không tồn tại mặc dù path được tìm thấy: \(path2)")
                }
            }
            
            // Không tìm thấy file model
            if modelFilePath == nil {
                print("⚠️ Face landmarker model không tìm thấy, kiểm tra các đường dẫn:")
                let bundlePath = Bundle.main.bundlePath
                print("- Bundle path: \(bundlePath)")
                
                // Kiểm tra thư mục Resources
                let resourcesPath = Bundle.main.bundlePath + "/Resources"
                print("- Resources path: \(resourcesPath)")
                
                let fileManager = FileManager.default
                if let files = try? fileManager.contentsOfDirectory(atPath: bundlePath) {
                    print("- Các file trong bundle:")
                    for file in files {
                        print("  + \(file)")
                    }
                }
                
                if let resourceFiles = try? fileManager.contentsOfDirectory(atPath: resourcesPath) {
                    print("- Các file trong Resources:")
                    for file in resourceFiles {
                        print("  + \(file)")
                    }
                }
                didInitFailOnce = true
                return
            }
            
            // Cấu hình Face Landmarker
            var options = FaceLandmarkerOptions()
            guard let finalModelPath = modelFilePath else {
                print("⚠️ Face landmarker model path is nil")
                didInitFailOnce = true
                return
            }
            
            options.baseOptions.modelAssetPath = finalModelPath

            // Tối ưu cấu hình - đơn giản hóa
            options.runningMode = .image // Sử dụng .image cho xử lý frame-by-frame
            options.outputFaceBlendshapes = false // Không cần blendshapes
            options.outputFacialTransformationMatrixes = false // Không cần transformation matrices
            options.numFaces = 1 // Chỉ phát hiện 1 khuôn mặt để tối ưu hiệu suất

            print("🔧 Khởi tạo Face Landmarker với cấu hình:")
            print("- Model path: \(finalModelPath)")
            print("- Running mode: image")
            print("- Max faces: 1")
            
            // Khởi tạo Face Landmarker
            do {
                let startTime = CACurrentMediaTime()
                faceLandmarker = try FaceLandmarker(options: options)
                let endTime = CACurrentMediaTime()
                print("✅ Khởi tạo Face Landmarker thành công! (\((endTime - startTime) * 1000) ms)")
                didInitFailOnce = false
            } catch {
                print("❌ Lỗi khởi tạo face landmarker: \(error)")
                print("❌ Chi tiết lỗi: \(error.localizedDescription)")
                
                // Hiển thị thông tin chi tiết hơn nếu là NSError
                if let nsError = error as NSError? {
                    print("❌ Error domain: \(nsError.domain)")
                    print("❌ Error code: \(nsError.code)")
                    print("❌ Error user info: \(nsError.userInfo)")
                }
                faceLandmarker = nil
                didInitFailOnce = true
            }
        } catch {
            print("❌ Lỗi khởi tạo face landmarker: \(error)")
            print("❌ Chi tiết lỗi: \(error.localizedDescription)")
            faceLandmarker = nil
            didInitFailOnce = true
        }
    }
    
    // Phát hiện face mesh trong hình ảnh
    func detectFaceMesh(in image: UIImage) -> FaceLandmarkerResult? {
        ensureInitialized()
        guard let faceLandmarker = faceLandmarker else {
            print("⚠️ Face landmarker chưa được khởi tạo")
            return nil
        }
        
        print("📊 Detecting face mesh in image: \(image.size.width) x \(image.size.height)")
        
        // Sử dụng autoreleasepool để quản lý bộ nhớ tốt hơn
        return autoreleasepool { () -> FaceLandmarkerResult? in
            do {
                // Chuyển đổi UIImage sang MPImage - Xử lý ngoại lệ
                var mpImage: MPImage?
                do {
                    mpImage = try MPImage(uiImage: image)
                    print("✅ Successfully converted UIImage to MPImage")
                } catch {
                    print("⚠️ Không thể chuyển đổi UIImage sang MPImage: \(error)")
                    return nil
                }
                
                guard let mpImage = mpImage else {
                    print("⚠️ MPImage là nil sau khi chuyển đổi")
                    return nil
                }
                
                // Sử dụng semaphore để đảm bảo chỉ có một tiến trình phát hiện cùng lúc
                let semaphore = DispatchSemaphore(value: 1)
                var detectionResult: FaceLandmarkerResult?
                
                semaphore.wait()
                
                // Phát hiện khuôn mặt
                do {
                    print("🔍 Running MediaPipe face detection...")
                    let startTime = CACurrentMediaTime()
                    detectionResult = try faceLandmarker.detect(image: mpImage)
                    let endTime = CACurrentMediaTime()
                    print("⏱️ MediaPipe face detection took \((endTime - startTime) * 1000) ms")
                    
                    // Kiểm tra kết quả
                    if let result = detectionResult {
                        if result.faceLandmarks.isEmpty {
                            print("ℹ️ Không phát hiện khuôn mặt trong ảnh")
                        } else {
                            print("✅ Đã phát hiện \(result.faceLandmarks.count) khuôn mặt với \(result.faceLandmarks.first?.count ?? 0) landmarks")
                        }
                    }
                } catch {
                    print("❌ Lỗi phát hiện khuôn mặt: \(error)")
                    
                    // Hiển thị chi tiết lỗi nếu có thể
                    if let nsError = error as NSError? {
                        print("❌ Error domain: \(nsError.domain), code: \(nsError.code)")
                        print("❌ Error description: \(nsError.localizedDescription)")
                    }
                }
                
                semaphore.signal()
                return detectionResult
                
            } catch {
                print("❌ Lỗi phát hiện khuôn mặt: \(error)")
                return nil
            }
        }
    }
    
    // Phát hiện face mesh từ camera frame
    func detectFaceMesh(in pixelBuffer: CVPixelBuffer) -> FaceLandmarkerResult? {
        ensureInitialized()
        guard let faceLandmarker = faceLandmarker else {
            print("⚠️ Face landmarker chưa được khởi tạo")
            return nil
        }
        
        // Sử dụng autoreleasepool để quản lý bộ nhớ tốt hơn
        return autoreleasepool { () -> FaceLandmarkerResult? in
            do {
                // Chuyển đổi CVPixelBuffer sang MPImage - Xử lý ngoại lệ
                var mpImage: MPImage?
                do {
                    mpImage = try MPImage(pixelBuffer: pixelBuffer)
                } catch {
                    print("⚠️ Không thể chuyển đổi CVPixelBuffer sang MPImage: \(error)")
                    return nil
                }
                
                guard let mpImage = mpImage else {
                    print("⚠️ MPImage là nil sau khi chuyển đổi")
                    return nil
                }
                
                // Phát hiện khuôn mặt
                do {
                    let detectionResult = try faceLandmarker.detect(image: mpImage)
                    
                    // Kiểm tra kết quả
                    if detectionResult.faceLandmarks.isEmpty {
                        print("ℹ️ Không phát hiện khuôn mặt trong frame")
                    } else {
                        print("✅ Đã phát hiện \(detectionResult.faceLandmarks.count) khuôn mặt với \(detectionResult.faceLandmarks.first?.count ?? 0) landmarks")
                    }
                    
                    return detectionResult
                } catch {
                    print("❌ Lỗi phát hiện khuôn mặt từ camera: \(error)")
                    return nil
                }
            } catch {
                print("❌ Lỗi phát hiện khuôn mặt từ camera: \(error)")
                return nil
            }
        }
    }
    
    // Kiểm tra trạng thái của Face Landmarker
    func checkStatus() -> Bool {
        return faceLandmarker != nil
    }
    
    func restartFaceLandmarker() {
        print("🔄 Đang khởi động lại FaceLandmarker…")
        cleanupFaceLandmarker()
        setupFaceLandmarker()
    }
    
    // Hàm áp dụng filter lên hình ảnh
    func applyFilter(on image: UIImage, landmarks: FaceLandmarkerResult, filterType: FilterType) -> UIImage? {
        print("🎭 Applying filter: \(filterType.displayName) with landmarks")
        guard !landmarks.faceLandmarks.isEmpty, let _ = landmarks.faceLandmarks.first else {
            print("⚠️ No face landmarks found, returning original image")
            return image
        }
        // Ủy quyền cho FilterManager để đảm bảo một nguồn logic duy nhất ở View/Filter
        if let rendered = FilterManager.shared.applyDynamicFilter(
            to: image,
            with: landmarks,
            type: filterType,
            isFrontCamera: false
        ) {
            return rendered
        }
        return image
    }
    
    // Helper method để chuyển đổi landmark thành điểm CGPoint
    private func convertLandmarkToPoint(_ landmark: NormalizedLandmark, in viewSize: CGSize) -> CGPoint {
        let x = min(max(CGFloat(landmark.x), 0), 1)
        let y = min(max(CGFloat(landmark.y), 0), 1)
        
        // Chuyển đổi giá trị chuẩn hóa sang tọa độ thực
        // Lưu ý: Không lật tọa độ x ở đây vì việc đó sẽ được xử lý ở CameraViewController
        // tùy thuộc vào loại camera (trước/sau)
        return CGPoint(x: x * viewSize.width, y: y * viewSize.height)
    }

    // Helper method để tính khoảng cách giữa hai điểm
    private func distance(from point1: CGPoint, to point2: CGPoint) -> CGFloat {
        return sqrt(pow(point2.x - point1.x, 2) + pow(point2.y - point1.y, 2))
    }

    // Helper method để tính rectangle bao quanh khuôn mặt
    private func getFaceRect(from landmarks: [NormalizedLandmark], in viewSize: CGSize) -> CGRect? {
        guard !landmarks.isEmpty else { return nil }
        
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
        
        let left = minX * viewSize.width
        let top = minY * viewSize.height
        let width = (maxX - minX) * viewSize.width
        let height = (maxY - minY) * viewSize.height
        
        return CGRect(x: left, y: top, width: width, height: height)
    }
    
    // Hiển thị alert yêu cầu quyền camera
 
}
