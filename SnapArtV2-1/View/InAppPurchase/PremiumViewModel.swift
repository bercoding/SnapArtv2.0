import Foundation
import StoreKit
import SwiftUI
import Combine

@MainActor
class PremiumViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var selectedPlan: String = "monthly"
    @Published var isPurchasing = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var purchaseSuccess = false
    
    // Đổi từ private thành internal để có thể truy cập từ PremiumView
    let purchaseManager: InAppPurchaseManager
    private var cancellables = Set<AnyCancellable>()
    
    init(purchaseManager: InAppPurchaseManager) {
        self.purchaseManager = purchaseManager
        setupBindings()
    }
    
    private func setupBindings() {
        purchaseManager.$errorMessage
            .compactMap { $0 }
            .sink { [weak self] message in
                self?.showAlert = true
                self?.alertTitle = "Lỗi"
                self?.alertMessage = message
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Computed Properties
    
    var products: [Product] {
        purchaseManager.products
    }
    
    var monthlyProducts: [Product] {
        purchaseManager.getSubscriptionProducts().filter { $0.id.contains("monthly") }
    }
    
    var yearlyProducts: [Product] {
        purchaseManager.getSubscriptionProducts().filter { $0.id.contains("yearly") }
    }
    
    var nonConsumableProducts: [Product] {
        purchaseManager.getNonConsumableProducts()
    }
    
    // MARK: - Helper Methods
    
    func isProductPurchased(_ productID: String) -> Bool {
        return purchaseManager.isProductPurchased(productID)
    }
    
    func hasIntroductoryOffer(for product: Product) -> Bool {
        return purchaseManager.hasIntroductoryOffer(for: product)
    }
    
    func formatPrice(_ product: Product) -> String {
        return product.displayPrice
    }
    
    func formatSubscriptionPeriod(_ product: Product) -> String {
        guard let subscription = product.subscription else {
            return ""
        }
        
        let unit = subscription.subscriptionPeriod.unit
        let value = subscription.subscriptionPeriod.value
        
        switch unit {
        case .day:
            return "\(value) ngày"
        case .week:
            return "\(value) tuần"
        case .month:
            return "\(value) tháng"
        case .year:
            return "\(value) năm"
        @unknown default:
            return ""
        }
    }
    
    func purchaseProduct(_ product: Product) {
        Task {
            isPurchasing = true
            
            do {
                try await purchaseManager.purchase(product)
                
                isPurchasing = false
                purchaseSuccess = true
                
                // Cập nhật trạng thái premium cho người dùng
                updateUserPremiumStatus()
                
                // Gửi thông báo rằng trạng thái premium đã thay đổi
                NotificationCenter.default.post(name: .premiumStatusChanged, object: nil)
                
                // Hiển thị thông báo thành công
                showAlert = true
                alertTitle = "Thành công"
                alertMessage = "Bạn đã mua gói Premium thành công!"
            } catch {
                isPurchasing = false
                showError = true
                errorMessage = error.localizedDescription
                
                showAlert = true
                alertTitle = "Lỗi"
                alertMessage = "Không thể hoàn tất giao dịch: \(error.localizedDescription)"
            }
        }
    }
    
    func purchaseSubscription(_ product: Product) {
        Task {
            isPurchasing = true
            
            do {
                try await purchaseManager.purchaseSubscription(product)
                
                isPurchasing = false
                purchaseSuccess = true
                
                // Cập nhật trạng thái premium cho người dùng
                updateUserPremiumStatus()
                
                // Gửi thông báo rằng trạng thái premium đã thay đổi
                NotificationCenter.default.post(name: .premiumStatusChanged, object: nil)
                
                // Hiển thị thông báo thành công
                showAlert = true
                alertTitle = "Thành công"
                alertMessage = "Bạn đã đăng ký gói Premium thành công!"
            } catch {
                isPurchasing = false
                showError = true
                errorMessage = error.localizedDescription
                
                showAlert = true
                alertTitle = "Lỗi"
                alertMessage = "Không thể hoàn tất đăng ký: \(error.localizedDescription)"
            }
        }
    }
    
    func restorePurchases() {
        Task {
            isLoading = true
            
            do {
                try await purchaseManager.restorePurchases()
                
                isLoading = false
                
                // Kiểm tra xem có khôi phục được gì không
                if purchaseManager.isSubscriptionActive() || !purchaseManager.currentEntitlements.isEmpty {
                    purchaseSuccess = true
                    
                    // Cập nhật trạng thái premium cho người dùng
                    updateUserPremiumStatus()
                    
                    // Gửi thông báo rằng trạng thái premium đã thay đổi
                    NotificationCenter.default.post(name: .premiumStatusChanged, object: nil)
                    
                    // Hiển thị thông báo thành công
                    showAlert = true
                    alertTitle = "Thành công"
                    alertMessage = "Đã khôi phục gói Premium của bạn!"
                } else {
                    showAlert = true
                    alertTitle = "Thông báo"
                    alertMessage = "Không tìm thấy gói Premium nào đã mua trước đây."
                }
            } catch {
                isLoading = false
                showAlert = true
                alertTitle = "Lỗi"
                alertMessage = "Không thể khôi phục giao dịch: \(error.localizedDescription)"
            }
        }
    }
    
    // Cập nhật trạng thái premium cho người dùng hiện tại
    private func updateUserPremiumStatus() {
        Task {
            do {
                if let userId = UserProfileManager.shared.currentUser?.id {
                    try await UserProfileManager.shared.updatePremiumStatus(true)
                }
            } catch {
                print("Failed to update premium status: \(error.localizedDescription)")
            }
        }
    }
} 
