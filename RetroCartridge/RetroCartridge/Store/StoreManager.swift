//
//  StoreManager.swift
//  RetroCartridge
//

import Foundation
import StoreKit
import SwiftUI

@MainActor
@Observable
final class StoreManager {
    var products: [Product] = []
    var purchasedProductIDs: Set<String> = []

    /// True while products are loading or purchases are being restored.
    var isLoading: Bool = false

    /// The product whose purchase is in flight, if any.
    var purchasingProductID: String?

    /// True while `restorePurchases()` runs.
    var isRestoring: Bool = false

    /// Purchase / restore failures, shown inline by the store screen.
    var errorMessage: String?

    /// Why the last product load came back empty (nil when products loaded).
    var productLoadError: String?

    /// Whether `loadProducts()` has finished at least once.
    var hasAttemptedProductLoad: Bool = false

    init() {
        Task { [weak self] in
            for await result in StoreKit.Transaction.updates {
                await self?.handle(transactionResult: result)
            }
        }
    }

    var hasLifetimePro: Bool {
        return purchasedProductIDs.contains(ProductIdentifiers.lifetimePro)
    }

    /// Products loaded, but none came back (offline, or IDs unknown to the store).
    var productsUnavailable: Bool {
        hasAttemptedProductLoad && !isLoading && products.isEmpty
    }

    func product(for productID: String) -> Product? {
        products.first { $0.id == productID }
    }

    func loadProducts() async {
        guard !isLoading else { return }
        isLoading = true
        productLoadError = nil
        defer {
            isLoading = false
            hasAttemptedProductLoad = true
        }

        do {
            let loaded = try await Product.products(for: ProductIdentifiers.allProductIDs)
            products = loaded.sorted {
                (ProductIdentifiers.displayOrder.firstIndex(of: $0.id) ?? .max)
                    < (ProductIdentifiers.displayOrder.firstIndex(of: $1.id) ?? .max)
            }
            if loaded.isEmpty {
                productLoadError = "The App Store didn't return any products."
            }
        } catch {
            productLoadError = error.localizedDescription
        }

        // Entitlements are cached on device, so refresh them even when offline.
        await updatePurchasedProducts()
    }

    func purchase(_ product: Product) async {
        guard purchasingProductID == nil else { return }
        purchasingProductID = product.id
        errorMessage = nil
        defer { purchasingProductID = nil }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verificationResult):
                if case .unverified = verificationResult {
                    errorMessage = "The purchase couldn't be verified."
                }
                await handle(transactionResult: verificationResult)
            case .pending:
                errorMessage = "Purchase pending approval. It will unlock once approved."
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
        }
    }

    func restorePurchases() async {
        guard !isRestoring else { return }
        isRestoring = true
        errorMessage = nil
        defer { isRestoring = false }

        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
        } catch {
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
        }
    }

    func isPurchased(_ productID: String) -> Bool {
        return purchasedProductIDs.contains(productID)
    }

    func isUnlocked(_ skinType: ConsoleSkinType) -> Bool {
        switch skinType {
        case .classicGrey:
            return true // Free default skin
        case .atomicPurple, .cyberpunkNeon, .arcadeCabinet:
            return hasLifetimePro || isPurchased(ProductIdentifiers.retroCollectorPack)
        }
    }

    /// Rebuilds the owned set from current entitlements, so refunds and
    /// revocations drop out as well.
    private func updatePurchasedProducts() async {
        var owned: Set<String> = []
        for await result in StoreKit.Transaction.currentEntitlements {
            if case .verified(let transaction) = result, transaction.revocationDate == nil {
                owned.insert(transaction.productID)
            }
        }
        purchasedProductIDs = owned
    }

    private func handle(transactionResult result: VerificationResult<StoreKit.Transaction>) async {
        guard case .verified(let transaction) = result else {
            return // Ignore unverified transactions
        }

        if transaction.revocationDate == nil {
            purchasedProductIDs.insert(transaction.productID)
        } else {
            purchasedProductIDs.remove(transaction.productID)
        }

        await transaction.finish()
    }
}
