import SwiftUI

struct MediaPipeTestButton: View {
    var body: some View {
        Button(action: {
            // Hiển thị màn hình test
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController
            {
                let testVC = MediaPipeTestViewController()
                let navVC = UINavigationController(rootViewController: testVC)
                rootViewController.present(navVC, animated: true)
            }
        }) {
            HStack {
                Image(systemName: "faceid")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .foregroundColor(.white)

                Text("Kiểm tra MediaPipe")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.blue)
            .cornerRadius(8)
        }
    }
}

// Wrapper SwiftUI cho MediaPipeTestViewController
struct MediaPipeTestViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> MediaPipeTestViewController {
        return MediaPipeTestViewController()
    }

    func updateUIViewController(_ uiViewController: MediaPipeTestViewController, context: Context) {
    }
}

// View SwiftUI để sử dụng trong NavigationLink
var mediaTestView: some View {
    MediaPipeTestViewControllerWrapper()
        .edgesIgnoringSafeArea(.all)
        .navigationBarTitle("MediaPipe Test", displayMode: .inline)
}
