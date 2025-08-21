import SwiftUI

struct AuthButtonView: View {
    let title: String
    let action: () -> Void
    let isLoading: Bool
    let backgroundColor: Color
    
    init(title: String, action: @escaping () -> Void, isLoading: Bool = false, backgroundColor: Color = .blue) {
        self.title = title
        self.action = action
        self.isLoading = isLoading
        self.backgroundColor = backgroundColor
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(title)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .background(backgroundColor)
            .cornerRadius(10)
            .padding(.horizontal)
        }
        .disabled(isLoading)
    }
} 