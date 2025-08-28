import Foundation
import StoreKit
import Combine

@MainActor
class PremiumViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var selectedPlan: String = "monthly"
    
    private let purchaseManager: InAppPurchaseManager
    
    init(purchaseManager: InAppPurchaseManager) {
        self.purchaseManager = purchaseManager
    }
    
    // MARK: - Computed Properties
    
    var products: [Product] {
        purchaseManager.products
    }
    
    var subscriptionProducts: [Product] {
        purchaseManager.getSubscriptionProducts()
    }
    
    var nonConsumableProducts: [Product] {
        purchaseManager.getNonConsumableProducts()
    }
    
    var monthlyProducts: [Product] {
        subscriptionProducts.filter { $0.id.contains("monthly") }
    }
    
    var yearlyProducts: [Product] {
        subscriptionProducts.filter { $0.id.contains("yearly") }
    }
    
    var isSubscriptionActive: Bool {
        purchaseManager.isSubscriptionActive()
    }
    
    // MARK: - Actions
    
    func purchaseProduct(_ product: Product) async {
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
    
    func purchaseSubscription(_ product: Product) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await purchaseManager.purchaseSubscription(product)
            alertMessage = NSLocalizedString("Đăng ký thành công!", comment: "Subscription successful!")
            showAlert = true
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
    
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await purchaseManager.restorePurchases()
            
            // Check if any subscriptions were restored
            let hasActiveSubscriptions = purchaseManager.isSubscriptionActive() || 
                                       !purchaseManager.purchasedProductIDs.isEmpty
            
            if hasActiveSubscriptions {
                alertMessage = NSLocalizedString("Khôi phục mua hàng thành công! Đã tìm thấy \(purchaseManager.purchasedProductIDs.count) sản phẩm.", comment: "Restore successful with count")
            } else {
                alertMessage = NSLocalizedString("Khôi phục hoàn tất. Không tìm thấy sản phẩm nào.", comment: "Restore completed but no products found")
            }
            showAlert = true
            
        } catch {
            alertMessage = "Khôi phục thất bại: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    func loadProducts() async {
        await purchaseManager.loadProducts()
    }
    
    // MARK: - Helper Methods
    
    func isProductPurchased(_ productID: String) -> Bool {
        return purchaseManager.isProductPurchased(productID)
    }
    
    func hasIntroductoryOffer(for product: Product) -> Bool {
        return purchaseManager.hasIntroductoryOffer(for: product)
    }
    
    func getSubscriptionPeriod(for product: Product) -> String {
        return purchaseManager.getSubscriptionPeriod(for: product)
    }
    
    // MARK: - Subscription Status Logic
    
    func isSubscriptionActive(for product: Product) -> Bool {
        let productID = product.id
        let isYearly = productID.contains("yearly")
        let isMonthly = productID.contains("monthly")
        
        if isYearly {
            // Yearly is active if purchased
            return purchaseManager.isProductPurchased(productID)
        } else if isMonthly {
            // Monthly is active if purchased AND no yearly exists
            if purchaseManager.isProductPurchased(productID) {
                let yearlyProducts = purchaseManager.getSubscriptionProducts().filter { $0.id.contains("yearly") }
                let hasYearly = yearlyProducts.contains { purchaseManager.isProductPurchased($0.id) }
                return !hasYearly
            }
            return false
        }
        
        return false
    }
    
    func canUpgradeToYearly() -> Bool {
        // Can upgrade if monthly is active
        let monthlyProducts = purchaseManager.getSubscriptionProducts().filter { $0.id.contains("monthly") }
        return monthlyProducts.contains { purchaseManager.isProductPurchased($0.id) }
    }
    
    func getUpgradeMessage() -> String {
        if canUpgradeToYearly() {
            return NSLocalizedString("Nâng cấp lên gói năm để tiết kiệm hơn!", comment: "Upgrade to yearly for better savings!")
        }
        return ""
    }
} 
