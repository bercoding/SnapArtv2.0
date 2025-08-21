import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore


class FirebaseManager {
    static let shared = FirebaseManager()
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    private init() {
        // Đảm bảo Firebase đã được cấu hình
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }
    
    // MARK: - Authentication
    
    func signUp(email: String, password: String, completion: @escaping (Result<UserModel, Error>) -> Void) {
        auth.createUser(withEmail: email, password: password) { (result, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let user = result?.user {
                // Tạo document user trong Firestore
                let userData: [String: Any] = [
                    "email": user.email ?? "",
                    "uid": user.uid,
                    "createdAt": FieldValue.serverTimestamp()
                ]
                
                self.db.collection("users").document(user.uid).setData(userData) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        let userModel = UserModel(user: user)
                        completion(.success(userModel))
                    }
                }
            } else {
                completion(.failure(NSError(domain: "FirebaseManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Không thể tạo người dùng"])))
            }
        }
    }
    
    func signIn(email: String, password: String, completion: @escaping (Result<UserModel, Error>) -> Void) {
        auth.signIn(withEmail: email, password: password) { (result, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let user = result?.user {
                let userModel = UserModel(user: user)
                completion(.success(userModel))
            } else {
                completion(.failure(NSError(domain: "FirebaseManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Không thể đăng nhập"])))
            }
        }
    }
    
    func signOut() throws {
        try auth.signOut()
    }
    
    var currentUser: UserModel? {
        guard let firebaseUser = auth.currentUser else { return nil }
        return UserModel(user: firebaseUser)
    }
    
    // MARK: - User Data
    
    func getUserData(completion: @escaping (Result<[String: Any], Error>) -> Void) {
        guard let currentUser = auth.currentUser else {
            completion(.failure(NSError(domain: "FirebaseManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Người dùng chưa đăng nhập"])))
            return
        }
        
        db.collection("users").document(currentUser.uid).getDocument { (document, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let document = document, document.exists, let data = document.data() {
                completion(.success(data))
            } else {
                completion(.failure(NSError(domain: "FirebaseManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Không tìm thấy dữ liệu người dùng"])))
            }
        }
    }
    
    func updateUserData(data: [String: Any], completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUser = auth.currentUser else {
            completion(.failure(NSError(domain: "FirebaseManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Người dùng chưa đăng nhập"])))
            return
        }
        
        db.collection("users").document(currentUser.uid).updateData(data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
} 
