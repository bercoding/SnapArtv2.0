import Foundation
import SwiftUI

// Thêm lại extension để khai báo languageChanged
extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
}

class LanguageViewModel: ObservableObject {
    let languages: [Language] = [
        Language(code: "vi", name: "Tiếng Việt", englishName: "Vietnamese", flag: "🇻🇳"),
        Language(code: "en", name: "English", englishName: "English", flag: "🇬🇧"),
        Language(code: "ar", name: "العربية", englishName: "Arabic", flag: "🇸🇦"),
        Language(code: "de", name: "Deutsch", englishName: "German", flag: "🇩🇪"),
        Language(code: "es", name: "Español", englishName: "Spanish", flag: "🇪🇸"),
        Language(code: "fr", name: "Français", englishName: "French", flag: "🇫🇷"),
        Language(code: "hi", name: "हिन्दी", englishName: "Hindi", flag: "🇮🇳"),
        Language(code: "hu", name: "Magyar", englishName: "Hungarian", flag: "🇭🇺"),
        Language(code: "id", name: "Bahasa Indonesia", englishName: "Indonesian", flag: "🇮🇩"),
        Language(code: "ja", name: "日本語", englishName: "Japanese", flag: "🇯🇵"),
        Language(code: "ko", name: "한국어", englishName: "Korean", flag: "🇰🇷"),
        Language(code: "ms", name: "Bahasa Melayu", englishName: "Malay", flag: "🇲🇾"),
        Language(code: "th", name: "ไทย", englishName: "Thai", flag: "🇹🇭"),
        Language(code: "tr", name: "Türkçe", englishName: "Turkish", flag: "🇹🇷"),
        Language(code: "zh-Hans", name: "简体中文", englishName: "Chinese (Simplified)", flag: "🇨🇳")
    ]
    
    @Published var selectedCode: String {
        didSet {
            UserDefaults.standard.set(selectedCode, forKey: "selectedLanguage")
            // Áp dụng ngay khi đổi ngôn ngữ
            updateLocale()
        }
    }
    
    // State để force reload UI khi cần
    @Published var refreshID = UUID()
    
    init() {
        if let saved = UserDefaults.standard.string(forKey: "selectedLanguage") {
            self.selectedCode = saved
        } else {
            self.selectedCode = "vi" // mặc định Tiếng Việt
        }
        // Áp dụng ngôn ngữ runtime lúc khởi động để khớp với selectedCode đã lưu
        updateLocale()
    }
    
    func applyLanguage() {
        updateLocale()
    }
    
    private func updateLocale() {
        // Map mã không khớp sang tài nguyên có sẵn
        let actualCode: String
        if selectedCode == "zh" { actualCode = "zh-Hans" } else { actualCode = selectedCode }
        
        // Debug: in ra đường dẫn .lproj
        let path = Bundle.main.path(forResource: actualCode, ofType: "lproj")
        print("[Language] selected=\(selectedCode) actual=\(actualCode) lprojPath=\(path ?? "nil")")
        
        // Cập nhật locale ưu tiên của hệ thống (để UIKit dùng nếu cần)
        UserDefaults.standard.set([actualCode], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        // Áp dụng bundle ngôn ngữ runtime để NSLocalizedString cập nhật ngay
        Bundle.setLanguage(actualCode)
        
        // Force reload UI bằng cách tạo ID mới
        DispatchQueue.main.async { [weak self] in
            self?.refreshID = UUID()
        }
        
        // Gửi notification để các view đóng/mở sheet nếu cần
        NotificationCenter.default.post(name: .languageChanged, object: nil)
    }
    
    // Phương thức để lấy tên ngôn ngữ hiện tại
    func getCurrentLanguageName() -> String {
        if let language = languages.first(where: { $0.code == selectedCode || ($0.code == "zh-Hans" && selectedCode == "zh") }) {
            return language.name
        }
        return "English" // Mặc định nếu không tìm thấy
    }
}
