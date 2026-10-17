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
    /// Unlocks: six skins (every one but Gold Edition), the Maze Muncher and
    ///          Frog Hop cartridges, and the Pocket, Arcade and Mellow sound packs
    static let retroCollectorPack = "com.foldcade.collector_pack"

    /// Lifetime Pro — $49.99
    /// Unlocks: everything in the Collector Pack, the Lunar Hinge cartridge,
    ///          the Gold Edition skin, every screen mode and screen tuning,
    ///          and all future content
    static let lifetimePro = "com.foldcade.lifetime_pro"

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

    /// Name shown when the StoreKit product couldn't be loaded, and spoken
    /// by VoiceOver.
    static func fallbackDisplayName(for productID: String) -> String {
        switch productID {
        case retroCollectorPack: return "Retro Collector Pack"
        case lifetimePro: return "Lifetime Pro"
        default: return productID
        }
    }

    /// Short uppercase name for lock labels, e.g. "COLLECTOR PACK".
    static func shortName(for productID: String) -> String {
        switch productID {
        case retroCollectorPack: return String(localized: "COLLECTOR PACK")
        case lifetimePro: return String(localized: "LIFETIME PRO")
        default: return fallbackDisplayName(for: productID).uppercased()
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

    // MARK: - Contents

    // Everything below is derived from each item's own `requiredProductID`,
    // so the store always lists exactly what a purchase opens.

    /// Whether buying a product unlocks an item that requires `required`.
    /// Lifetime Pro includes everything paid.
    static func unlocks(_ productID: String, itemRequiring required: String?) -> Bool {
        guard let required else { return false }
        return required == productID || productID == lifetimePro
    }

    /// The console skins a product unlocks.
    static func skins(unlockedBy productID: String) -> [ConsoleSkinType] {
        ConsoleSkinType.allCases.filter { unlocks(productID, itemRequiring: $0.requiredProductID) }
    }

    /// The cartridges a product unlocks.
    static func cartridges(unlockedBy productID: String) -> [GameType] {
        GameType.allCases.filter { unlocks(productID, itemRequiring: $0.info.requiredProductID) }
    }

    /// The sound packs a product unlocks.
    static func soundPacks(unlockedBy productID: String) -> [SoundPack] {
        SoundPack.allCases.filter { unlocks(productID, itemRequiring: $0.requiredProductID) }
    }

    /// The screen modes a product unlocks.
    static func screenModes(unlockedBy productID: String) -> [ScreenMode] {
        ScreenMode.allCases.filter { unlocks(productID, itemRequiring: $0.requiredProductID) }
    }

    /// Whether a product unlocks screen tuning.
    static func unlocksScreenTuning(_ productID: String) -> Bool {
        productID == lifetimePro
    }

    /// One sentence on what a product unlocks, written from its contents.
    static func summary(for productID: String) -> String {
        if productID == lifetimePro {
            // What Pro adds on top of the Collector Pack
            let collector = retroCollectorPack
            let exclusiveCartridges = cartridges(unlockedBy: productID)
                .filter { !unlocks(collector, itemRequiring: $0.info.requiredProductID) }
            let exclusiveSkins = skins(unlockedBy: productID)
                .filter { !unlocks(collector, itemRequiring: $0.requiredProductID) }
            let modeCount = screenModes(unlockedBy: productID).count

            var parts = exclusiveCartridges.map(\.rawValue)
            parts += exclusiveSkins.map { String(localized: "the \($0.rawValue) skin") }
            if modeCount > 0 {
                parts.append(String(localized: "\(modeCount) screen modes with tuning"))
            }
            parts.append(String(localized: "all future content"))
            return String(localized: "Everything in the Collector Pack, plus \(list(parts)).")
        }

        var parts: [String] = []
        let skinCount = skins(unlockedBy: productID).count
        let cartridgeCount = cartridges(unlockedBy: productID).count
        let packCount = soundPacks(unlockedBy: productID).count
        if skinCount > 0 { parts.append(String(localized: "\(skinCount) skins")) }
        if cartridgeCount > 0 { parts.append(String(localized: "\(cartridgeCount) cartridges")) }
        if packCount > 0 { parts.append(String(localized: "\(packCount) sound packs")) }
        return parts.isEmpty ? "" : String(localized: "\(list(parts)).", comment: "A product summary sentence")
    }

    /// "a", "a and b", "a, b and c".
    private static func list(_ items: [String]) -> String {
        guard items.count > 1 else { return items.first ?? "" }
        let and = String(localized: " and ", comment: "Joins the last two items of a list, with spaces")
        return items.dropLast().joined(separator: ", ") + and + items[items.count - 1]
    }
}
