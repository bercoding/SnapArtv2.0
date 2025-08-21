import UIKit
import MediaPipeTasksVision
// import SnapArtV2_1 // Removed as it's part of the same module

class MediaPipeTestViewController: UIViewController {
    
    // UI Elements
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let selectImageButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Chọn ảnh", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let showLandmarksButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Hiển thị landmarks", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let saveImageButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Lưu vào Gallery", for: .normal)
        button.backgroundColor = .systemPurple
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let errorLabel: UILabel = {
        let label = UILabel()
        label.textColor = .red
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let restartButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Khởi động lại", for: .normal)
        button.backgroundColor = .systemOrange
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.isHidden = true
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let filtersCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 70, height: 70)
        layout.minimumLineSpacing = 10
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    private let imagePicker = UIImagePickerController()
    private var selectedImage: UIImage?
    private var showingLandmarks = false
    private var faceLandmarkerResult: FaceLandmarkerResult?
    
    // Mediapipe tester
    private let mediapipeTester = MediaPipeTester()
    private var currentFilter: FilterType? = nil
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupImagePicker()
        setupCollectionView()
        
        selectImageButton.addTarget(self, action: #selector(selectImageTapped), for: .touchUpInside)
        showLandmarksButton.addTarget(self, action: #selector(showLandmarksTapped), for: .touchUpInside)
        restartButton.addTarget(self, action: #selector(restartMediaPipeTapped), for: .touchUpInside)
        saveImageButton.addTarget(self, action: #selector(saveImageTapped), for: .touchUpInside)
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        view.backgroundColor = .white
        title = "MediaPipe Face Mesh Test"
        
        view.addSubview(imageView)
        view.addSubview(selectImageButton)
        view.addSubview(showLandmarksButton)
        view.addSubview(errorLabel)
        view.addSubview(restartButton)
        view.addSubview(filtersCollectionView)
        view.addSubview(saveImageButton)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.6),
            
            selectImageButton.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 10),
            selectImageButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            selectImageButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.45),
            
            showLandmarksButton.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 10),
            showLandmarksButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            showLandmarksButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.45),
            
            errorLabel.topAnchor.constraint(equalTo: selectImageButton.bottomAnchor, constant: 10),
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            restartButton.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 10),
            restartButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            restartButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6),
            
            saveImageButton.topAnchor.constraint(equalTo: restartButton.bottomAnchor, constant: 10),
            saveImageButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            saveImageButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6),
            saveImageButton.heightAnchor.constraint(equalToConstant: 44),
            
            filtersCollectionView.topAnchor.constraint(equalTo: saveImageButton.bottomAnchor, constant: 10),
            filtersCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            filtersCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            filtersCollectionView.heightAnchor.constraint(equalToConstant: 80),
            filtersCollectionView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        ])
        
        // Kiểm tra trạng thái MediaPipe
        let mediaStatus = MediaPipeFaceMeshManager.shared.checkStatus()
        if !mediaStatus {
            errorLabel.isHidden = false
            errorLabel.textColor = .red
            errorLabel.text = "Lỗi: MediaPipe FaceMesh chưa được khởi tạo đúng cách!"
            restartButton.isHidden = false
        } else {
            errorLabel.isHidden = true
            restartButton.isHidden = true
        }
    }
    
    private func setupImagePicker() {
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .photoLibrary
    }
    
    private func setupCollectionView() {
        filtersCollectionView.delegate = self
        filtersCollectionView.dataSource = self
        filtersCollectionView.register(FilterCollectionViewCell.self, forCellWithReuseIdentifier: FilterCollectionViewCell.identifier)
    }
    
    // MARK: - Action Methods
    
    @objc private func selectImageTapped() {
        present(imagePicker, animated: true)
    }
    
    @objc private func showLandmarksTapped() {
        guard let image = selectedImage else {
            showError(message: "Vui lòng chọn ảnh trước!")
            return
        }
        
        // Reset error display
        hideError()
        
        // Toggle landmarks state
        showingLandmarks = !showingLandmarks
        
        if showingLandmarks {
            // Phát hiện khuôn mặt nếu chưa có
            if faceLandmarkerResult == nil {
                faceLandmarkerResult = detectFaceMesh(in: image)
            }
            
            // Hiển thị thông tin và vẽ landmark
            if faceLandmarkerResult != nil {
                // Hiển thị thông tin chi tiết landmark
                errorLabel.isHidden = false
                errorLabel.textColor = .blue
                errorLabel.text = mediapipeTester.printKeyLandmarkInfo(result: faceLandmarkerResult!)
                
                // Vẽ landmark lên ảnh
                if let landmarkImage = mediapipeTester.drawDebugLandmarks(on: image, result: faceLandmarkerResult!) {
                    imageView.image = landmarkImage
                }
                
                showLandmarksButton.setTitle("Ẩn landmarks", for: .normal)
            } else {
                errorLabel.isHidden = false
                errorLabel.textColor = .orange
                errorLabel.text = "Không phát hiện được khuôn mặt trong ảnh!"
                showLandmarksButton.setTitle("Thử lại", for: .normal)
            }
        } else {
            // Apply filter to the image
            applySelectedFilter()
            hideError()
            showLandmarksButton.setTitle("Hiển thị landmarks", for: .normal)
        }
    }
    
    @objc private func restartMediaPipeTapped() {
        // Khởi động lại MediaPipe FaceMesh
        MediaPipeFaceMeshManager.shared.restartFaceLandmarker()
        
        // Hiển thị thông báo đang khởi động lại
        errorLabel.isHidden = false
        errorLabel.textColor = .blue
        errorLabel.text = "Đang khởi động lại MediaPipe FaceMesh..."
        
        // Đợi một chút để MediaPipe khởi tạo
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            
            // Kiểm tra lại trạng thái MediaPipe
            let mediaStatus = MediaPipeFaceMeshManager.shared.checkStatus()
            if !mediaStatus {
                self.errorLabel.textColor = .red
                self.errorLabel.text = "Không thể khởi động MediaPipe FaceMesh. Vui lòng thử lại!"
                self.restartButton.isHidden = false
            } else {
                self.errorLabel.textColor = .green
                self.errorLabel.text = "Đã khởi động lại MediaPipe FaceMesh thành công!"
                self.restartButton.isHidden = true
                
                // Nếu đã có ảnh, thử phát hiện khuôn mặt lại
                if let image = self.selectedImage {
                    self.faceLandmarkerResult = self.detectFaceMesh(in: image)
                    self.applySelectedFilter()
                }
                
                // Tự động ẩn thông báo sau một thời gian
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.hideError()
                }
            }
        }
    }
    
    @objc private func saveImageTapped() {
        guard let imageToSave = imageView.image else {
            showTransientToast("⚠️ Không có ảnh để lưu")
            return
        }
        var metadata: Data? = nil
        if let filter = currentFilter {
            let dict: [String: Any] = ["filterType": filter.displayName]
            metadata = try? JSONSerialization.data(withJSONObject: dict)
        }
        if let data = imageToSave.jpegData(compressionQuality: 0.9) {
            do {
                _ = try CoreDataManager.shared.saveSavedImage(imageData: data, id: UUID(), createdAt: Date(), metadata: metadata) // Added id and createdAt
                showTransientToast("✅ Đã lưu vào Gallery")
            } catch {
                showTransientToast("❌ Lưu thất bại: \(error.localizedDescription)")
            }
        } else {
            showTransientToast("❌ Không thể chuyển ảnh thành dữ liệu")
        }
    }
    
    private func showTransientToast(_ message: String) {
        let toast = UILabel()
        toast.text = message
        toast.textAlignment = .center
        toast.textColor = .white
        toast.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        toast.layer.cornerRadius = 10
        toast.layer.masksToBounds = true
        toast.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toast)
        
        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            toast.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.8)
        ])
        
        toast.alpha = 0
        UIView.animate(withDuration: 0.2, animations: { toast.alpha = 1 }) { _ in
            UIView.animate(withDuration: 0.3, delay: 1.2, options: [], animations: { toast.alpha = 0 }) { _ in
                toast.removeFromSuperview()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func showError(message: String) {
        errorLabel.text = message
        errorLabel.textColor = .red
        errorLabel.isHidden = false
    }
    
    private func hideError() {
        errorLabel.isHidden = true
    }
    
    private func applySelectedFilter() {
        guard let image = selectedImage else { return }
        
        do {
            // Kiểm tra kích thước hình ảnh
            if image.size.width <= 0 || image.size.height <= 0 {
                throw NSError(domain: "MediaPipeTest", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "Invalid image size: \(image.size)"
                ])
            }
            
            if let currentFilter = SnapArtV2_1.FilterManager.shared.currentFilter {
                // Nếu chưa phát hiện khuôn mặt, thử phát hiện
                if faceLandmarkerResult == nil {
                    faceLandmarkerResult = detectFaceMesh(in: image)
                }
                
                // Sử dụng filter với landmarks nếu có
                if let filteredImage = MediaPipeFaceMeshManager.shared.applyFilter(
                    on: image, 
                    landmarks: faceLandmarkerResult!,
                    filterType: currentFilter
                ) {
                    imageView.image = filteredImage
                } else {
                    // Nếu không thể áp dụng filter, hiển thị ảnh gốc
                    imageView.image = image
                    
                    // Hiển thị thông báo
                    errorLabel.isHidden = false
                    errorLabel.textColor = .orange
                    errorLabel.text = "Không thể áp dụng filter cho ảnh này"
                }
            } else {
                // Hiển thị ảnh gốc
                imageView.image = image
            }
        } catch {
            // Xử lý lỗi
            print("❌ Error applying filter: \(error.localizedDescription)")
            
            // Hiển thị ảnh gốc
            imageView.image = image
            
            // Hiển thị thông báo lỗi
            errorLabel.isHidden = false
            errorLabel.textColor = .red
            errorLabel.text = "Lỗi: \(error.localizedDescription)"
        }
    }
    
    // Helper method để phát hiện khuôn mặt
    private func detectFaceMesh(in image: UIImage) -> FaceLandmarkerResult? {
        return MediaPipeFaceMeshManager.shared.detectFaceMesh(in: image)
    }
    
    // Helper method để vẽ landmark
    private func drawLandmarks(on image: UIImage) -> UIImage? {
        guard let faceLandmarkerResult = self.faceLandmarkerResult else {
            return image
        }
        return mediapipeTester.drawDebugLandmarks(on: image, result: faceLandmarkerResult)
    }
}

// MARK: - UIImagePickerControllerDelegate

extension MediaPipeTestViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
            // Lưu ảnh đã chọn
            selectedImage = image
            imageView.image = image
            
            // Reset các trạng thái
            showingLandmarks = false
            showLandmarksButton.setTitle("Hiển thị landmarks", for: .normal)
            hideError()
            
            // Phát hiện khuôn mặt mới
            faceLandmarkerResult = detectFaceMesh(in: image)
            
            // Áp dụng filter nếu cần
            applySelectedFilter()
            
            // Hiển thị trạng thái phát hiện
            if faceLandmarkerResult != nil {
                errorLabel.isHidden = false
                errorLabel.textColor = .blue
                errorLabel.text = "Đã phát hiện khuôn mặt trong ảnh!"
            } else {
                errorLabel.isHidden = false
                errorLabel.textColor = .orange
                errorLabel.text = "Không phát hiện được khuôn mặt trong ảnh!"
            }
        }
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource

extension MediaPipeTestViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return SnapArtV2_1.FilterManager.shared.getAllFilters().count + 1 // +1 for "No filter" option
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FilterCollectionViewCell.identifier, for: indexPath) as? FilterCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        if indexPath.item == 0 {
            // First cell is "No filter"
            cell.configure(with: CustomFilter.none)
            cell.isSelected = currentFilter == nil
        } else {
            // Other cells are actual filters
            let filters = SnapArtV2_1.FilterManager.shared.getAllFilters()
            let filterIndex = indexPath.item - 1
            
            if filterIndex < filters.count {
                let filter = filters[filterIndex]
                cell.configure(with: filter)
                cell.isSelected = currentFilter == filter
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == 0 {
            // Select "No filter"
            SnapArtV2_1.FilterManager.shared.setFilter(nil)
            currentFilter = nil
        } else {
            // Select a filter
            let filters = SnapArtV2_1.FilterManager.shared.getAllFilters()
            let filterIndex = indexPath.item - 1
            
            if filterIndex < filters.count {
                let filter = filters[filterIndex]
                SnapArtV2_1.FilterManager.shared.setFilter(filter)
                currentFilter = filter
            }
        }
        
        // Apply selected filter
        applySelectedFilter()
        
        // Update UI
        collectionView.reloadData()
    }
}

// Enum for "No filter" cell
enum CustomFilter {
    case none
    
    var displayName: String {
        return "Không filter"
    }
    
    var icon: String {
        return "❌"
    }
} 
