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
    /// Unlocks: Atomic Purple, Cyberpunk Neon, 90's Arcade skins
    ///          + 3 custom 8-bit sound packs + custom cartridge designs
    static let retroCollectorPack = "com.retrocartridge.collector_pack"

    /// Lifetime Pro — $49.99
    /// Unlocks: All current + future content, Apple Pencil cartridge designer,
    ///          custom CRT shader settings, all future games
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
