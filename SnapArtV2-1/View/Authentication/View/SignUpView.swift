import SwiftUI
import Combine

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingAlert = false

    var body: some View {
        ZStack {
            AppTheme.mainGradient.ignoresSafeArea()
            VStack(spacing: 20) {
                // Header
                Text("Đăng ký tài khoản mới")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 20)

                Text("Tạo tài khoản để bắt đầu sử dụng SnapArt")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()

                // Signup Form
                VStack(spacing: 20) {
                    AuthTextFieldView(
                        iconName: "envelope.fill",
                        placeholder: "Email",
                        text: $authViewModel.email
                    )
                    .autocapitalization(.none)

                    AuthTextFieldView(
                        iconName: "lock.fill",
                        placeholder: "Mật khẩu",
                        text: $authViewModel.password,
                        isSecure: true
                    )

                    AuthTextFieldView(
                        iconName: "lock.fill", // Changed from lock.shield to lock.fill for consistency
                        placeholder: "Xác nhận mật khẩu",
                        text: $authViewModel.confirmPassword,
                        isSecure: true
                    )
                }
                .padding(.horizontal, 30)

                Spacer()

                // Signup Button
                Button(action: {
                    authViewModel.signUp()
                }) {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Đăng ký")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(AppTheme.primaryButtonStyle()) // Sửa lỗi ở đây
                .padding(.horizontal, 30)
                .disabled(authViewModel.isLoading)

                HStack {
                    Text("Đã có tài khoản?")
                        .foregroundColor(.white.opacity(0.8))
                    Button("Đăng nhập") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.secondaryColor)
                }
                .padding(.vertical)
            }
        }
        .alert("Lỗi", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(authViewModel.errorMessage ?? "Đã xảy ra lỗi không xác định.")
        }
        .onReceive(authViewModel.$errorMessage) { errorMessage in
            if errorMessage != nil {
                showingAlert = true
            }
        }
        .onReceive(authViewModel.$authState) { state in
            if state == .signedIn {
                dismiss()
            }
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
            .environmentObject(AuthViewModel.example)
    }
} 
