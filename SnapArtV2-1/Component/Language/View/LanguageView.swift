import SwiftUI

struct LanguageView: View {
    @EnvironmentObject private var viewModel: LanguageViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var pendingCode: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    Header
                    
                    // Language List
                    scrollView
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .id(viewModel.refreshID) // Force reload toàn bộ view khi refreshID thay đổi
        .onAppear {
            pendingCode = viewModel.selectedCode
        }
    }
    
    var Header: some View {
        VStack(spacing: 16) {
            HStack {
                Text(NSLocalizedString("Ngôn ngữ", comment: "Language"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .id(viewModel.refreshID) // Force reload khi refreshID thay đổi
                    .padding(.leading, 100)
                
                Spacer()
                
                Button(NSLocalizedString("OK", comment: "OK")) {
                    // Áp dụng ngôn ngữ khi nhấn OK (UIKit bundle override)
                    if !pendingCode.isEmpty { viewModel.selectedCode = pendingCode }
                    viewModel.applyLanguage()
                    NotificationCenter.default.post(name: .languageChanged, object: nil)
                    dismiss()
                }
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
                .id(viewModel.refreshID)
            }
     
            Text(NSLocalizedString("Chọn ngôn ngữ cho ứng dụng", comment: "Choose language for app"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .id(viewModel.refreshID) // Force reload khi refreshID thay đổi
        }
        .padding(.top, 20)
        .padding(.horizontal, 20)
    }
    
    var scrollView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.languages) { language in
                    LanguageRowView(
                        language: language,
                        isSelected: pendingCode == language.code
                    ) {
                        pendingCode = language.code
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
}

struct LanguageRowView: View {
    let language: Language
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Hiệu ứng haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            // Thực hiện action
            onTap()
        }) {
            HStack(spacing: 16) {
                // Flag ở góc trái ngoài cùng
                Text(language.flag)
                    .font(.system(size: 32))
                    .frame(width: 40)
                
                // Thông tin ngôn ngữ
                VStack(alignment: .leading, spacing: 4) {
                    // Tên ngôn ngữ
                    Text(language.name)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)
                    
                    // Tên quốc gia hoặc "selected language"
                    Text(isSelected ? NSLocalizedString("Đã chọn", comment: "Selected") : language.englishName)
                        .font(.subheadline)
                        .foregroundColor(isSelected ? .blue : .secondary)
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Radio button ở góc phải
                Circle()
                    .stroke(isSelected ? Color.blue : Color.gray, lineWidth: 2)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .fill(isSelected ? Color.blue : Color.clear)
                            .frame(width: 12, height: 12)
                    )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

#Preview {
    LanguageView()
        .environmentObject(LanguageViewModel())
}
