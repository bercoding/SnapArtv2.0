import Foundation
import FirebaseAuth

struct UserModel: Identifiable {
    var id: String
    var email: String
    var displayName: String?
    var photoURL: URL?
    var isEmailVerified: Bool
    
    init(user: FirebaseAuth.User) {
        self.id = user.uid
        self.email = user.email ?? ""
        self.displayName = user.displayName
        self.photoURL = user.photoURL
        self.isEmailVerified = user.isEmailVerified
    }
    
    // For preview purposes
    static var example: UserModel {
        UserModel(
            id: "user123",
            email: "user@example.com",
            displayName: "John Doe",
            photoURL: nil,
            isEmailVerified: true
        )
    }
    
    // Convenience initializer for previews
    init(id: String, email: String, displayName: String? = nil, photoURL: URL? = nil, isEmailVerified: Bool = false) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.isEmailVerified = isEmailVerified
    }
}

// Authentication state enum
enum AuthState {
    case signedIn
    case signedOut
    case loading
}

// Authentication error types
enum AuthError: Error, LocalizedError {
    case invalidEmail
    case weakPassword
    case emailAlreadyInUse
    case userNotFound
    case wrongPassword
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Email không hợp lệ"
        case .weakPassword:
            return "Mật khẩu yếu, vui lòng chọn mật khẩu phức tạp hơn"
        case .emailAlreadyInUse:
            return "Email đã được sử dụng"
        case .userNotFound:
            return "Không tìm thấy tài khoản"
        case .wrongPassword:
            return "Mật khẩu không chính xác"
        case .unknown(let message):
            return "Lỗi: \(message)"
        }
    }
    
    static func from(_ error: Error) -> AuthError {
        let nsError = error as NSError
        // Safely unwrap the optional AuthErrorCode
        if let errorCode = AuthErrorCode(_bridgedNSError: nsError)?.code {
            switch errorCode {
            case .invalidEmail:
                return .invalidEmail
            case .weakPassword:
                return .weakPassword
            case .emailAlreadyInUse:
                return .emailAlreadyInUse
            case .userNotFound:
                return .userNotFound
            case .wrongPassword:
                return .wrongPassword
            default:
                return .unknown(error.localizedDescription)
            }
        } else {
            return .unknown(error.localizedDescription)
        }
    }
} 
