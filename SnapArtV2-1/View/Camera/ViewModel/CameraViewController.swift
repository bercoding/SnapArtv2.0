import AVFoundation
import MediaPipeTasksVision
import SnapArtV2_1
import UIKit

class CameraViewController: UIViewController {
    // MARK: - Properties
    
    // Camera capture
    private var captureSession: AVCaptureSession?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private let captureQueue = DispatchQueue(label: "captureQueue")
    
    // Output
    private var videoDataOutput = AVCaptureVideoDataOutput()
    private let photoOutput = AVCapturePhotoOutput()
    
    // UI elements
    private let previewView = UIView()
    private let filterSelectionView = UIView()
    private let filterScrollView = UIScrollView()
    private let captureButton = UIButton()
    private var filterOverlay: UIImageView? // Thêm property này để lưu trữ filter overlay
    private let closeButton = UIButton() // Nút thoát camera
    private let warpResetButton = UIButton() // Nút reset biến dạng funnyWarp
    private let beautySlider = UISlider() // Slider chỉnh beauty
    private var beautySmooth: CGFloat = 0.4
    private var beautyBright: CGFloat = 0.25
    
    // Face mesh
    private let faceMeshManager = MediaPipeFaceMeshManager.shared
    private let filterManager = SnapArtV2_1.FilterManager.shared
    private var filterButtons: [UIButton] = []
    
    // Processing state
    private var isProcessingFrame = false
    private var lastProcessedTimestamp: TimeInterval = 0
    private let frameProcessInterval: TimeInterval = 0.1 // Giới hạn tối đa 10 frame/giây
    
    // CI
    private let ciContext = CIContext(options: nil)
    
    // Callback khi thoát camera
    var onDismiss: (() -> Void)?
    var saveImageAction: ((UIImage, String?) -> Void)? // Action để lưu ảnh thông qua GalleryViewModel
    
    // Ảnh chờ xác nhận lưu
    private var pendingCapturedImage: UIImage?
    private var pendingFilterType: FilterType?
    
    // UI preview ảnh sau khi chụp
    private var capturePreviewView: UIView?
    private var capturePreviewImageView: UIImageView?
    
    // Warp realtime
    private var activeWarps: [Int: (start: CGPoint, current: CGPoint, radius: CGFloat, mode: String)] = [:]
    private struct WarpStamp {
        let center: CGPoint
        let radius: CGFloat
        let mode: String // "pinch" | "bump"
        let scale: CGFloat // độ mạnh hiệu ứng đã chốt
    }

    private var committedWarpStamps: [WarpStamp] = []

    // Christmas animated effects
    private var christmasEffectView: UIView?
    private var snowEmitterLayer: CAEmitterLayer?
    private var sparkleEmitterLayer: CAEmitterLayer?
    private var iconsOverlayView: UIView?
    private var xmasWarmIconView: UIImageView?
    private var xmasWarmBackgroundView: UIImageView?

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        checkCameraPermission()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Start session only after camera permission granted and setup complete
        if AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
            startCaptureSession()
        }
        // Đảm bảo bật/tắt hiệu ứng Noel theo filter hiện tại ngay khi vào màn hình
        updateChristmasEffectsVisibility()
        updateXmasWarmBackgroundVisibility()
        updateXmasWarmIconVisibility()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopCaptureSession()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutUIForSafeAreas()
        updateChristmasEffectsLayout()
        // Cập nhật layout cho background Noel
        updateXmasWarmBackgroundVisibility()
        // Đảm bảo thứ tự lớp đúng sau khi layout
        if let bg = xmasWarmBackgroundView { previewView.sendSubviewToBack(bg) }
        if let overlay = filterOverlay { previewView.bringSubviewToFront(overlay) }
        if let effectView = christmasEffectView { previewView.bringSubviewToFront(effectView) }
        if let iconsView = iconsOverlayView {
            iconsView.frame = previewView.bounds
            if let iv = xmasWarmIconView, let img = iv.image {
                let margin: CGFloat = 8
                let maxWidth = previewView.bounds.width * 0.28
                let aspect = img.size.height / max(1, img.size.width)
                let width = maxWidth
                let height = width * aspect
                iv.frame = CGRect(x: margin, y: margin + view.safeAreaInsets.top, width: width, height: height)
            }
            // đảm bảo trên cùng
            previewView.bringSubviewToFront(iconsView)
        }
    }
    
    private func layoutUIForSafeAreas() {
        let safeTop = view.safeAreaInsets.top
        let safeBottom = view.safeAreaInsets.bottom
        
        // Preview & overlay
        previewView.frame = view.bounds
        filterOverlay?.frame = previewView.bounds
        christmasEffectView?.frame = previewView.bounds
        
        // Capture button
        let captureSize: CGFloat = 70
        let captureBottomPadding: CGFloat = max(16, safeBottom + 12)
        captureButton.frame = CGRect(
            x: (view.bounds.width - captureSize) / 2,
            y: view.bounds.height - captureSize - captureBottomPadding,
            width: captureSize,
            height: captureSize
        )
        captureButton.layer.cornerRadius = captureSize / 2
        
    
        let filterHeight: CGFloat = 100
        let spacingBetweenFilterAndCapture: CGFloat = 24
        let filterY = max(safeTop + 80, captureButton.frame.minY - filterHeight - spacingBetweenFilterAndCapture)
        filterSelectionView.frame = CGRect(
            x: 0,
            y: filterY,
            width: view.bounds.width,
            height: filterHeight
        )
        filterScrollView.frame = filterSelectionView.bounds
        
        // Close button (góc phải trên, theo safe area)
        let closeSize: CGFloat = 44
        let rightMargin: CGFloat = 20
        closeButton.frame = CGRect(
            x: view.bounds.width - closeSize - rightMargin,
            y: safeTop + 8,
            width: closeSize,
            height: closeSize
        )
        closeButton.layer.cornerRadius = closeSize / 2

        // Warp reset button (góc trái trên, theo safe area)
        let resetSize: CGFloat = 40
        warpResetButton.frame = CGRect(x: 20, y: safeTop + 8, width: resetSize, height: resetSize)
        warpResetButton.layer.cornerRadius = resetSize / 2
        
        // Beauty slider (nằm ngay trên thanh chọn filter)
        let sliderHeight: CGFloat = 34
        beautySlider.frame = CGRect(x: 20, y: filterSelectionView.frame.minY - sliderHeight - 8, width: view.bounds.width - 40, height: sliderHeight)
    }
    
    // MARK: - Camera Permission
    
    private func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            // Permission already granted
            setupCamera()
//            checkFaceMeshStatus()
        case .notDetermined:
            // Request permission
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.setupCamera()
//                        self?.checkFaceMeshStatus()
                        self?.startCaptureSession()
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.showPermissionAlert()
                    }
                }
            }
        case .denied, .restricted:
            showPermissionAlert()
            // Thêm một số UI để người dùng biết rằng camera không hoạt động
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                let label = UILabel()
                label.text = "Cần quyền truy cập camera để sử dụng tính năng này"
                label.textAlignment = .center
                label.textColor = .white
                label.backgroundColor = UIColor.black.withAlphaComponent(0.7)
                label.numberOfLines = 0
                label.frame = self.view.bounds
                self.view.addSubview(label)
                
                // Thêm nút thoát
                self.setupCloseButton()
            }
        @unknown default:
            showPermissionAlert()
        }
    }
    
    private func showPermissionAlert() {
        let alert = UIAlertController(
            title: "Cần quyền truy cập camera",
            message: "Vui lòng cấp quyền truy cập camera trong Cài đặt để sử dụng tính năng này",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Đi đến Cài đặt", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Hủy", style: .cancel) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        
        present(alert, animated: true)
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .black
        
        // Setup preview view
        previewView.frame = view.bounds
        previewView.contentMode = .scaleAspectFill
        previewView.backgroundColor = .black
        view.addSubview(previewView)
        
        // Setup capture button
        setupCaptureButton()
        
        // Setup filter selection view
        setupFilterSelectionView()
        
        // Setup close button
        setupCloseButton()
        
        // Setup warp reset button (ẩn mặc định)
        setupWarpResetButton()
        
        // Setup beauty slider (ẩn mặc định)
        setupBeautySlider()
    }
    
    private func setupFilterOverlay() {
        guard filterOverlay == nil else { return }
        
        let overlay = UIImageView(frame: previewView.bounds)
        overlay.contentMode = .scaleAspectFill
        overlay.clipsToBounds = true
        overlay.backgroundColor = .clear
        overlay.isUserInteractionEnabled = true
        // Gesture
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleWarpPan(_:)))
        pan.maximumNumberOfTouches = 2
        overlay.addGestureRecognizer(pan)
        let long = UILongPressGestureRecognizer(target: self, action: #selector(handleWarpLongPress(_:)))
        overlay.addGestureRecognizer(long)
        previewView.addSubview(overlay)
        previewView.bringSubviewToFront(overlay)
        
        filterOverlay = overlay
        print("✅ Filter overlay setup complete")
    }
    
    private func setupCaptureButton() {
        let buttonSize: CGFloat = 70
        let bottomMargin: CGFloat = 30
        
        captureButton.frame = CGRect(
            x: (view.bounds.width - buttonSize) / 2,
            y: view.bounds.height - buttonSize - bottomMargin,
            width: buttonSize,
            height: buttonSize
        )
        
        captureButton.backgroundColor = .white
        captureButton.layer.cornerRadius = buttonSize / 2
        captureButton.layer.borderWidth = 3
        captureButton.layer.borderColor = UIColor.lightGray.cgColor
        
        captureButton.addTarget(self, action: #selector(captureButtonTapped), for: .touchUpInside)
        
        view.addSubview(captureButton)
    }
    
    private func setupFilterSelectionView() {
        let height: CGFloat = 100
        let bottomMargin: CGFloat = 120
        
        filterSelectionView.frame = CGRect(
            x: 0,
            y: view.bounds.height - height - bottomMargin,
            width: view.bounds.width,
            height: height
        )
        
        filterSelectionView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.addSubview(filterSelectionView)
        // Scroll view bên trong để lướt chọn filter
        filterScrollView.frame = filterSelectionView.bounds
        filterScrollView.showsHorizontalScrollIndicator = false
        filterScrollView.alwaysBounceHorizontal = true
        filterScrollView.alwaysBounceVertical = false
        filterScrollView.backgroundColor = .clear
        filterSelectionView.addSubview(filterScrollView)
        
        setupFilterButtons()
    }
    
    private func setupCloseButton() {
        let buttonSize: CGFloat = 44
        let topMargin: CGFloat = 40
        let rightMargin: CGFloat = 20
        
        closeButton.frame = CGRect(
            x: view.bounds.width - buttonSize - rightMargin,
            y: topMargin,
            width: buttonSize,
            height: buttonSize
        )
        
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        closeButton.layer.cornerRadius = buttonSize / 2
        
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        
        view.addSubview(closeButton)
    }

    private func setupWarpResetButton() {
        let buttonSize: CGFloat = 40
        warpResetButton.frame = CGRect(x: 20, y: 40, width: buttonSize, height: buttonSize)
        if let img = UIImage(systemName: "arrow.counterclockwise") {
            warpResetButton.setImage(img, for: .normal)
        } else {
            warpResetButton.setTitle("↺", for: .normal)
            warpResetButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        }
        warpResetButton.tintColor = .white
        warpResetButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        warpResetButton.layer.cornerRadius = buttonSize / 2
        warpResetButton.isHidden = true
        warpResetButton.addTarget(self, action: #selector(warpResetButtonTapped), for: .touchUpInside)
        previewView.addSubview(warpResetButton)
    }
    
    private func setupBeautySlider() {
        beautySlider.minimumValue = 0
        beautySlider.maximumValue = 1
        beautySlider.value = Float(beautySmooth)
        beautySlider.tintColor = .systemPink
        beautySlider.isHidden = true
        beautySlider.addTarget(self, action: #selector(onBeautySliderChanged(_:)), for: .valueChanged)
        view.addSubview(beautySlider)
    }
    
    private func updateBeautySliderVisibility() {
        let isBeauty = (filterManager.currentFilter == .beauty)
        beautySlider.isHidden = !isBeauty
        if isBeauty {
            view.bringSubviewToFront(beautySlider)
        }
    }
    
    @objc private func onBeautySliderChanged(_ sender: UISlider) {
        // Dùng 1 slider: map thành smooth và bright
        let v = CGFloat(sender.value)
        beautySmooth = v // 0..1
        beautyBright = max(0, min(1, v * 0.6))
    }
    
    private func updateWarpResetButtonVisibility() {
        let isWarp = (filterManager.currentFilter == .funnyWarp)
        warpResetButton.isHidden = !isWarp
        if isWarp {
            previewView.bringSubviewToFront(warpResetButton)
        }
    }
    
    @objc private func warpResetButtonTapped() {
        activeWarps.removeAll()
        committedWarpStamps.removeAll()
        // Hiệu ứng thông báo ngắn
        let label = UILabel()
        label.text = "Reset trạng thái ban đầu!"
        label.textColor = .white
        label.textAlignment = .center
        label.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        label.layer.cornerRadius = 8
        label.layer.masksToBounds = true
        label.frame = CGRect(x: 0, y: 0, width: 150, height: 34)
        label.center = CGPoint(x: view.bounds.midX, y: view.safeAreaInsets.top + 70)
        view.addSubview(label)
        UIView.animate(withDuration: 0.2, animations: { label.alpha = 1 }) { _ in
            UIView.animate(withDuration: 0.35, delay: 0.8, options: [], animations: { label.alpha = 0 }) { _ in
                label.removeFromSuperview()
            }
        }
    }
    
    private func setupFilterButtons() {
        // Xóa các button cũ nếu có
        for button in filterButtons {
            button.removeFromSuperview()
        }
        filterButtons.removeAll()
        
        // Lấy danh sách filter từ FilterManager
        let filters = [FilterType.none] + filterManager.getAllFilters()
        
        // Layout trong scroll view
        let buttonSize: CGFloat = 60
        let spacing: CGFloat = 16
        let sidePadding: CGFloat = 16
        var cursorX: CGFloat = sidePadding
        let centerY = (filterSelectionView.bounds.height - buttonSize) / 2
        
        for (index, filter) in filters.enumerated() {
            let button = UIButton(type: .custom)
            button.frame = CGRect(x: cursorX, y: centerY, width: buttonSize, height: buttonSize)
            
            // Thiết lập hình ảnh và tiêu đề
            if filter == .none {
                button.setTitle("❌", for: .normal)
                button.titleLabel?.font = UIFont.systemFont(ofSize: 30)
            } else {
                button.setTitle(filter.icon, for: .normal)
                button.titleLabel?.font = UIFont.systemFont(ofSize: 30)
            }
            
            button.backgroundColor = UIColor.darkGray.withAlphaComponent(0.7)
            button.layer.cornerRadius = buttonSize / 2
            button.tag = index // Sử dụng tag để xác định filter
            button.addTarget(self, action: #selector(filterButtonTapped(_:)), for: .touchUpInside)
            
            // Highlight button nếu là filter hiện tại
            if filter == filterManager.currentFilter {
                button.layer.borderWidth = 3
                button.layer.borderColor = UIColor.white.cgColor
            }
            
            filterScrollView.addSubview(button)
            filterButtons.append(button)
            cursorX += buttonSize + spacing
        }
        filterScrollView.contentSize = CGSize(width: cursorX + sidePadding - spacing, height: filterSelectionView.bounds.height)
    }
    
    // MARK: - Actions
    
    @objc private func captureButtonTapped() {
        print("📸 Capture button tapped")
        capturePhoto()
    }
    
    @objc private func closeButtonTapped() {
        print("❌ Close button tapped")
        stopCaptureSession()
        dismiss(animated: true) {
            self.onDismiss?()
        }
    }
    
    @objc private func filterButtonTapped(_ sender: UIButton) {
        // Lấy danh sách filter từ FilterManager
        let filters = [FilterType.none] + filterManager.getAllFilters()
        
        // Xác định filter được chọn
        let selectedIndex = sender.tag
        if selectedIndex < filters.count {
            let selectedFilter = filters[selectedIndex]
            
            // Thiết lập filter mới
            if selectedFilter == .none {
                filterManager.setFilter(nil)
                print("🎭 Filter cleared")
            } else {
                filterManager.setFilter(selectedFilter)
                print("🎭 Filter set to: \(selectedFilter.displayName)")
            }
            
            // Nếu rời khỏi funnyWarp thì reset biến dạng đã commit
            if selectedFilter != .funnyWarp {
                activeWarps.removeAll()
                committedWarpStamps.removeAll()
            }
            // Cập nhật hiển thị nút reset
            updateWarpResetButtonVisibility()
            // Cập nhật slider beauty
            updateBeautySliderVisibility()
            // Cập nhật hiệu ứng Giáng Sinh
            updateChristmasEffectsVisibility()
            // Cập nhật background + icon cố định cho xmasWarm
            updateXmasWarmBackgroundVisibility()
            updateXmasWarmIconVisibility()
            
            // Cập nhật UI
            updateFilterButtonsHighlight(selectedIndex: selectedIndex)
            
            // Cập nhật filter overlay nếu có
            if let filterOverlay = filterOverlay {
                // Sử dụng FilterManager để cập nhật overlay
                filterManager.updateFilterOverlayWithCorrectAspectRatio(
                    filterOverlay,
                    with: nil as FaceLandmarkerResult?,
                    viewSize: previewView.bounds.size,
                    frameSize: previewView.bounds.size,
                    isFrontCamera: isFrontCameraActive()
                )
                // Đảm bảo tuyết nằm trên overlay
                if let effectView = christmasEffectView {
                    previewView.bringSubviewToFront(effectView)
                }
                // Và icon cố định nằm trên tất cả
                if let iconsView = iconsOverlayView {
                    previewView.bringSubviewToFront(iconsView)
                }
                // Đảm bảo background luôn nằm trên camera layer
                if let bg = xmasWarmBackgroundView {
                    previewView.bringSubviewToFront(bg)
                }
            }
        }
    }
    
    private func updateFilterButtonsHighlight(selectedIndex: Int) {
        for (index, button) in filterButtons.enumerated() {
            if index == selectedIndex {
                button.layer.borderWidth = 3
                button.layer.borderColor = UIColor.white.cgColor
            } else {
                button.layer.borderWidth = 0
            }
        }
        // Tự động cuộn để nút được chọn nằm giữa
        if selectedIndex < filterButtons.count {
            let button = filterButtons[selectedIndex]
            let targetMidX = button.frame.midX
            let halfWidth = filterScrollView.bounds.width / 2
            var offsetX = targetMidX - halfWidth
            offsetX = max(0, min(offsetX, filterScrollView.contentSize.width - filterScrollView.bounds.width))
            filterScrollView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: true)
        }
    }

    // MARK: - Christmas Effects (Snow + Sparkles)

    private func updateChristmasEffectsVisibility() {
        let type = filterManager.currentFilter
        let shouldEnable = (type == .xmasWarm) || (type == .xmasSanta)
        if shouldEnable { startChristmasEffects() } else { stopChristmasEffects() }
    }

    private func ensureChristmasEffectView() {
        if christmasEffectView == nil {
            let v = UIView(frame: previewView.bounds)
            v.backgroundColor = .clear
            previewView.addSubview(v)
            // Đặt trên overlay để hiệu ứng nằm trên cùng lớp camera
            if let overlay = filterOverlay {
                previewView.bringSubviewToFront(overlay)
                previewView.bringSubviewToFront(v)
            }
            // Đưa các control UI lên trên cùng
            view.bringSubviewToFront(closeButton)
            view.bringSubviewToFront(captureButton)
            view.bringSubviewToFront(filterSelectionView)
            view.bringSubviewToFront(beautySlider)
            view.bringSubviewToFront(warpResetButton)
            christmasEffectView = v
        }
    }

    private func startChristmasEffects() {
        ensureChristmasEffectView()
        guard let host = christmasEffectView else { return }

        // Nếu đã tồn tại emitter, cập nhật layout và thoát
        if snowEmitterLayer != nil || sparkleEmitterLayer != nil {
            updateChristmasEffectsLayout()
            return
        }
        // Snow - to và rõ hơn
        let snow = CAEmitterLayer()
        snow.emitterShape = .line
        snow.emitterMode = .surface
        snow.frame = host.bounds
        snow.emitterPosition = CGPoint(x: host.bounds.midX, y: -6)
        snow.emitterSize = CGSize(width: host.bounds.width + 60, height: 1)
        snow.birthRate = 1
        snow.speed = 1
        snow.zPosition = 1

        let bigSnow = CAEmitterCell()
        bigSnow.contents = makeParticleImage(diameter: 12, color: .white, alpha: 1.0)
        bigSnow.birthRate = 14
        bigSnow.lifetime = 16
        bigSnow.lifetimeRange = 6
        bigSnow.velocity = 110
        bigSnow.velocityRange = 50
        bigSnow.yAcceleration = 45
        bigSnow.xAcceleration = 10
        bigSnow.emissionLongitude = .pi
        bigSnow.emissionRange = .pi / 10
        bigSnow.spin = 0.8
        bigSnow.spinRange = 1.2
        bigSnow.scale = 0.09
        bigSnow.scaleRange = 0.05
        bigSnow.alphaSpeed = -0.015

        let smallSnow = CAEmitterCell()
        smallSnow.contents = makeParticleImage(diameter: 7, color: .white, alpha: 0.95)
        smallSnow.birthRate = 18
        smallSnow.lifetime = 14
        smallSnow.lifetimeRange = 5
        smallSnow.velocity = 80
        smallSnow.velocityRange = 40
        smallSnow.yAcceleration = 40
        smallSnow.xAcceleration = 12
        smallSnow.emissionLongitude = .pi
        smallSnow.emissionRange = .pi / 8
        smallSnow.spin = 0.6
        smallSnow.spinRange = 1.0
        smallSnow.scale = 0.07
        smallSnow.scaleRange = 0.04
        smallSnow.alphaSpeed = -0.02

        snow.emitterCells = [bigSnow, smallSnow]

        host.layer.addSublayer(snow)
        snowEmitterLayer = snow

        // Nếu là .xmasSanta thì thêm sparkles; .xmasWarm chỉ có tuyết
        if filterManager.currentFilter == .xmasSanta {
            let spark = CAEmitterLayer()
            spark.emitterShape = .rectangle
            spark.emitterMode = .surface
            spark.frame = host.bounds
            spark.emitterPosition = CGPoint(x: host.bounds.midX, y: host.bounds.midY)
            spark.emitterSize = host.bounds.size
            spark.birthRate = 1
            spark.speed = 1
            spark.zPosition = 2

            let sparkCell = CAEmitterCell()
            sparkCell.contents = makeParticleImage(diameter: 5, color: UIColor(red: 1, green: 0.95, blue: 0.6, alpha: 1), alpha: 1.0)
            sparkCell.birthRate = 5
            sparkCell.lifetime = 1.8
            sparkCell.lifetimeRange = 0.6
            sparkCell.velocity = 24
            sparkCell.velocityRange = 30
            sparkCell.yAcceleration = 10
            sparkCell.emissionRange = .pi * 2
            sparkCell.scale = 1.2
            sparkCell.scaleRange = 0.8
            sparkCell.alphaSpeed = -0.7
            sparkCell.spin = 1.6
            sparkCell.spinRange = 2.2
            spark.emitterCells = [sparkCell]
            host.layer.addSublayer(spark)
            sparkleEmitterLayer = spark
        } else {
            sparkleEmitterLayer = nil
        }

        // Đảm bảo hiệu ứng nằm trên overlay và dưới UI control
        if let overlay = filterOverlay {
            previewView.bringSubviewToFront(overlay)
            if let effectView = christmasEffectView { previewView.bringSubviewToFront(effectView) }
        }
        if let iconsView = iconsOverlayView { previewView.bringSubviewToFront(iconsView) }
    }

    private func stopChristmasEffects() {
        snowEmitterLayer?.removeFromSuperlayer()
        sparkleEmitterLayer?.removeFromSuperlayer()
        snowEmitterLayer = nil
        sparkleEmitterLayer = nil
        // Giữ view để bật lại nhanh; nếu muốn giải phóng hoàn toàn, bỏ comment dòng sau
        // christmasEffectView?.removeFromSuperview(); christmasEffectView = nil
    }

    private func updateChristmasEffectsLayout() {
        guard let host = christmasEffectView else { return }
        snowEmitterLayer?.frame = host.bounds
        sparkleEmitterLayer?.frame = host.bounds
        snowEmitterLayer?.emitterPosition = CGPoint(x: host.bounds.midX, y: -6)
        snowEmitterLayer?.emitterSize = CGSize(width: host.bounds.width + 60, height: 1)
        sparkleEmitterLayer?.emitterPosition = CGPoint(x: host.bounds.midX, y: host.bounds.midY)
        sparkleEmitterLayer?.emitterSize = host.bounds.size
    }

    private func makeParticleImage(diameter: CGFloat, color: UIColor, alpha: CGFloat = 1.0) -> CGImage? {
        let size = CGSize(width: diameter, height: diameter)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { _ in
            let rect = CGRect(origin: .zero, size: size)
            color.withAlphaComponent(alpha).setFill()
            UIBezierPath(ovalIn: rect).fill()
        }
        return img.cgImage
    }

    // MARK: - Camera Setup
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        guard let captureSession = captureSession else { return }
        
        captureSession.sessionPreset = .high
        
        // Setup camera input
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("❌ Could not get front camera")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: frontCamera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                print("✅ Added front camera input")
            }
        } catch {
            print("❌ Error setting up camera input: \(error.localizedDescription)")
            return
        }
        
        // Setup video preview layer
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = .resizeAspectFill
        videoPreviewLayer?.frame = previewView.bounds
        
        if let videoPreviewLayer = videoPreviewLayer {
            // Đặt layer preview ở đáy để mọi subview (background/overlay/effects) nằm trên
            previewView.layer.insertSublayer(videoPreviewLayer, at: 0)
            print("✅ Added video preview layer at bottom")
        }
        
        // Setup video data output
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        
        let videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue")
        videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
            print("✅ Added video data output")
        }
        
        // Setup photo output
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
            print("✅ Added photo output")
        }
        
        // Ensure the connection uses the right orientation
        if let connection = videoDataOutput.connection(with: .video) {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
            if connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = false // data output không mirror
            }
        }
        // Bật mirror cho preview layer (kiểu gương)
        if let plConn = videoPreviewLayer?.connection {
            if plConn.isVideoOrientationSupported {
                plConn.videoOrientation = .portrait
            }
            if plConn.isVideoMirroringSupported {
                plConn.automaticallyAdjustsVideoMirroring = false
                plConn.isVideoMirrored = true
            }
        }
    }
    
    private func startCaptureSession() {
        guard let captureSession = captureSession, !captureSession.isRunning else { return }
        
        captureQueue.async {
            captureSession.startRunning()
            print("✅ Capture session started")
        }
    }
    
    private func stopCaptureSession() {
        guard let captureSession = captureSession, captureSession.isRunning else { return }
        
        captureQueue.async {
            captureSession.stopRunning()
            print("⏹️ Capture session stopped")
        }
    }
    
//    // MARK: - Face Mesh
//
//    private func checkFaceMeshStatus() {
//        if !faceMeshManager.isInitialized {
//            print("⚠️ Face landmarker chưa được khởi tạo")
//            faceMeshManager.initializeFaceLandmarker()
//        }
//    }
    
    // MARK: - Photo Capture
    
    private func capturePhoto() {
        guard let photoOutput = captureSession?.outputs.first(where: { $0 is AVCapturePhotoOutput }) as? AVCapturePhotoOutput else {
            print("❌ Photo output not available")
            return
        }
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .off
        
        photoOutput.capturePhoto(with: settings, delegate: self)
        print("📸 Capturing photo...")
    }
    
    // MARK: - Helper Methods
    
    private func isFrontCameraActive() -> Bool {
        guard let inputs = captureSession?.inputs as? [AVCaptureDeviceInput] else { return false }
        return inputs.first(where: { $0.device.position == .front }) != nil
    }
    
    private func mirrorImage(_ image: UIImage) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        
        let context = UIGraphicsGetCurrentContext()!
        context.translateBy(x: image.size.width, y: 0)
        context.scaleBy(x: -1.0, y: 1.0)
        
        image.draw(in: CGRect(origin: .zero, size: image.size))
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    // Hiển thị popup xác nhận lưu ảnh vào Gallery của app
    private func presentSaveConfirmation(for image: UIImage, filterType: FilterType?) {
        pendingCapturedImage = image
        pendingFilterType = filterType
        let alert = UIAlertController(title: "Lưu ảnh?", message: "Bạn có muốn lưu ảnh này vào Gallery của ứng dụng?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Hủy", style: .cancel, handler: { [weak self] _ in
            self?.pendingCapturedImage = nil
            self?.pendingFilterType = nil
        }))
        alert.addAction(UIAlertAction(title: "Lưu", style: .default, handler: { [weak self] _ in
            guard let self = self, let img = self.pendingCapturedImage else { return }
            self.saveImageToAppGallery(img, filterType: self.pendingFilterType)
            self.pendingCapturedImage = nil
            self.pendingFilterType = nil
        }))
        present(alert, animated: true)
    }
    
    // Lưu ảnh vào Core Data (Gallery của app)
    private func saveImageToAppGallery(_ image: UIImage, filterType: FilterType?) {
        var finalImage = image
        // Nếu là xmasWarm, trộn thêm overlay background_xmas 1 vào ảnh trước khi lưu
        if filterType == .xmasWarm, let overlay = UIImage(named: "background_xmas 1") {
            finalImage = compositeOverlayOnTop(base: image, overlay: overlay)
        }
        
        // Gọi action được truyền vào để lưu ảnh thông qua GalleryViewModel
        saveImageAction?(finalImage, filterType?.displayName)

        // Hiển thị thông báo thành công (có thể chuyển vào GalleryViewModel nếu muốn)
        let successLabel = UILabel()
        successLabel.text = "✅ Đã lưu ảnh"
        successLabel.textAlignment = .center
        successLabel.textColor = .white
        successLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        successLabel.frame = CGRect(x: 0, y: 0, width: 200, height: 50)
        successLabel.center = view.center
        successLabel.layer.cornerRadius = 10
        successLabel.layer.masksToBounds = true
        view.addSubview(successLabel)
        UIView.animate(withDuration: 0.25, animations: { successLabel.alpha = 1 }) { _ in
            UIView.animate(withDuration: 0.4, delay: 1.2, options: [], animations: { successLabel.alpha = 0 }) { _ in
                successLabel.removeFromSuperview()
            }
        }
        // Xóa code lưu CoreData trực tiếp, vì giờ GalleryViewModel sẽ xử lý
        // guard let imageData = finalImage.jpegData(compressionQuality: 0.9) else {
        //     let alert = UIAlertController(title: "Lỗi", message: "Không thể chuyển ảnh thành dữ liệu.", preferredStyle: .alert)
        //     alert.addAction(UIAlertAction(title: "OK", style: .default))
        //     present(alert, animated: true)
        //     return
        // }
        // var metadata: Data? = nil
        // if let ft = filterType {
        //     let dict: [String: Any] = ["filterType": ft.displayName]
        //     metadata = try? JSONSerialization.data(withJSONObject: dict)
        // }
        // do {
        //     _ = try CoreDataManager.shared.saveSavedImage(imageData: imageData, id: UUID(), createdAt: Date(), metadata: metadata)
        //     // Thông báo ngắn
        //     let successLabel = UILabel()
        //     successLabel.text = "✅ Đã lưu vào Gallery"
        //     successLabel.textAlignment = .center
        //     successLabel.textColor = .white
        //     successLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        //     successLabel.frame = CGRect(x: 0, y: 0, width: 220, height: 44)
        //     successLabel.center = view.center
        //     successLabel.layer.cornerRadius = 10
        //     successLabel.layer.masksToBounds = true
        //     view.addSubview(successLabel)
        //     UIView.animate(withDuration: 0.25, animations: { successLabel.alpha = 1 }) { _ in
        //         UIView.animate(withDuration: 0.4, delay: 1.2, options: [], animations: { successLabel.alpha = 0 }) { _ in
        //             successLabel.removeFromSuperview()
        //         }
        //     }
        // } catch {
        //     let alert = UIAlertController(title: "Lỗi", message: "Không thể lưu ảnh: \(error.localizedDescription)", preferredStyle: .alert)
        //     alert.addAction(UIAlertAction(title: "OK", style: .default))
        //     present(alert, animated: true)
        // }
    }

    // Vẽ overlay (scaleAspectFill) lên TRÊN ảnh gốc với kích thước khớp ảnh
    private func compositeOverlayOnTop(base: UIImage, overlay: UIImage) -> UIImage {
        let canvasSize = base.size
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, base.scale)
        // vẽ ảnh gốc phủ toàn canvas
        base.draw(in: CGRect(origin: .zero, size: canvasSize))
        // tính rect cho overlay theo scaleAspectFill
        let bw = overlay.size.width
        let bh = overlay.size.height
        if bw > 0 && bh > 0 {
            let scale = max(canvasSize.width / bw, canvasSize.height / bh)
            let w = bw * scale
            let h = bh * scale
            let x = (canvasSize.width - w) / 2
            let y = (canvasSize.height - h) / 2
            overlay.draw(in: CGRect(x: x, y: y, width: w, height: h))
        }
        let out = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return out ?? base
    }
    
    // MARK: - Capture Preview Overlay

    private func showCapturePreview(for image: UIImage, filterType: FilterType?) {
        // Clear nếu đã có
        capturePreviewView?.removeFromSuperview()
        capturePreviewImageView = nil
        
        pendingCapturedImage = image
        pendingFilterType = filterType
        
        let overlay = UIView(frame: view.bounds)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.95)
        view.addSubview(overlay)
        capturePreviewView = overlay
        
        let imageView = UIImageView(frame: overlay.bounds)
        imageView.contentMode = .scaleAspectFit
        imageView.image = image
        imageView.isUserInteractionEnabled = true
        overlay.addSubview(imageView)
        capturePreviewImageView = imageView
        
        // Đặt background Noel lên TRÊN ảnh chụp trong màn preview nếu là xmasWarm
        if filterType == .xmasWarm {
            let topBg = UIImageView(frame: overlay.bounds)
            topBg.contentMode = .scaleAspectFill
            topBg.clipsToBounds = true
            topBg.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            topBg.image = UIImage(named: "background_xmas 1")
            overlay.addSubview(topBg)
        }
        
        // Stack nút
        let buttonHeight: CGFloat = 48
        let buttonWidth: CGFloat = 120
        let spacing: CGFloat = 20
        
        let saveBtn = UIButton(type: .system)
        saveBtn.setTitle("Lưu", for: .normal)
        saveBtn.setTitleColor(.white, for: .normal)
        saveBtn.backgroundColor = UIColor.systemBlue
        saveBtn.layer.cornerRadius = 12
        saveBtn.frame = CGRect(x: view.bounds.midX - buttonWidth - spacing / 2,
                               y: view.bounds.height - buttonHeight - 40,
                               width: buttonWidth, height: buttonHeight)
        saveBtn.addTarget(self, action: #selector(onConfirmSaveTapped), for: .touchUpInside)
        overlay.addSubview(saveBtn)
        
        let cancelBtn = UIButton(type: .system)
        cancelBtn.setTitle("Hủy", for: .normal)
        cancelBtn.setTitleColor(.white, for: .normal)
        cancelBtn.backgroundColor = UIColor.systemRed
        cancelBtn.layer.cornerRadius = 12
        cancelBtn.frame = CGRect(x: view.bounds.midX + spacing / 2,
                                 y: view.bounds.height - buttonHeight - 40,
                                 width: buttonWidth, height: buttonHeight)
        cancelBtn.addTarget(self, action: #selector(onCancelPreviewTapped), for: .touchUpInside)
        overlay.addSubview(cancelBtn)
        
        // Animation
        overlay.alpha = 0
        UIView.animate(withDuration: 0.2) {
            overlay.alpha = 1
        }
    }
    
    @objc private func onCancelPreviewTapped() {
        UIView.animate(withDuration: 0.2, animations: {
            self.capturePreviewView?.alpha = 0
        }) { _ in
            self.capturePreviewImageView?.removeFromSuperview()
            self.capturePreviewView?.removeFromSuperview()
            self.capturePreviewImageView = nil
            self.capturePreviewView = nil
            self.pendingCapturedImage = nil
            self.pendingFilterType = nil
        }
    }
    
    @objc private func onConfirmSaveTapped() {
        guard let img = pendingCapturedImage else { return }
        let type = pendingFilterType
        onCancelPreviewTapped()
        saveImageToAppGallery(img, filterType: type)
    }
    
    private func imageFromPixelBuffer(_ pixelBuffer: CVPixelBuffer) -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let cg = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
    
    @objc private func handleWarpPan(_ g: UIPanGestureRecognizer) {
        guard let overlay = filterOverlay else { return }
        let point = g.location(in: overlay)
        switch g.state {
        case .began:
            let idx = 0
            activeWarps[idx] = (start: point, current: point, radius: 80, mode: "pinch")
        case .changed:
            let idx = 0
            if var w = activeWarps[idx] {
                w.current = point
                activeWarps[idx] = w
            }
        case .ended, .cancelled, .failed:
            let idx = 0
            if let w = activeWarps[idx] {
                let dx = w.current.x - w.start.x
                let dy = w.current.y - w.start.y
                // Độ nhạy cao hơn và có ngưỡng tối thiểu
                let dist = hypot(dx, dy)
                let scaleMag = min(0.6, max(0.12, dist / 80.0))
                committedWarpStamps.append(WarpStamp(center: w.current, radius: max(w.radius, 40), mode: w.mode, scale: scaleMag))
            }
            activeWarps.removeAll()
        default:
            break
        }
    }
    
    @objc private func handleWarpLongPress(_ g: UILongPressGestureRecognizer) {
        guard let overlay = filterOverlay else { return }
        let point = g.location(in: overlay)
        if g.state == .began {
            let idx = 0
            activeWarps[idx] = (start: point, current: point, radius: 100, mode: "bump")
        } else if g.state == .changed {
            let idx = 0
            if var w = activeWarps[idx] {
                w.current = point
                activeWarps[idx] = w
            }
        } else if g.state == .ended || g.state == .cancelled || g.state == .failed {
            let idx = 0
            if let w = activeWarps[idx] {
                let dx = w.current.x - w.start.x
                let dy = w.current.y - w.start.y
                let dist = hypot(dx, dy)
                
                
                let scaleMag = min(0.6, max(0.14, dist / 80.0))
                committedWarpStamps.append(WarpStamp(center: w.current, radius: max(w.radius, 40), mode: w.mode, scale: scaleMag))
            }
            activeWarps.removeAll()
        }
    }
    
    // Áp các warp đang có lên ảnh (overlay size)
    private func applyWarpTouches(on image: UIImage) -> UIImage? {
        guard let cg = image.cgImage else { return image }
        var ci = CIImage(cgImage: cg)
        let size = CGSize(width: cg.width, height: cg.height)
        
        // 1) Áp các warp đã commit (giữ nguyên sau khi thả tay)
        for stamp in committedWarpStamps {
            let center = CGPoint(x: stamp.center.x, y: size.height - stamp.center.y)
            if stamp.mode == "pinch" {
                if let pinch = CIFilter(name: "CIPinchDistortion") {
                    pinch.setValue(ci, forKey: kCIInputImageKey)
                    pinch.setValue(CIVector(x: center.x, y: center.y), forKey: kCIInputCenterKey)
                    pinch.setValue(max(stamp.radius, 40), forKey: kCIInputRadiusKey)
                    pinch.setValue(-stamp.scale, forKey: kCIInputScaleKey) // pinch là âm
                    ci = pinch.outputImage ?? ci
                }
            } else {
                if let bump = CIFilter(name: "CIBumpDistortion") {
                    bump.setValue(ci, forKey: kCIInputImageKey)
                    bump.setValue(CIVector(x: center.x, y: center.y), forKey: kCIInputCenterKey)
                    bump.setValue(max(stamp.radius, 40), forKey: kCIInputRadiusKey)
                    bump.setValue(stamp.scale, forKey: kCIInputScaleKey)
                    ci = bump.outputImage ?? ci
                }
            }
        }
        
        // 2) Áp các warp đang kéo (realtime)
        for (_, w) in activeWarps {
            let dx = w.current.x - w.start.x
            let dy = w.current.y - w.start.y
            let dist = hypot(dx, dy)
            let scaleMag = min(0.6, max(0.12, dist / 80.0)) // nhạy hơn + ngưỡng tối thiểu
            let center = CGPoint(x: w.current.x, y: size.height - w.current.y)
            if w.mode == "pinch" {
                if let pinch = CIFilter(name: "CIPinchDistortion") {
                    pinch.setValue(ci, forKey: kCIInputImageKey)
                    pinch.setValue(CIVector(x: center.x, y: center.y), forKey: kCIInputCenterKey)
                    pinch.setValue(max(w.radius, 40), forKey: kCIInputRadiusKey)
                    pinch.setValue(-scaleMag, forKey: kCIInputScaleKey)
                    ci = pinch.outputImage ?? ci
                }
            } else {
                if let bump = CIFilter(name: "CIBumpDistortion") {
                    bump.setValue(ci, forKey: kCIInputImageKey)
                    bump.setValue(CIVector(x: center.x, y: center.y), forKey: kCIInputCenterKey)
                    bump.setValue(max(w.radius, 40), forKey: kCIInputRadiusKey)
                    bump.setValue(scaleMag, forKey: kCIInputScaleKey)
                    ci = bump.outputImage ?? ci
                }
            }
        }
        let ctx = ciContext
        guard let out = ctx.createCGImage(ci, from: ci.extent) else { return image }
        return UIImage(cgImage: out, scale: image.scale, orientation: image.imageOrientation)
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil else {
            print("Error capturing photo: \(error?.localizedDescription ?? "Unknown error")")
            return
        }
        
        // Lấy dữ liệu hình ảnh
        guard let imageData = photo.fileDataRepresentation(),
              var capturedImage = UIImage(data: imageData)
        else {
            print("Could not create image from photo data")
            return
        }
        
        // Kiểm tra xem có đang sử dụng camera trước không
        let isFrontCamera = isFrontCameraActive()
        
        // Nếu đang sử dụng camera trước, cần lật ảnh theo chiều ngang để khớp với preview
        if isFrontCamera {
            print("📸 Mirroring front camera image for filter alignment")
            if let mirroredImage = mirrorImage(capturedImage) {
                capturedImage = mirroredImage
            }
        }
        
        // Xác định filter hiện tại
        let currentFilter = filterManager.currentFilter
        
        // Nếu có filter và landmarks, áp dụng filter động lên ảnh chụp
        if let landmarkerResult = faceMeshManager.detectFaceMesh(in: capturedImage),
           !landmarkerResult.faceLandmarks.isEmpty
        {
            if let type = currentFilter {
                switch type {
                case .beauty:
                    if let out = BeautyFilter().apply(to: capturedImage, smooth: beautySmooth, brighten: beautyBright) {
                        DispatchQueue.main.async { self.showCapturePreview(for: out, filterType: type) }
                        return
                    }
                case .xmasWarm:
                    if let out = XmasWarmFilter().apply(to: capturedImage) {
                        DispatchQueue.main.async { self.showCapturePreview(for: out, filterType: type) }
                        return
                    }
                case .funnyBigEyes:
                    if let out = BigEyesFilter().apply(to: capturedImage, landmarks: landmarkerResult) {
                        DispatchQueue.main.async { self.showCapturePreview(for: out, filterType: type) }
                        return
                    }
                case .funnyTinyNose:
                    if let out = TinyNoseFilter().apply(to: capturedImage, landmarks: landmarkerResult) {
                        DispatchQueue.main.async { self.showCapturePreview(for: out, filterType: type) }
                        return
                    }
                case .funnyWideMouth:
                    if let out = WideMouthFilter().apply(to: capturedImage, landmarks: landmarkerResult) {
                        DispatchQueue.main.async { self.showCapturePreview(for: out, filterType: type) }
                        return
                    }
                case .funnyPuffyCheeks:
                    if let out = PuffyCheeksFilter().apply(to: capturedImage, landmarks: landmarkerResult) {
                        DispatchQueue.main.async { self.showCapturePreview(for: out, filterType: type) }
                        return
                    }
                case .funnySwirl:
                    if let out = SwirlFaceFilter().apply(to: capturedImage, landmarks: landmarkerResult) {
                        DispatchQueue.main.async { self.showCapturePreview(for: out, filterType: type) }
                        return
                    }
                case .funnyLongChin:
                    if let out = LongChinFilter().apply(to: capturedImage, landmarks: landmarkerResult) {
                        DispatchQueue.main.async { self.showCapturePreview(for: out, filterType: type) }
                        return
                    }
                case .funnyMegaFace:
                    if let out = MegaFaceFilter().apply(to: capturedImage, landmarks: landmarkerResult) {
                        DispatchQueue.main.async { self.showCapturePreview(for: out, filterType: type) }
                        return
                    }
                case .funnyAlienHead:
                    if let out = AlienHeadFilter().apply(to: capturedImage, landmarks: landmarkerResult) {
                        DispatchQueue.main.async { self.showCapturePreview(for: out, filterType: type) }
                        return
                    }
                case .funnyWarp:
                    if let out = applyWarpTouches(on: capturedImage) {
                        DispatchQueue.main.async { self.showCapturePreview(for: out, filterType: type) }
                        return
                    }
                case .dogFace, .glasses, .mustache, .hat, .xmasSanta, .xmasBeard:
                    if let filteredImage = filterManager.applyDynamicFilter(
                        to: capturedImage,
                        with: landmarkerResult,
                        type: type,
                        isFrontCamera: false
                    ) {
                        DispatchQueue.main.async { self.showCapturePreview(for: filteredImage, filterType: type) }
                        return
                    }
                case .none:
                    break
                }
            }
        }
        
        // Không có filter hoặc không detect được khuôn mặt: dùng ảnh gốc
        print("ℹ️ No dynamic filter applied - showing preview with original image")
        DispatchQueue.main.async {
            self.showCapturePreview(for: capturedImage, filterType: currentFilter)
        }
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // Show error alert
            let alertController = UIAlertController(
                title: "Save Error",
                message: error.localizedDescription,
                preferredStyle: .alert
            )
            alertController.addAction(UIAlertAction(title: "OK", style: .default))
            present(alertController, animated: true)
        } else {
            // Show success animation
            let successLabel = UILabel()
            successLabel.text = "✅ Đã lưu ảnh"
            successLabel.textAlignment = .center
            successLabel.textColor = .white
            successLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
            successLabel.frame = CGRect(x: 0, y: 0, width: 200, height: 50)
            successLabel.center = view.center
            successLabel.layer.cornerRadius = 10
            successLabel.layer.masksToBounds = true
            
            view.addSubview(successLabel)
            
            // Fade out after 1.5 seconds
            UIView.animate(withDuration: 0.5, delay: 1.5, options: [], animations: {
                successLabel.alpha = 0
            }, completion: { _ in
                successLabel.removeFromSuperview()
            })
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Kiểm tra xem có đang xử lý frame không
        if isProcessingFrame {
            return
        }
        
        // Giới hạn tần suất xử lý frame để tiết kiệm tài nguyên
        let currentTime = CACurrentMediaTime()
        if currentTime - lastProcessedTimestamp < frameProcessInterval {
            return
        }
        
        lastProcessedTimestamp = currentTime
        isProcessingFrame = true
        
        // Đảm bảo filter overlay đã được tạo trên main thread
        DispatchQueue.main.async {
            if self.filterOverlay == nil {
                self.setupFilterOverlay()
            }
        }
        
        // Use autoreleasepool to better manage memory
        autoreleasepool { [weak self] in
            guard let self = self else {
                isProcessingFrame = false
                return
            }
            
            // Safely unwrap pixel buffer
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
                  CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly) == kCVReturnSuccess
            else {
                self.isProcessingFrame = false
                return
            }
            
            // Ensure we unlock the pixel buffer even if we exit early
            defer {
                CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
            }
            
            // Lấy kích thước frame
            let width = CVPixelBufferGetWidth(pixelBuffer)
            let height = CVPixelBufferGetHeight(pixelBuffer)
            let frameSize = CGSize(width: CGFloat(width), height: CGFloat(height))
            print("📏 Frame size: \(frameSize.width) x \(frameSize.height)")
            
            // Process on a background queue to avoid blocking camera feed
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                
                // Use autoreleasepool to release memory more quickly
                autoreleasepool {
                    // Phát hiện khuôn mặt và landmarks
                    print("🔍 Attempting face detection...")
                    
                    let startTime = CACurrentMediaTime()
                    // Sử dụng trực tiếp MediaPipeFaceMeshManager để phát hiện khuôn mặt từ pixelBuffer
                    if let landmarkerResult = self.faceMeshManager.detectFaceMesh(in: pixelBuffer) {
                        let endTime = CACurrentMediaTime()
                        print("⏱️ Face detection took \((endTime - startTime) * 1000) ms")
                        
                        if !landmarkerResult.faceLandmarks.isEmpty {
                            print("✅ Face detected with \(landmarkerResult.faceLandmarks.first?.count ?? 0) landmarks")
                            
                            // Chuẩn bị hình đã xử lý cho funny filters (nếu có)
                            var processedFunnyImage: UIImage? = nil
                            if let current = self.filterManager.currentFilter,
                               [.beauty, .funnyBigEyes, .funnyTinyNose, .funnyWideMouth, .funnyPuffyCheeks, .funnySwirl, .funnyLongChin, .funnyMegaFace, .funnyAlienHead, .funnyWarp, .xmasWarm].contains(current),
                               let baseImage = self.imageFromPixelBuffer(pixelBuffer)
                            {
                                switch current {
                                case .beauty:
                                    processedFunnyImage = BeautyFilter().apply(to: baseImage, smooth: self.beautySmooth, brighten: self.beautyBright)
                                case .funnyBigEyes:
                                    processedFunnyImage = BigEyesFilter().apply(to: baseImage, landmarks: landmarkerResult)
                                case .funnyTinyNose:
                                    processedFunnyImage = TinyNoseFilter().apply(to: baseImage, landmarks: landmarkerResult)
                                case .funnyWideMouth:
                                    processedFunnyImage = WideMouthFilter().apply(to: baseImage, landmarks: landmarkerResult)
                                case .funnyPuffyCheeks:
                                    processedFunnyImage = PuffyCheeksFilter().apply(to: baseImage, landmarks: landmarkerResult)
                                case .funnySwirl:
                                    processedFunnyImage = SwirlFaceFilter().apply(to: baseImage, landmarks: landmarkerResult)
                                case .funnyLongChin:
                                    processedFunnyImage = LongChinFilter().apply(to: baseImage, landmarks: landmarkerResult)
                                case .funnyMegaFace:
                                    processedFunnyImage = MegaFaceFilter().apply(to: baseImage, landmarks: landmarkerResult)
                                case .funnyAlienHead:
                                    processedFunnyImage = AlienHeadFilter().apply(to: baseImage, landmarks: landmarkerResult)
                                case .funnyWarp:
                                    processedFunnyImage = self.applyWarpTouches(on: baseImage)
                                case .xmasWarm:
                                    processedFunnyImage = XmasWarmFilter().apply(to: baseImage)
                                default:
                                    break
                                }
                            }
                            
                            // Cập nhật UI trên main thread
                            DispatchQueue.main.async { [weak self] in
                                guard let self = self, let filterOverlay = self.filterOverlay else { return }
                                
                                if let funnyImage = processedFunnyImage {
                                    if self.filterManager.currentFilter == .funnyAlienHead {
                                        // Đè overlay toàn màn hình cho AlienHead để không lộ lớp dưới
                                        self.videoPreviewLayer?.isHidden = true
                                        filterOverlay.transform = .identity
                                        filterOverlay.frame = self.previewView.bounds
                                        filterOverlay.contentMode = .scaleAspectFill
                                        filterOverlay.image = funnyImage
                                    } else {
                                        // Các funny khác: bù orientation/mirror theo preview layer và giữ preview
                                        self.videoPreviewLayer?.isHidden = false
                                        filterOverlay.frame = self.previewView.bounds
                                        filterOverlay.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                                        filterOverlay.center = self.previewView.center
                                        let conn = self.videoPreviewLayer?.connection
                                        let orientation = conn?.videoOrientation ?? .portrait
                                        let mirrored = conn?.isVideoMirrored ?? true
                                        var t = CGAffineTransform.identity
                                        switch orientation {
                                        case .portrait: t = .identity
                                        case .portraitUpsideDown: t = CGAffineTransform(rotationAngle: .pi)
                                        case .landscapeLeft: t = CGAffineTransform(rotationAngle: .pi / 2)
                                        case .landscapeRight: t = CGAffineTransform(rotationAngle: -.pi / 2)
                                        @unknown default: t = .identity
                                        }
                                        if mirrored { t = t.scaledBy(x: -1, y: 1) }
                                        filterOverlay.contentMode = .scaleAspectFill
                                        filterOverlay.transform = t
                                        filterOverlay.image = funnyImage
                                    }
                                } else {
                                    // Hiển thị overlay ảnh bình thường
                                    self.videoPreviewLayer?.isHidden = false
                                    print("🔁 Calling overlay update for: \(self.filterManager.currentFilter?.displayName ?? "nil") isFrontCam=\(self.isFrontCameraActive()) viewSize=\(self.previewView.bounds.size) frameSize=\(frameSize)")
                                    self.filterManager.updateFilterOverlayWithCorrectAspectRatio(
                                        filterOverlay,
                                        with: landmarkerResult,
                                        viewSize: self.previewView.bounds.size,
                                        frameSize: frameSize,
                                        isFrontCamera: self.isFrontCameraActive()
                                    )
                                    filterOverlay.transform = .identity // Reset transform khi trở về filter cũ
                                }
                                
                                // Đảm bảo filter overlay hiển thị trên cùng
                                self.previewView.bringSubviewToFront(filterOverlay)
                                // Và hiệu ứng Noel (tuyết/sparkles) nằm trên overlay
                                if let effectView = self.christmasEffectView {
                                    self.previewView.bringSubviewToFront(effectView)
                                }
                                // Và icon cố định nằm trên tất cả
                                if let iconsView = self.iconsOverlayView {
                                    self.previewView.bringSubviewToFront(iconsView)
                                }
                                // Và nút reset luôn nằm trên overlay
                                self.updateWarpResetButtonVisibility()
                                self.previewView.bringSubviewToFront(self.warpResetButton)
                            }
                        } else {
                            print("⚠️ No face landmarks found in this frame - KEEPING EXISTING FILTER")
                        }
                    } else {
                        print("❌ Failed to detect face in this frame - KEEPING EXISTING FILTER")
                    }
                    
                    // Reset processing flag
                    self.isProcessingFrame = false
                }
            }
        }
    }
}

// MARK: - Icons Overlay (xmasWarm)

extension CameraViewController {
    private func ensureIconsOverlayView() {
        if iconsOverlayView == nil {
            let v = UIView(frame: previewView.bounds)
            v.backgroundColor = .clear
            previewView.addSubview(v)
            iconsOverlayView = v
        }
    }
    
    private func updateXmasWarmIconVisibility() {
        ensureIconsOverlayView()
        guard let host = iconsOverlayView else { return }
        // Hiển thị icon khi filter là xmasWarm
        if filterManager.currentFilter == .xmasWarm {
            if xmasWarmIconView == nil {
                let iv = UIImageView()
                iv.contentMode = .scaleAspectFit
                iv.clipsToBounds = true
                iv.image = UIImage(named: "background_xmas 1")
                host.addSubview(iv)
                xmasWarmIconView = iv
            }
            // Cập nhật frame ngay
            if let iv = xmasWarmIconView, let img = iv.image {
                let margin: CGFloat = 8
                let maxWidth = previewView.bounds.width * 0.28
                let aspect = img.size.height / max(1, img.size.width)
                let width = maxWidth
                let height = width * aspect
                iv.frame = CGRect(x: margin, y: margin + view.safeAreaInsets.top, width: width, height: height)
                iv.isHidden = false
                previewView.bringSubviewToFront(host)
            }
        } else {
            xmasWarmIconView?.isHidden = true
        }
    }
    
    // MARK: - XmasWarm Background (full screen)

    private func ensureXmasWarmBackgroundView() {
        if xmasWarmBackgroundView == nil {
            let bg = UIImageView(frame: previewView.bounds)
            bg.contentMode = .scaleAspectFill
            bg.clipsToBounds = true
            bg.image = UIImage(named: "background_xmas 1")
            // chèn dưới icon và hiệu ứng, nhưng trên camera preview
            bg.layer.zPosition = 1
            previewView.addSubview(bg)
            xmasWarmBackgroundView = bg
        }
    }
    
    private func updateXmasWarmBackgroundVisibility() {
        ensureXmasWarmBackgroundView()
        guard let bg = xmasWarmBackgroundView else { return }
        if filterManager.currentFilter == .xmasWarm {
            bg.isHidden = false
            bg.frame = previewView.bounds
            // Đặt thứ tự: camera (layer) -> background (view) -> overlay (imageView) -> snow (view) -> icons (view)
            // Đưa background xuống dưới các overlay nhưng vẫn trên camera layer
            previewView.sendSubviewToBack(bg)
            if let overlay = filterOverlay {
                previewView.bringSubviewToFront(overlay)
            }
            if let effectView = christmasEffectView {
                previewView.bringSubviewToFront(effectView)
            }
            if let iconsView = iconsOverlayView {
                previewView.bringSubviewToFront(iconsView)
            }
            // Ẩn icon góc khi đã dùng background full-screen để tránh trùng lặp
            xmasWarmIconView?.isHidden = true
        } else {
            bg.isHidden = true
        }
    }
}
