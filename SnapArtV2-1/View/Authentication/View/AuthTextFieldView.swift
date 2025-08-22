import SwiftUI

struct AuthTextFieldView: View {
	let iconName: String
	let placeholderKey: String
	let isSecure: Bool
	@Binding var text: String
	@State private var isShowingPassword: Bool = false
	
	init(iconName: String, placeholder: String, text: Binding<String>, isSecure: Bool = false) {
		self.iconName = iconName
		self.placeholderKey = placeholder
		self._text = text
		self.isSecure = isSecure
	}
	
	var body: some View {
		HStack {
			Image(systemName: iconName)
				.foregroundColor(.gray)
				.frame(width: 20)
			
			Group {
				if isSecure && !isShowingPassword {
					SecureField("", text: $text, prompt: Text(NSLocalizedString(placeholderKey, comment: "Auth placeholder")))
						.autocapitalization(.none)
						.disableAutocorrection(true)
				} else if isSecure && isShowingPassword {
					TextField("", text: $text, prompt: Text(NSLocalizedString(placeholderKey, comment: "Auth placeholder")))
						.autocapitalization(.none)
						.disableAutocorrection(true)
				} else {
					TextField("", text: $text, prompt: Text(NSLocalizedString(placeholderKey, comment: "Auth placeholder")))
						.autocapitalization(.none)
						.disableAutocorrection(true)
				}
			}
			.padding(.leading, 8)
			
			if isSecure {
				Button(action: {
					isShowingPassword.toggle()
				}) {
					Image(systemName: isShowingPassword ? "eye.slash.fill" : "eye.fill")
						.foregroundColor(.gray)
				}
			}
		}
		.padding()
		.background(
			RoundedRectangle(cornerRadius: 10)
				.fill(Color(.systemGray6))
		)
		.padding(.horizontal)
	}
} 