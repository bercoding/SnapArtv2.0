import SwiftUI
import Combine

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingAlert = false
    @EnvironmentObject private var languageViewModel: LanguageViewModel
    
    var body: some View {
        ZStack {
            AppTheme.mainGradient.ignoresSafeArea()
            VStack(spacing: 20) {
                // Header
                Text(NSLocalizedString("Đăng ký tài khoản mới", comment: "Create new account"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 20)
                    .id(languageViewModel.refreshID)
                
                Text(NSLocalizedString("Tạo tài khoản để bắt đầu sử dụng SnapArt", comment: "Create account to start using SnapArt"))
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .id(languageViewModel.refreshID)

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
                        iconName: "lock.fill",
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
                        Text(NSLocalizedString("Đăng ký", comment: "Sign Up"))
                            .font(.headline)
                            .foregroundColor(.white)
                            .id(languageViewModel.refreshID)
                    }
                }
                .buttonStyle(AppTheme.primaryButtonStyle())
                .padding(.horizontal, 30)
                .disabled(authViewModel.isLoading)

                HStack {
                    Text(NSLocalizedString("Đã có tài khoản?", comment: "Already have an account?"))
                        .foregroundColor(.white.opacity(0.8))
                        .id(languageViewModel.refreshID)
                    Button(NSLocalizedString("Đăng nhập", comment: "Sign In")) {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.secondaryColor)
                    .id(languageViewModel.refreshID)
                }
                .padding(.vertical)
            }
        }
        .alert(NSLocalizedString("Lỗi", comment: "Error"), isPresented: $showingAlert) {
            Button(NSLocalizedString("OK", comment: "OK")) { }
        } message: {
            Text(authViewModel.errorMessage ?? NSLocalizedString("Đã xảy ra lỗi không xác định.", comment: "An unknown error occurred"))
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
        .id(languageViewModel.refreshID)
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
            .environmentObject(AuthViewModel.example)
            .environmentObject(LanguageViewModel())
    }
} 
