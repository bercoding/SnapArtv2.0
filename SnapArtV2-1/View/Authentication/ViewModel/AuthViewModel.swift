import Foundation
import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    @Published var user: UserModel?
    @Published var authState: AuthState = .loading
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var errorMessage: String? = nil
    @Published var isLoading: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        print("AuthViewModel init - Bắt đầu khởi tạo")
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        print("setupAuthStateListener - Thiết lập listener Auth state")
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                print("Auth state changed - user: \(user != nil ? "logged in" : "nil")")
                if let user = user {
                    print("User đã đăng nhập: \(user.email ?? "unknown email")")
                    self?.user = UserModel(user: user)
                    self?.authState = .signedIn
                    print("AuthState => .signedIn")
                } else {
                    print("Không có user đăng nhập")
                    self?.user = nil
                    self?.authState = .signedOut
                    print("AuthState => .signedOut")
                }
            }
        }
    }
    
    // MARK: - Authentication Methods
    
    func signIn() {
        isLoading = true
        errorMessage = nil
        
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Vui lòng nhập email và mật khẩu."
            isLoading = false
            return
        }
        
        print("signIn - Bắt đầu đăng nhập với email: \(email)")
        authState = .loading
        print("AuthState => .loading")
        
        FirebaseManager.shared.signIn(email: email, password: password) { [weak self] result in
            print("FirebaseManager.signIn callback received")
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                switch result {
                case .success(let userModel):
                    print("Đăng nhập thành công: \(userModel.email)")
                    self.user = userModel
                    self.authState = .signedIn
                    print("AuthState => .signedIn")
                    self.errorMessage = nil // Clear error message on success
                    NotificationCenter.default.post(name: .userDidSignIn, object: nil)
                case .failure(let error):
                    print("Đăng nhập thất bại: \(error.localizedDescription)")
                    self.authState = .signedOut
                    print("AuthState => .signedOut")
                    self.errorMessage = error.localizedDescription // Set error message on failure
                }
            }
        }
    }
    
    func signUp() {
        isLoading = true
        errorMessage = nil
        
        guard !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            errorMessage = "Vui lòng nhập đầy đủ email, mật khẩu và xác nhận mật khẩu."
            isLoading = false
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "Mật khẩu xác nhận không khớp."
            isLoading = false
            return
        }
        
        print("signUp - Bắt đầu đăng ký với email: \(email)")
        authState = .loading
        print("AuthState => .loading")
        
        FirebaseManager.shared.signUp(email: email, password: password) { [weak self] result in
            print("FirebaseManager.signUp callback received")
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                switch result {
                case .success(let userModel):
                    print("Đăng ký thành công: \(userModel.email)")
                    self.user = userModel
                    self.authState = .signedIn
                    print("AuthState => .signedIn")
                    self.errorMessage = nil // Clear error message on success
                    NotificationCenter.default.post(name: .userDidSignIn, object: nil)
                case .failure(let error):
                    print("Đăng ký thất bại: \(error.localizedDescription)")
                    self.authState = .signedOut
                    print("AuthState => .signedOut")
                    self.errorMessage = error.localizedDescription // Set error message on failure
                }
            }
        }
    }
    
    func signOut() {
        isLoading = true
        errorMessage = nil
        
        print("signOut - Bắt đầu đăng xuất")
        do {
            try FirebaseManager.shared.signOut()
            DispatchQueue.main.async {
                [weak self] in
                guard let self = self else { return }
                self.authState = .signedOut
                print("Đăng xuất thành công: AuthState => .signedOut")
                self.user = nil
                self.isLoading = false
                self.errorMessage = nil // Clear error message on success
                NotificationCenter.default.post(name: .userDidSignOut, object: nil)
            }
        } catch {
            DispatchQueue.main.async {
                [weak self] in
                guard let self = self else { return }
                self.errorMessage = error.localizedDescription
                print("Đăng xuất thất bại: \(error.localizedDescription)")
                self.isLoading = false
            }
        }
    }
    
    // Force sign out khi có timeout hoặc cần reset trạng thái
    func forceSignOut() {
        print("forceSignOut - Reset trạng thái về .signedOut")
        authState = .signedOut
        user = nil
        errorMessage = "Không thể kết nối đến máy chủ"
        isLoading = false
    }
    
    // MARK: - Helper Methods
    
    private func handleAuthError(_ error: Error) {
        // Lưu lại error nguyên bản để debug
        print("=== DEBUG ERROR ===")
        print("Error object: \(error)")
        print("Error description: \(error.localizedDescription)")
        if let nsError = error as NSError? {
            print("NSError domain: \(nsError.domain), code: \(nsError.code)")
            print("NSError userInfo: \(nsError.userInfo)")
            
            // Xử lý trường hợp đặc biệt
            if nsError.domain == "FirebaseManager" && nsError.code == -1001 {
                // Timeout error
                errorMessage = "Kết nối máy chủ quá chậm. Vui lòng kiểm tra mạng và thử lại."
                return
            }
        }
        
        // Xử lý Auth Error Codes
        if let firebaseError = error as NSError?,
           let errorCode = AuthErrorCode(_bridgedNSError: firebaseError)?.code {
            print("Firebase Auth Error Code: \(errorCode.rawValue)")
            
            switch errorCode {
            case .networkError:
                errorMessage = "Lỗi kết nối mạng. Vui lòng kiểm tra kết nối internet."
            case .invalidAPIKey:
                errorMessage = "Cấu hình ứng dụng không hợp lệ. Vui lòng liên hệ nhà phát triển."
            case .appNotAuthorized:
                errorMessage = "Ứng dụng không được ủy quyền. Vui lòng liên hệ nhà phát triển."
            case .keychainError:
                errorMessage = "Lỗi truy cập keychain. Vui lòng khởi động lại thiết bị."
            case .internalError:
                errorMessage = "Đã xảy ra lỗi nội bộ. Vui lòng thử lại sau."
            default:
                errorMessage = AuthError.from(error).localizedDescription
            }
        } else {
            // Fallback to default handling
            errorMessage = AuthError.from(error).localizedDescription
        }
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    func isValidPassword(_ password: String) -> Bool {
        return password.count >= 6
    }
}

extension AuthViewModel {
    static var example: AuthViewModel {
        let viewModel = AuthViewModel()
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        viewModel.user = UserModel.example
        viewModel.authState = .signedIn
        return viewModel
    }
} 
