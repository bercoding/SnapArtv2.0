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
    
    // Product IDs
    private let productIDs = [
        "com.snapart.premium"           // Non-consumable
    ]
    
    private let subscriptionIDs = [
        "com.snapart.premium.monthly",  // Monthly subscription
        "com.snapart.premium.yearly"    // Yearly subscription
    ]
    
    // StoreKit listeners
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
            print("✅ Loaded \(products.count) products")
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            print("❌ Failed to load products: \(error)")
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
            await handlePurchaseResult(verification, for: product)
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
        
        try await AppStore.sync()
        await updateSubscriptionStatus()
        print("✅ Purchases restored successfully")
    }
    
    // MARK: - Subscription Management
    
    func updateSubscriptionStatus() async {
        for await result in Transaction.currentEntitlements {
            if let transaction = try? result.payloadValue {
                await handleTransaction(transaction)
            }
        }
    }
    
    private func handleTransaction(_ transaction: Transaction) async {
        let productID = transaction.productID
        
        // Check if this is a subscription product
        if let product = getProduct(by: productID), product.subscription != nil {
            // Handle subscription
            if transaction.revocationDate == nil {
                // Active subscription
                subscriptionStatus = .active
                purchasedProductIDs.insert(productID)
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
    
    private func handlePurchaseResult(_ verification: VerificationResult<Transaction>, for product: Product) async {
        guard let transaction = try? verification.payloadValue else {
            errorMessage = "Transaction verification failed"
            return
        }
        
        await handleTransaction(transaction)
        
        // Check if this is a subscription product
        if product.subscription != nil {
            subscriptionStatus = .active
        }
        
        print("✅ Purchase successful: \(product.id)")
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
    
    var errorDescription: String? {
        switch self {
        case .userCancelled:
            return NSLocalizedString("Purchase was cancelled", comment: "Purchase cancelled")
        case .pending:
            return NSLocalizedString("Purchase is pending", comment: "Purchase pending")
        case .unknown:
            return NSLocalizedString("An unknown error occurred", comment: "Unknown error")
        }
    }
} 
