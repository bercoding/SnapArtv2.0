//import SwiftUI
//import AVFoundation
//
//struct CameraView: UIViewControllerRepresentable {
//    @State private var cameraPermissionGranted: Bool = false
//    @State private var showCamera = false
//    
//    func makeUIViewController(context: Context) -> CameraViewController {
//        // Kiểm tra quyền trước khi tạo view controller
//        checkCameraPermission()
//        return CameraViewController()
//    }
//    
//    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
//        // Updates can be handled here if needed
//    }
//    
//    private func checkCameraPermission() {
//        let status = AVCaptureDevice.authorizationStatus(for: .video)
//        if status == .notDetermined {
//            r
//            AVCaptureDevice.requestAccess(for: .video) { granted in
//                self.cameraPermissionGranted = granted
//            }
//        } else {
//            cameraPermissionGranted = (status == .authorized)
//        }
//    }
//    
//}
//
//
////// Preview
////struct CameraView_Previews: PreviewProvider {
////    static var previews: some View {
////        Text("Camera Preview")
////            .padding()
////            .background(Color.gray.opacity(0.2))
////            .cornerRadius(10)
////    }
//    
//}
