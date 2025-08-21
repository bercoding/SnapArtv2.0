import Foundation
import SwiftUI

class LanguageViewModel: ObservableObject {
    @Published var languages: [Language] = [
        Language(code: "ar", name: "العربية", englishName: "Arabic", flag: "🇸🇦"),
        Language(code: "zh", name: "简体中文", englishName: "Chinese (Simplified)", flag: "🇨🇳"),
        Language(code: "de", name: "Deutsch", englishName: "German", flag: "🇩🇪"),
        Language(code: "en", name: "English", englishName: "selected language", flag: "🇬🇧"),
        Language(code: "hi", name: "हिन्दी", englishName: "Hindi", flag: "🇮🇳"),
        Language(code: "id", name: "Bahasa Indonesia", englishName: "Indonesian", flag: "🇮🇩"),
        Language(code: "ms", name: "Bahasa Melayu", englishName: "Malay", flag: "🇲🇾"),
        Language(code: "pl", name: "Polski", englishName: "Polish", flag: "🇵🇱")
    ]
    
    @Published var selectedCode: String {
        didSet {
            UserDefaults.standard.set(selectedCode, forKey: "selectedLanguage")
        }
    }
    
    init() {
        if let saved = UserDefaults.standard.string(forKey: "selectedLanguage") {
            self.selectedCode = saved
        } else {
            self.selectedCode = "en" // mặc định English
        }
    }
    
    func select(language: Language) {
        selectedCode = language.code
    }
}
