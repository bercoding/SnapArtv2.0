import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss // Use @Environment(\.dismiss) for SwiftUI 2.0+
    @State private var showingAlert = false // Local state for showing alert
    
    var body: some View {
        ZStack {
            AppTheme.mainGradient.ignoresSafeArea()
            VStack(spacing: 20) {
                // Logo and Header
                VStack(spacing: 10) {
                    Image(systemName: "camera.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.white)
                    
                    Text("SnapArt")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Đăng nhập để tiếp tục")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.top, 20)

                Spacer()

                // Login Form
                VStack(spacing: 20) {
                    AuthTextFieldView(
                        iconName: "envelope.fill", // Sửa tên tham số
                        placeholder: "Email",
                        text: $authViewModel.email // Bind to AuthViewModel.email
                    )
                    .autocapitalization(.none)
                    
                    AuthTextFieldView(
                        iconName: "lock.fill", // Sửa tên tham số
                        placeholder: "Mật khẩu",
                        text: $authViewModel.password, // Bind to AuthViewModel.password
                        isSecure: true
                    )
                }
                .padding(.horizontal, 30)

                // Forgot Password
                Button("Quên mật khẩu?") {
                    // Handle forgot password
                }
                .font(.footnote)
                .foregroundColor(.white.opacity(0.8))
                .padding(.bottom, 10)

                // Test account button
                Button("Dùng tài khoản demo") {
                    authViewModel.email = "test@example.com"
                    authViewModel.password = "password123"
                    authViewModel.signIn()
                }
                .font(.footnote)
                .foregroundColor(.white.opacity(0.6))
                .padding(.bottom, 20)

                Button(action: {
                    authViewModel.signIn()
                }) {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Đăng nhập")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(AppTheme.primaryButtonStyle()) // Sửa lỗi ở đây
                .padding(.horizontal, 30)
                .disabled(authViewModel.isLoading)

                HStack {
                    Text("Chưa có tài khoản?")
                        .foregroundColor(.white.opacity(0.8))
                    NavigationLink("Đăng ký") {
                        SignUpView()
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

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthViewModel.example)
    }
} 
