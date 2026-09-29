// ProductIdentifiers.swift
// RetroCartridge
//
// StoreKit 2 product identifiers for In-App Purchases, plus the local
// catalog metadata the store screen falls back on when the App Store
// can't be reached.

import Foundation

/// Central registry of all IAP product identifiers.
enum ProductIdentifiers {
    /// Retro Collector Pack — $6.99
    /// Unlocks: six skins (every one but Gold Edition) and the Pocket,
    ///          Arcade and Mellow sound packs
    static let retroCollectorPack = "com.retrocartridge.collector_pack"

    /// Lifetime Pro — $49.99
    /// Unlocks: everything in the Collector Pack, the Gold Edition skin,
    ///          every screen mode and screen tuning, and all future content
    static let lifetimePro = "com.retrocartridge.lifetime_pro"

    /// All purchasable product IDs.
    static let allProductIDs: Set<String> = [
        retroCollectorPack,
        lifetimePro
    ]

    /// The order products are listed in the store.
    static let displayOrder: [String] = [
        retroCollectorPack,
        lifetimePro
    ]

    // MARK: - Fallback catalog

    /// Name shown when the StoreKit product couldn't be loaded.
    static func fallbackDisplayName(for productID: String) -> String {
        switch productID {
        case retroCollectorPack: return "Retro Collector Pack"
        case lifetimePro: return "Lifetime Pro"
        default: return productID
        }
    }

    /// Price shown when the StoreKit product couldn't be loaded.
    static func fallbackDisplayPrice(for productID: String) -> String {
        switch productID {
        case retroCollectorPack: return "$6.99"
        case lifetimePro: return "$49.99"
        default: return "—"
        }
    }

    /// The console skins a product unlocks.
    static func skins(unlockedBy productID: String) -> [ConsoleSkinType] {
        switch productID {
        case retroCollectorPack:
            return ConsoleSkinType.allCases.filter { $0.requiredProductID == retroCollectorPack }
        case lifetimePro:
            return ConsoleSkinType.allCases.filter { !$0.isFree }
        default:
            return []
        }
    }
}
