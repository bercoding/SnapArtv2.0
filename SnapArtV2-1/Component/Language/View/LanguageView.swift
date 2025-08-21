import SwiftUI

struct LanguageView: View {
    @StateObject private var viewModel = LanguageViewModel()
    
    var body: some View {
        NavigationView {
            List(viewModel.languages) { language in
                HStack {
                    Text(language.flag)
                        .font(.system(size: 32))
                        .frame(width: 40)
                    
                    VStack(alignment: .leading) {
                        Text(language.name)
                            .font(.headline)
                        Text(language.englishName)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Radio button
                    Circle()
                        .stroke(viewModel.selectedCode == language.code ? Color.blue : Color.gray, lineWidth: 2)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .fill(viewModel.selectedCode == language.code ? Color.blue : Color.clear)
                                .frame(width: 12, height: 12)
                        )
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.select(language: language)
                }
            }
            .navigationTitle("Languages")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        print("Selected: \(viewModel.selectedCode)")
                    }
                }
            }
        }
    }
}

