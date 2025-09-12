import Foundation
import StoreKit
import Combine

@MainActor
class InAppPurchaseManager: ObservableObject {
    static let shared = InAppPurchaseManager()
    
    // Published properties
    @Published var products: [Product] = []
    @Published var purchasedProductIDs = Set<String>()
    @Published var subscriptionStatus: SubscriptionStatus = .none
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentEntitlements: [Product] = []
    
    // Product IDs
    private let productIDs = [
        "com.snapart.premium"           // Non-consumable
    ]
    
    private let subscriptionIDs = [
        "com.snapart.premium.monthly",  // Monthly subscription
        "com.snapart.premium.yearly"    // Yearly subscription
    ]
    
    // StoreKit 2 listeners
    private var updateListenerTask: Task<Void, Error>?
    private var transactionListener: Task<Void, Error>?
    
    private init() {
        updateListenerTask = listenForTransactions()
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
        transactionListener?.cancel()
    }
    
    // MARK: - Product Loading
    
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let allProductIDs = productIDs + subscriptionIDs
            products = try await Product.products(for: allProductIDs)
            
            // Update current entitlements
            await updateCurrentEntitlements()
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Purchase Methods
    
    func purchase(_ product: Product) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            // Handle successful purchase
            await handlePurchaseResult(verification)
        case .userCancelled:
            throw InAppPurchaseError.userCancelled
        case .pending:
            throw InAppPurchaseError.pending
        @unknown default:
            throw InAppPurchaseError.unknown
        }
    }
    
    func purchaseSubscription(_ product: Product) async throws {    
        guard product.subscription != nil else {
            throw InAppPurchaseError.invalidProduct
        }
        
        isLoading = true
        defer { isLoading = false }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            await handlePurchaseResult(verification)
        case .userCancelled:
            throw InAppPurchaseError.userCancelled
        case .pending:
            throw InAppPurchaseError.pending
        @unknown default:
            throw InAppPurchaseError.unknown
        }
    }
        func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Sync với App Store
            try await AppStore.sync()
            
            // Update subscription status
            await updateSubscriptionStatus()
            
            // Update current entitlements
            await updateCurrentEntitlements()
            
            // Force refresh products
            await loadProducts()
            
            // Log để debug
            print("Restore completed. Active subscriptions: \(purchasedProductIDs)")
            print("Subscription status: \(subscriptionStatus)")
            
        } catch {
            print("Restore failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - App Launch Restore
    
    func restoreOnAppLaunch() async {
        do {
            try await restorePurchases()
        } catch {
            print("App launch restore failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Subscription Management
    
    func updateSubscriptionStatus() async {
        for await result in Transaction.currentEntitlements {
            if let transaction = try? result.payloadValue {
                await handleTransaction(transaction)
            }
        }
    }
    
    private func updateCurrentEntitlements() async {
        var entitlements: [Product] = []
        
        print("🔍 Checking current entitlements...")
        
        for await result in Transaction.currentEntitlements {
            if let transaction = try? result.payloadValue {
                print("📦 Found transaction: \(transaction.productID)")
                if let product = getProduct(by: transaction.productID) {
                    entitlements.append(product)
                    print("✅ Added product to entitlements: \(product.id)")
                } else {
                    print("❌ Product not found for transaction: \(transaction.productID)")
                }
            } else {
                print("❌ Failed to verify transaction")
            }
        }
        
        currentEntitlements = entitlements
        print("📊 Total entitlements: \(entitlements.count)")
        await updateSubscriptionStatus()
    }
    
    private func handleTransaction(_ transaction: Transaction) async {
        let productID = transaction.productID
        
        // Check if this is a subscription product
        if let product = getProduct(by: productID), product.subscription != nil {
            // Handle subscription
            if transaction.revocationDate == nil {
                // Active subscription - check if it's a higher tier
                await handleActiveSubscription(product)
            } else {
                // Subscription revoked
                subscriptionStatus = .expired
                purchasedProductIDs.remove(productID)
            }
        } else {
            // Handle non-consumable purchase
            if transaction.revocationDate == nil {
                purchasedProductIDs.insert(productID)
            } else {
                purchasedProductIDs.remove(productID)
            }
        }
        
        // Always finish the transaction
        await transaction.finish()
    }
    
    private func handleActiveSubscription(_ product: Product) async {
        // Check if this is a higher tier subscription
        let isYearly = product.id.contains("yearly")
        let isMonthly = product.id.contains("monthly")
        
        if isYearly {
            // Yearly subscription is highest tier - activate immediately
            subscriptionStatus = .active
            purchasedProductIDs.insert(product.id)
            
            // Remove any monthly subscription from purchased list
            let monthlyProducts = getSubscriptionProducts().filter { $0.id.contains("monthly") }
            for monthlyProduct in monthlyProducts {
                purchasedProductIDs.remove(monthlyProduct.id)
            }
        } else if isMonthly {
            // Monthly subscription - check if we already have yearly
            let yearlyProducts = getSubscriptionProducts().filter { $0.id.contains("yearly") }
            let hasYearly = yearlyProducts.contains { purchasedProductIDs.contains($0.id) }
            
            if !hasYearly {
                // Only activate monthly if no yearly exists
                subscriptionStatus = .active
                purchasedProductIDs.insert(product.id)
            }
        }
    }
    
    private func handlePurchaseResult(_ verification: VerificationResult<Transaction>) async {
        guard let transaction = try? verification.payloadValue else {
            errorMessage = "Transaction verification failed"
            return
        }
        
        await handleTransaction(transaction)
        
        // Update entitlements
        await updateCurrentEntitlements()
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                if let transaction = try? result.payloadValue {
                    await self.handleTransaction(transaction)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    func isProductPurchased(_ productID: String) -> Bool {
        return purchasedProductIDs.contains(productID)
    }
    
    func isSubscriptionActive() -> Bool {
        return subscriptionStatus == .active
    }
    
    func getProduct(by id: String) -> Product? {
        return products.first { $0.id == id }
    }
    
    func getSubscriptionProducts() -> [Product] {
        return products.filter { $0.subscription != nil }
    }
    
    func getNonConsumableProducts() -> [Product] {
        return products.filter { $0.subscription == nil }
    }
    
    // Helper method to check if product is subscription
    func isSubscription(_ product: Product) -> Bool {
        return product.subscription != nil
    }
    
    // Helper method to check if product is non-consumable
    func isNonConsumable(_ product: Product) -> Bool {
        return product.subscription == nil
    }
    
    // MARK: - Subscription Info
    
    func getSubscriptionInfo(for product: Product) -> Product.SubscriptionInfo? {
        return product.subscription
    }
    
    func getSubscriptionPeriod(for product: Product) -> String {
        guard let subscription = product.subscription else { return "" }
        
        let period = subscription.subscriptionPeriod
        switch period.unit {
        case .day:
            return "\(period.value) ngày"
        case .week:
            return "\(period.value) tuần"
        case .month:
            return "\(period.value) tháng"
        case .year:
            return "\(period.value) năm"
        @unknown default:
            return "\(period.value) \(period.unit)"
        }
    }
    
    func hasIntroductoryOffer(for product: Product) -> Bool {
        return product.subscription?.introductoryOffer != nil
    }
    
    func getIntroductoryOffer(for product: Product) -> Product.SubscriptionOffer? {
        return product.subscription?.introductoryOffer
    }
    
    // MARK: - Verification
    
    func verifyPurchase(_ verification: VerificationResult<Transaction>) -> Bool {
        switch verification {
        case .verified:
            return true
        case .unverified:
            return false
        }
    }
}

// MARK: - Enums

enum SubscriptionStatus {
    case none
    case active
    case expired
    case trial
}

enum InAppPurchaseError: LocalizedError {
    case userCancelled
    case pending
    case unknown
    case invalidProduct
    case verificationFailed
    
    var errorDescription: String? {
        switch self {
        case .userCancelled:
            return NSLocalizedString("Purchase was cancelled", comment: "Purchase cancelled")
        case .pending:
            return NSLocalizedString("Purchase is pending", comment: "Purchase pending")
        case .unknown:
            return NSLocalizedString("An unknown error occurred", comment: "Unknown error")
        case .invalidProduct:
            return NSLocalizedString("Invalid product", comment: "Invalid product")
        case .verificationFailed:
            return NSLocalizedString("Purchase verification failed", comment: "Verification failed")
        }
    }
} 
