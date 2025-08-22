import Foundation
import SwiftUI

class LanguageViewModel: ObservableObject {
    let languages: [Language] = [
        Language(code: "en", name: "English", englishName: "English", flag: "🇬🇧"),
        Language(code: "vi", name: "Tiếng Việt", englishName: "Vietnamese", flag: "🇻🇳"),
        Language(code: "zh", name: "简体中文", englishName: "Chinese (Simplified)", flag: "🇨🇳"),
        Language(code: "ja", name: "日本語", englishName: "Japanese", flag: "🇯🇵"),
        Language(code: "ko", name: "한국어", englishName: "Korean", flag: "🇰🇷"),
        Language(code: "fr", name: "Français", englishName: "French", flag: "🇫🇷"),
        Language(code: "de", name: "Deutsch", englishName: "German", flag: "🇩🇪"),
        Language(code: "es", name: "Español", englishName: "Spanish", flag: "🇪🇸"),
        Language(code: "pt", name: "Português", englishName: "Portuguese", flag: "🇵🇹"),
        Language(code: "ru", name: "Русский", englishName: "Russian", flag: "🇷🇺"),
        Language(code: "ar", name: "العربية", englishName: "Arabic", flag: "🇸🇦"),
        Language(code: "hi", name: "हिन्दी", englishName: "Hindi", flag: "🇮🇳"),
        Language(code: "id", name: "Bahasa Indonesia", englishName: "Indonesian", flag: "🇮🇩"),
        Language(code: "ms", name: "Bahasa Melayu", englishName: "Malay", flag: "🇲🇾"),
        Language(code: "th", name: "ไทย", englishName: "Thai", flag: "🇹🇭")
    ]
    
    @Published var selectedCode: String {
        didSet {
            UserDefaults.standard.set(selectedCode, forKey: "selectedLanguage")
            // Force refresh UI ngay khi đổi code
            DispatchQueue.main.async { [weak self] in
                self?.refreshID = UUID()
            }
        }
    }
    
    // State để force reload UI khi cần
    @Published var refreshID = UUID()
    
    init() {
        if let saved = UserDefaults.standard.string(forKey: "selectedLanguage") {
            self.selectedCode = saved
        } else {
            self.selectedCode = "en" // mặc định English
        }
        // Áp dụng ngôn ngữ runtime lúc khởi động để khớp với selectedCode đã lưu
        updateLocale()
    }
    
    func applyLanguage() {
        updateLocale()
    }
    
    private func updateLocale() {
        // Cập nhật locale ưu tiên của hệ thống (để UIKit dùng nếu cần)
        UserDefaults.standard.set([selectedCode], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        
        // Áp dụng bundle ngôn ngữ runtime để NSLocalizedString cập nhật ngay
        Bundle.setLanguage(selectedCode)
        
        // Force reload UI bằng cách tạo ID mới
        DispatchQueue.main.async { [weak self] in
            self?.refreshID = UUID()
        }
        
        // Gửi notification để các view đóng/mở sheet nếu cần
        NotificationCenter.default.post(name: .languageChanged, object: nil)
    }
}

extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
}
