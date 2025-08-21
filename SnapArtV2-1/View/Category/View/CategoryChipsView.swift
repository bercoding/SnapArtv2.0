import SwiftUI

struct CategoryChipsView: View {
    @Binding var selectedCategory: FilterCategory?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(FilterCategory.allCases, id: \.self) { cat in
                    let isSelected = (selectedCategory == cat)
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = cat
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(cat.icon)
                            Text(cat.title)
                                .font(.subheadline).bold()
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(isSelected ? Color.white.opacity(0.3) : Color.white.opacity(0.15))
                        .foregroundColor(Color.white)
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? Color.white : Color.white.opacity(0.5), lineWidth: 1)
                        )
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
} 