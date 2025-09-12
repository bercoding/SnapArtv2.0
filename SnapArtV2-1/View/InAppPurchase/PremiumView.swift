import SwiftUI
import StoreKit

struct PremiumView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel: PremiumViewModel
    
    init(purchaseManager: InAppPurchaseManager) {
        _viewModel = StateObject(wrappedValue: PremiumViewModel(purchaseManager: purchaseManager))
    }
    
    var body: some View {
        ZStack {
            // Gradient background
            AppTheme.mainGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Hero Section
                    heroSection
                    
                    Divider()
                        .background(Color.white.opacity(0.3))
                    
                    // Features Grid
                    featuresGridSection
                    
                    Divider()
                        .background(Color.white.opacity(0.3))
                    
                    // Pricing Section
                    pricingSection
                    
                    // Restore Purchases Button
                    Button(action: {
                        Task {
                            await viewModel.restorePurchases()
                        }
                    }) {
                        Text(NSLocalizedString("Khôi phục giao dịch đã mua", comment: "Restore purchases"))
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.vertical, 12)
                    }
                    
                    // Terms and Privacy
                    VStack(spacing: 8) {
                        Text(NSLocalizedString("Bằng việc mua, bạn đồng ý với", comment: "By purchasing you agree to"))
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                        
                        HStack(spacing: 4) {
                            Text(NSLocalizedString("Điều khoản dịch vụ", comment: "Terms of Service"))
                                .font(.caption2)
                                .foregroundColor(.blue)
                            
                            Text("•")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                            
                            Text(NSLocalizedString("Chính sách bảo mật", comment: "Privacy Policy"))
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.bottom, 20)
                }
                .padding()
            }
        }
        .navigationBarTitle("Premium", displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "chevron.left")
                .foregroundColor(.white)
        })
        .alert(NSLocalizedString("Thông báo", comment: "Notice"), isPresented: $viewModel.showAlert) {
            Button(NSLocalizedString("OK", comment: "OK")) {}
        } message: {
            Text(viewModel.alertMessage)
        }
        .onAppear {
            // Sản phẩm đã được tải trong init của PremiumViewModel
        }
    }
    
    // MARK: - Hero Section - Compact
    
    private var heroSection: some View {
        VStack(spacing: 16) {
            // Premium Badge
            HStack(spacing: 8) {
                Image(systemName: "crown.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                
                Text("PREMIUM")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.yellow.opacity(0.2))
                    .clipShape(Capsule())
            }
            
            // Main Title
            VStack(spacing: 8) {
                Text(NSLocalizedString("Nâng cấp lên Premium", comment: "Upgrade to Premium"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(NSLocalizedString("Mở khóa tất cả tính năng và filter cao cấp", comment: "Unlock all premium features and filters"))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            
            // Stats Row - Compact
            HStack(spacing: 24) {
                StatItem(number: "20+", label: NSLocalizedString("Filter", comment: "Filters"))
                StatItem(number: "∞", label: NSLocalizedString("Không giới hạn", comment: "Unlimited"))
                StatItem(number: "24/7", label: NSLocalizedString("Hỗ trợ", comment: "Support"))
            }
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Features Grid Section - Compact
    
    private var featuresGridSection: some View {
        VStack(spacing: 16) {
            Text(NSLocalizedString("Tính năng Premium", comment: "Premium Features"))
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                FeatureCard(
                    icon: "sparkles",
                    title: NSLocalizedString("Tất cả filter premium", comment: "All premium filters"),
                    description: NSLocalizedString("Truy cập không giới hạn", comment: "Unlimited access")
                )
                
                FeatureCard(
                    icon: "camera.filters",
                    title: NSLocalizedString("Filter mới hàng tuần", comment: "New filters weekly"),
                    description: NSLocalizedString("Cập nhật thường xuyên", comment: "Regular updates")
                )
                
                FeatureCard(
                    icon: "xmark.circle",
                    title: NSLocalizedString("Không quảng cáo", comment: "No ads"),
                    description: NSLocalizedString("Trải nghiệm mượt mà", comment: "Smooth experience")
                )
                
                FeatureCard(
                    icon: "icloud",
                    title: NSLocalizedString("Đồng bộ đám mây", comment: "Cloud sync"),
                    description: NSLocalizedString("An toàn và tiện lợi", comment: "Safe and convenient")
                )
            }
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Pricing Section - Compact
    
    private var pricingSection: some View {
        VStack(spacing: 16) {
            Text(NSLocalizedString("Chọn gói Premium", comment: "Choose Premium Plan"))
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Segment Control
            HStack(spacing: 0) {
                SegmentButton(
                    title: NSLocalizedString("Hàng tháng", comment: "Monthly"),
                    isSelected: viewModel.selectedPlan == "monthly",
                    action: { viewModel.selectedPlan = "monthly" }
                )
                
                SegmentButton(
                    title: NSLocalizedString("Hàng năm", comment: "Yearly"),
                    isSelected: viewModel.selectedPlan == "yearly",
                    action: { viewModel.selectedPlan = "yearly" }
                )
            }
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Pricing Cards - Compact
            VStack(spacing: 16) {
                // Show selected plan products
                if viewModel.selectedPlan == "monthly" {
                    if viewModel.monthlyProducts.isEmpty {
                        Text("Không có gói tháng")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    } else {
                        ForEach(viewModel.monthlyProducts, id: \.id) { product in
                            PricingCard(
                                product: product,
                                isPopular: false,
                                isActive: viewModel.isProductPurchased(product.id),
                                onPurchase: {
                                    Task {
                                        await viewModel.purchaseSubscription(product)
                                    }
                                },
                                viewModel: viewModel
                            )
                        }
                    }
                } else {
                    if viewModel.yearlyProducts.isEmpty {
                        Text("Không có gói năm")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    } else {
                        ForEach(viewModel.yearlyProducts, id: \.id) { product in
                            PricingCard(
                                product: product,
                                isPopular: true,
                                isActive: viewModel.isProductPurchased(product.id),
                                onPurchase: {
                                    Task {
                                        await viewModel.purchaseSubscription(product)
                                    }
                                },
                                viewModel: viewModel
                            )
                        }
                    }
                }
                
                // Non-consumable product (always show)
                if viewModel.nonConsumableProducts.isEmpty {
                    Text("Không có gói mua một lần")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                } else {
                    ForEach(viewModel.nonConsumableProducts, id: \.id) { product in
                        PricingCard(
                            product: product,
                            isPopular: false,
                            isActive: viewModel.isProductPurchased(product.id),
                            onPurchase: {
                                Task {
                                    await viewModel.purchaseProduct(product)
                                }
                            },
                            viewModel: viewModel
                        )
                    }
                }
            }
            
            // Loading state
            if viewModel.products.isEmpty {
                Text("Đang tải sản phẩm...")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.vertical, 20)
    }
}

// MARK: - Supporting Views - Compact

struct StatItem: View {
    let number: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(number)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.yellow)
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
            
            VStack(spacing: 3) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct SegmentButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.white.opacity(0.2) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

struct PricingCard: View {
    let product: Product
    let isPopular: Bool
    let isActive: Bool
    let onPurchase: () -> Void
    let viewModel: PremiumViewModel
    
    private var isYearly: Bool {
        product.id.contains("yearly")
    }
    
    var body: some View {
        VStack(spacing: 14) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(product.displayName)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(product.description)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                }
                
                Spacer()
                
                if isPopular {
                    Text(NSLocalizedString("PHỔ BIẾN", comment: "POPULAR"))
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.orange)
                        .clipShape(Capsule())
                }
            }
            
            // Price
            HStack(alignment: .bottom, spacing: 6) {
                Text(viewModel.formatPrice(product))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(isYearly ? NSLocalizedString("/năm", comment: "/year") : NSLocalizedString("/tháng", comment: "/month"))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, 2)
            }
            
            // Savings badge for yearly
            if isYearly {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption2)
                    Text(NSLocalizedString("Tiết kiệm 33% so với gói tháng", comment: "Save 33% vs monthly"))
                        .font(.caption2)
                        .foregroundColor(.yellow)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.yellow.opacity(0.2))
                .clipShape(Capsule())
            }
            
            // Introductory offer badge
            if viewModel.hasIntroductoryOffer(for: product) {
                HStack {
                    Image(systemName: "gift.fill")
                        .foregroundColor(.green)
                        .font(.caption2)
                    Text("1 tuần dùng thử miễn phí")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.2))
                .clipShape(Capsule())
            }
            
            // Action Button
            if isActive {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text(isYearly ? NSLocalizedString("Đang hoạt động", comment: "Active") : NSLocalizedString("Đã mua", comment: "Purchased"))
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Button(action: onPurchase) {
                    Text(NSLocalizedString("Mua ngay", comment: "Buy now"))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(viewModel.isPurchasing)
                .overlay(
                    Group {
                        if viewModel.isPurchasing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                    }
                )
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
