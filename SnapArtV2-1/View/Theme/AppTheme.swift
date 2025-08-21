import SwiftUI

/// Quản lý theme của ứng dụng, bao gồm màu sắc, gradient và các kiểu dáng chung
struct AppTheme {
    // MARK: - Màu sắc chính
    
    /// Màu chủ đạo của ứng dụng
    static let primaryColor = Color.blue
    
    /// Màu phụ của ứng dụng
    static let secondaryColor = Color.purple
    
    /// Màu nền của ứng dụng
    static let backgroundColor = Color(UIColor.systemBackground)
    
    /// Màu chữ chính
    static let textColor = Color.primary
    
    /// Màu chữ phụ
    static let secondaryTextColor = Color.secondary
    
    // MARK: - Gradients
    
    /// Gradient chính cho màn hình splash và onboarding
    static let mainGradient = LinearGradient(
        gradient: Gradient(colors: [
            primaryColor.opacity(0.6),
            secondaryColor.opacity(0.4)
        ]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// Gradient tối cho các nút
    static let buttonGradient = LinearGradient(
        gradient: Gradient(colors: [
            primaryColor,
            primaryColor.opacity(0.8)
        ]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // MARK: - Kiểu dáng chung
    
    /// Kiểu dáng cho nút chính
    static func primaryButtonStyle() -> some ButtonStyle {
        return PrimaryButtonStyle()
    }
    
    /// Kiểu dáng cho nút phụ
    static func secondaryButtonStyle() -> some ButtonStyle {
        return SecondaryButtonStyle()
    }
    
    /// Kiểu dáng cho nút văn bản
    static func textButtonStyle() -> some ButtonStyle {
        return TextButtonStyle()
    }
}

// MARK: - Button Styles

/// Kiểu dáng cho nút chính
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppTheme.buttonGradient)
            .cornerRadius(12)
            .padding(.horizontal, 24)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

/// Kiểu dáng cho nút phụ
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(AppTheme.primaryColor)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white.opacity(0.2))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.primaryColor, lineWidth: 1)
            )
            .padding(.horizontal, 24)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

/// Kiểu dáng cho nút văn bản
struct TextButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .foregroundColor(.white)
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
} 