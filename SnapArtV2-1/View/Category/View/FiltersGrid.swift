import GoogleMobileAds
import SwiftUI

struct FiltersGrid: View {
    let category: FilterCategory
    let onSelect: (FilterType) -> Void
    @StateObject private var unlockManager = FilterUnlockManager.shared
    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(category.filters, id: \.self) { ft in
                    if unlockManager.isFilterLocked(ft) {
                        // Hiển thị filter bị khóa
                        LockedFilterView(filter: ft)
                            .frame(maxWidth: .infinity, minHeight: 84)
                    } else {
                        // Hiển thị filter bình thường
                        Button {
                            onSelect(ft)
                        } label: {
                            VStack(spacing: 8) {
                                // Chỉ hiển thị text, không hiển thị emoji
                                Text(ft.displayName)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                Text(ft.icon)
                            }
                            .frame(maxWidth: .infinity, minHeight: 84)
                            .padding(10)
                            .background(Color.white.opacity(0.2)) // Thay đổi màu nền thành trắng mờ
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        .background(Color.clear) // Đặt background là trong suốt
    }
}
