import SwiftUI

struct OnboardingImageView: View {
    let imageName: String
    let size: CGSize
    
    var body: some View {
        // Nếu là system image, hiển thị từ SF Symbols
        if imageName.hasPrefix("system:") {
            let systemName = String(imageName.dropFirst(7))
            Image(systemName: systemName)
                .resizable()
                .scaledToFit()
                .frame(width: size.width, height: size.height)
                .foregroundColor(.white)
        }
        // Nếu không, hiển thị từ Assets
        else {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: size.width, height: size.height)
        }
    }
}

#Preview {
    ZStack {
        Color.blue
        VStack(spacing: 20) {
            OnboardingImageView(imageName: "system:camera.filters", size: CGSize(width: 100, height: 100))
            OnboardingImageView(imageName: "AppIcon", size: CGSize(width: 100, height: 100))
        }
    }
} 