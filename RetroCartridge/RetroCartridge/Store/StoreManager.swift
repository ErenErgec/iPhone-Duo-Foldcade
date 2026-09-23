//
//  StoreManager.swift
//  RetroCartridge
//
//  Created by AI on 2026-09-22.
//

import Foundation
import StoreKit
import SwiftUI

@MainActor
@Observable
final class StoreManager {
    var products: [Product] = []
    var purchasedProductIDs: Set<String> = []
    var isLoading: Bool = false
    var errorMessage: String?

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
    
    @MainActor
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        do {
            products = try await Product.products(for: ProductIdentifiers.allProductIDs)
            await updatePurchasedProducts()
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    @MainActor
    func purchase(_ product: Product) async throws {
        isLoading = true
        let result = try await product.purchase()
        switch result {
        case .success(let verificationResult):
            await handle(transactionResult: verificationResult)
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
        isLoading = false
    }
    
    @MainActor
    func restorePurchases() async {
        isLoading = true
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
        } catch {
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
        }
        isLoading = false
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
    
    @MainActor
    private func updatePurchasedProducts() async {
        for await result in StoreKit.Transaction.currentEntitlements {
            await handle(transactionResult: result)
        }
    }
    
    @MainActor
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
