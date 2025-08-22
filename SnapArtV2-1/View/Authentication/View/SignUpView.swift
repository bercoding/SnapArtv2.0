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
                Text(String(localized: "Đăng ký tài khoản mới"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 20)
                    .id(languageViewModel.refreshID)
                
                Text(String(localized: "Tạo tài khoản để bắt đầu sử dụng SnapArt"))
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
                        Text(String(localized: "Đăng ký"))
                            .font(.headline)
                            .foregroundColor(.white)
                            .id(languageViewModel.refreshID)
                    }
                }
                .buttonStyle(AppTheme.primaryButtonStyle())
                .padding(.horizontal, 30)
                .disabled(authViewModel.isLoading)

                HStack {
                    Text(String(localized: "Đã có tài khoản?"))
                        .foregroundColor(.white.opacity(0.8))
                        .id(languageViewModel.refreshID)
                    Button(String(localized: "Đăng nhập")) {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.secondaryColor)
                    .id(languageViewModel.refreshID)
                }
                .padding(.vertical)
            }
        }
        .alert(String(localized: "Lỗi"), isPresented: $showingAlert) {
            Button(String(localized: "OK")) { }
        } message: {
            Text(authViewModel.errorMessage ?? String(localized: "Đã xảy ra lỗi không xác định."))
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
