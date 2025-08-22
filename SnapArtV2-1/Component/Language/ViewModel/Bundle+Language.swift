import Foundation
import ObjectiveC

private var kAssociatedLanguageBundleKey: UInt8 = 0

extension Bundle {
	/// Thiết lập ngôn ngữ runtime cho NSLocalizedString mà không cần restart app
	class func setLanguage(_ languageCode: String) {
		// Xử lý RTL nếu cần
		let isRTL = Locale.characterDirection(forLanguage: languageCode) == .rightToLeft
		UserDefaults.standard.set(isRTL ? "YES" : "NO", forKey: "AppleTextDirection")
		UserDefaults.standard.set(isRTL ? "YES" : "NO", forKey: "NSForceRightToLeftWritingDirection")
		
		// Trỏ tới bundle .lproj tương ứng
		let path = Bundle.main.path(forResource: languageCode, ofType: "lproj")
		let languageBundle = path.flatMap { Bundle(path: $0) }
		
		// Gắn bundle ngôn ngữ vào main bundle bằng associated object
		objc_setAssociatedObject(Bundle.main, &kAssociatedLanguageBundleKey, languageBundle, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		
		// Đảm bảo Bundle.main dùng subclass override method localizedString
		object_setClass(Bundle.main, LanguageOverrideBundle.self)
	}
	
	private class LanguageOverrideBundle: Bundle {
		override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
			if let bundle = objc_getAssociatedObject(self, &kAssociatedLanguageBundleKey) as? Bundle {
				return bundle.localizedString(forKey: key, value: value, table: tableName)
			}
			return super.localizedString(forKey: key, value: value, table: tableName)
		}
	}
} 