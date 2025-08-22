import SwiftUI
import StoreKit

struct PremiumView: View {
    @EnvironmentObject private var purchaseManager: InAppPurchaseManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedProduct: Product?
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var selectedPlan: String = "monthly"
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Hero Section
                        heroSection
                        
                        // Features Grid
                        featuresGridSection
                        
                        // Pricing Plans
                        pricingSection
                        
                        // Testimonials
                        testimonialsSection
                        
                        // FAQ Section
                        faqSection
                        
                        // Action Buttons
                        actionButtonsSection
                        
                        // Legal Info
                        legalSection
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
        }
        .alert(NSLocalizedString("Thông báo", comment: "Notice"), isPresented: $showAlert) {
            Button(NSLocalizedString("OK", comment: "OK")) { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            Task {
                await purchaseManager.loadProducts()
            }
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: 24) {
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
            VStack(spacing: 16) {
                Text(NSLocalizedString("Nâng cấp lên Premium", comment: "Upgrade to Premium"))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(NSLocalizedString("Mở khóa tất cả tính năng và filter cao cấp", comment: "Unlock all premium features and filters"))
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            
            // Stats Row
            HStack(spacing: 32) {
                StatItem(number: "50+", label: NSLocalizedString("Filter", comment: "Filters"))
                StatItem(number: "∞", label: NSLocalizedString("Không giới hạn", comment: "Unlimited"))
                StatItem(number: "24/7", label: NSLocalizedString("Hỗ trợ", comment: "Support"))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 40)
        .padding(.bottom, 32)
    }
    
    // MARK: - Features Grid Section
    
    private var featuresGridSection: some View {
        VStack(spacing: 20) {
            Text(NSLocalizedString("Tính năng Premium", comment: "Premium Features"))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
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
                
                FeatureCard(
                    icon: "wand.and.stars",
                    title: NSLocalizedString("Chỉnh sửa nâng cao", comment: "Advanced editing"),
                    description: NSLocalizedString("Công cụ chuyên nghiệp", comment: "Professional tools")
                )
                
                FeatureCard(
                    icon: "bolt.fill",
                    title: NSLocalizedString("Tốc độ cao", comment: "High speed"),
                    description: NSLocalizedString("Xử lý nhanh chóng", comment: "Fast processing")
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
    }
    
    // MARK: - Pricing Section
    
    private var pricingSection: some View {
        VStack(spacing: 24) {
            Text(NSLocalizedString("Chọn gói phù hợp", comment: "Choose your plan"))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Plan Selector
            HStack(spacing: 0) {
                PlanToggleButton(
                    title: NSLocalizedString("Tháng", comment: "Monthly"),
                    isSelected: selectedPlan == "monthly",
                    action: { selectedPlan = "monthly" }
                )
                
                PlanToggleButton(
                    title: NSLocalizedString("Năm", comment: "Yearly"),
                    isSelected: selectedPlan == "yearly",
                    action: { selectedPlan = "yearly" }
                )
            }
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 24)
            
            // Pricing Cards
            VStack(spacing: 16) {
                if selectedPlan == "monthly" {
                    ForEach(purchaseManager.getSubscriptionProducts().filter { $0.id.contains("monthly") }, id: \.id) { product in
                        PricingCard(
                            product: product,
                            isPopular: false,
                            isActive: purchaseManager.isSubscriptionActive(),
                            onPurchase: {
                                Task {
                                    await purchaseProduct(product)
                                }
                            }
                        )
                    }
                } else {
                    ForEach(purchaseManager.getSubscriptionProducts().filter { $0.id.contains("yearly") }, id: \.id) { product in
                        PricingCard(
                            product: product,
                            isPopular: true,
                            isActive: purchaseManager.isSubscriptionActive(),
                            onPurchase: {
                                Task {
                                    await purchaseProduct(product)
                                }
                            }
                        )
                    }
                }
                
                // Non-consumable product
                ForEach(purchaseManager.getNonConsumableProducts(), id: \.id) { product in
                    PricingCard(
                        product: product,
                        isPopular: false,
                        isActive: purchaseManager.isProductPurchased(product.id),
                        onPurchase: {
                            Task {
                                await purchaseProduct(product)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 32)
    }
    
    // MARK: - Testimonials Section
    
    private var testimonialsSection: some View {
        VStack(spacing: 20) {
            Text(NSLocalizedString("Người dùng nói gì", comment: "What users say"))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    TestimonialCard(
                        name: "Nguyễn Văn A",
                        rating: 5,
                        comment: NSLocalizedString("Filter đẹp quá! Tôi rất thích tính năng premium.", comment: "Beautiful filters! I love the premium features.")
                    )
                    
                    TestimonialCard(
                        name: "Trần Thị B",
                        rating: 5,
                        comment: NSLocalizedString("Ứng dụng tuyệt vời, đáng để mua premium.", comment: "Great app, worth buying premium.")
                    )
                    
                    TestimonialCard(
                        name: "Lê Văn C",
                        rating: 5,
                        comment: NSLocalizedString("Chất lượng filter rất cao, rất hài lòng!", comment: "Filter quality is very high, very satisfied!")
                    )
                }
                .padding(.horizontal, 24)
            }
        }
        .padding(.vertical, 32)
    }
    
    // MARK: - FAQ Section
    
    private var faqSection: some View {
        VStack(spacing: 20) {
            Text(NSLocalizedString("Câu hỏi thường gặp", comment: "Frequently Asked Questions"))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                FAQItem(
                    question: NSLocalizedString("Tôi có thể hủy subscription không?", comment: "Can I cancel my subscription?"),
                    answer: NSLocalizedString("Có, bạn có thể hủy bất cứ lúc nào trong App Store.", comment: "Yes, you can cancel anytime in the App Store.")
                )
                
                FAQItem(
                    question: NSLocalizedString("Premium có hoạt động trên tất cả thiết bị không?", comment: "Does premium work on all devices?"),
                    answer: NSLocalizedString("Có, premium được đồng bộ qua iCloud.", comment: "Yes, premium syncs via iCloud.")
                )
                
                FAQItem(
                    question: NSLocalizedString("Tôi có thể dùng thử trước khi mua không?", comment: "Can I try before buying?"),
                    answer: NSLocalizedString("Có, bạn có 1 tuần dùng thử miễn phí.", comment: "Yes, you get 1 week free trial.")
                )
            }
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 32)
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            Button {
                Task {
                    await restorePurchases()
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text(NSLocalizedString("Khôi phục mua hàng", comment: "Restore purchases"))
                }
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .underline()
            }
            
            Text(NSLocalizedString("* Miễn phí dùng thử 7 ngày", comment: "* 7-day free trial"))
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 32)
    }
    
    // MARK: - Legal Section
    
    private var legalSection: some View {
        VStack(spacing: 8) {
            Text(NSLocalizedString("Bằng việc mua, bạn đồng ý với", comment: "By purchasing, you agree to"))
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
            
            HStack(spacing: 16) {
                Button(NSLocalizedString("Điều khoản sử dụng", comment: "Terms of Service")) { }
                Button(NSLocalizedString("Chính sách bảo mật", comment: "Privacy Policy")) { }
            }
            .font(.caption)
            .foregroundColor(.white.opacity(0.6))
            .underline()
        }
        .padding(.bottom, 40)
    }
    
    // MARK: - Actions
    
    private func purchaseProduct(_ product: Product) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await purchaseManager.purchase(product)
            alertMessage = NSLocalizedString("Mua hàng thành công!", comment: "Purchase successful!")
            showAlert = true
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
    
    private func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await purchaseManager.restorePurchases()
            alertMessage = NSLocalizedString("Khôi phục mua hàng thành công!", comment: "Restore successful!")
            showAlert = true
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}

// MARK: - Supporting Views

struct StatItem: View {
    let number: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(number)
                .font(.title2)
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
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.yellow)
                .frame(width: 40, height: 40)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct PlanToggleButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.white.opacity(0.2) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct PricingCard: View {
    let product: Product
    let isPopular: Bool
    let isActive: Bool
    let onPurchase: () -> Void
    
    private var isYearly: Bool {
        product.id.contains("yearly")
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayName)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(product.description)
                        .font(.caption)
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
                        .padding(.vertical, 4)
                        .background(Color.orange)
                        .clipShape(Capsule())
                }
            }
            
            // Price
            HStack(alignment: .bottom, spacing: 8) {
                Text(product.displayPrice)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(isYearly ? NSLocalizedString("/năm", comment: "/year") : NSLocalizedString("/tháng", comment: "/month"))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, 4)
            }
            
            // Savings badge for yearly
            if isYearly {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text(NSLocalizedString("Tiết kiệm 33% so với gói tháng", comment: "Save 33% vs monthly"))
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.yellow.opacity(0.2))
                .clipShape(Capsule())
            }
            
            // Action Button
            if isActive {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(isYearly ? NSLocalizedString("Đang hoạt động", comment: "Active") : NSLocalizedString("Đã mua", comment: "Purchased"))
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Button(action: onPurchase) {
                    Text(NSLocalizedString("Bắt đầu ngay", comment: "Get Started"))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "ff6b6b"), Color(hex: "ee5a24")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct TestimonialCard: View {
    let name: String
    let rating: Int
    let comment: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Rating
            HStack {
                ForEach(1...5, id: \.self) { index in
                    Image(systemName: index <= rating ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
            }
            
            // Comment
            Text(comment)
                .font(.subheadline)
                .foregroundColor(.white)
                .lineLimit(4)
            
            // Name
            Text("- \(name)")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .fontWeight(.medium)
        }
        .padding(16)
        .frame(width: 280)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct FAQItem: View {
    let question: String
    let answer: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(question)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.caption)
                }
            }
            
            if isExpanded {
                Text(answer)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.leading)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
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
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 