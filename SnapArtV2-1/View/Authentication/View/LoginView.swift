import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss // Use @Environment(\.dismiss) for SwiftUI 2.0+
    @State private var showingAlert = false // Local state for showing alert
    @EnvironmentObject private var languageViewModel: LanguageViewModel
    
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
                    
                    Text(NSLocalizedString("SnapArt", comment: "App name"))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .id(languageViewModel.refreshID)
                    
                    Text(NSLocalizedString("Đăng nhập để tiếp tục", comment: "Sign in to continue"))
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                        .id(languageViewModel.refreshID)
                }
                .padding(.top, 20)
                
                // Login Form
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
                }
                .padding(.horizontal, 30)
                
                // Forgot Password
                Button(NSLocalizedString("Quên mật khẩu?", comment: "Forgot password?")) {
                    // Handle forgot password
                }
                .font(.footnote)
                .foregroundColor(.white.opacity(0.8))
                .padding(.bottom, 10)
                .id(languageViewModel.refreshID)
                
                // Test account button
                Button(NSLocalizedString("Dùng tài khoản demo", comment: "Use demo account")) {
                    authViewModel.email = "test@example.com"
                    authViewModel.password = "password123"
                    authViewModel.signIn()
                }
                .font(.footnote)
                .foregroundColor(.white.opacity(0.6))
                .padding(.bottom, 20)
                .id(languageViewModel.refreshID)
                
                Button(action: {
                    authViewModel.signIn()
                }) {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(NSLocalizedString("Đăng nhập", comment: "Sign In"))
                            .font(.headline)
                            .foregroundColor(.white)
                            .id(languageViewModel.refreshID)
                    }
                }
                .buttonStyle(AppTheme.primaryButtonStyle())
                .padding(.horizontal, 30)
                .disabled(authViewModel.isLoading)
                
                HStack {
                    Text(NSLocalizedString("Chưa có tài khoản?", comment: "Don't have an account?"))
                        .foregroundColor(.white.opacity(0.8))
                        .id(languageViewModel.refreshID)
                    NavigationLink(NSLocalizedString("Đăng ký", comment: "Sign Up")) {
                        SignUpView()
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
        .withBannerAd(adUnitId: "ca-app-pub-3940256099942544/2934735716")
        
    }
    
    struct LoginView_Previews: PreviewProvider {
        static var previews: some View {
            LoginView()
                .environmentObject(AuthViewModel.example)
                .environmentObject(LanguageViewModel())
        }
    }
}
