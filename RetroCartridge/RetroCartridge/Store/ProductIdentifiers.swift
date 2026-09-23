// ProductIdentifiers.swift
// RetroCartridge
//
// StoreKit 2 product identifiers for In-App Purchases.

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
}
