//
// StoreView.swift
// RetroCartridge
//
// In-hierarchy store overlay: both non-consumables with their App Store
// prices, what each unlocks, Buy / Restore, and inline errors. When the App
// Store can't be reached it falls back to the catalog prices in
// `ProductIdentifiers` and offers a retry. Hosted by `FullScreenLayout`
// (never as a sheet); only StoreKit's own confirmation sheet is system UI.
//

import StoreKit
import SwiftUI

struct StoreView: View {
    @Environment(AppState.self) private var appState
    @Environment(StoreManager.self) private var storeManager
    @Environment(HapticManager.self) private var hapticManager

    /// Feedback shown under Restore Purchases after it completes.
    @State private var restoreNote: String?

    var body: some View {
        OverlayPanel(
            title: "CARTRIDGE SHOP",
            subtitle: "CARTRIDGES, SKINS & UPGRADES",
            onClose: close
        ) {
            VStack(spacing: 16) {
                if storeManager.productsUnavailable {
                    offlineBanner
                        .transition(.opacity)
                }

                if let message = storeManager.errorMessage {
                    errorBanner(message)
                        .transition(.opacity)
                }

                ForEach(ProductIdentifiers.displayOrder, id: \.self) { productID in
                    productCard(productID)
                }

                restoreSection
                    .padding(.top, 4)
            }
            .animation(.easeInOut(duration: 0.2), value: storeManager.productsUnavailable)
            .animation(.easeInOut(duration: 0.2), value: storeManager.errorMessage)
        }
        .task {
            if storeManager.products.isEmpty {
                await storeManager.loadProducts()
            }
        }
    }

    private func close() {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
            appState.isStoreVisible = false
            appState.storeHighlight = nil
        }
    }

    // MARK: - Banners

    private var offlineBanner: some View {
        banner(
            icon: "wifi.exclamationmark",
            tint: RetroPalette.amber,
            title: String(localized: "APP STORE UNAVAILABLE"),
            message: String(localized: "Showing standard prices. Check your connection and try again.")
        ) {
            Button {
                Task { await storeManager.loadProducts() }
            } label: {
                if storeManager.isLoading {
                    ProgressView()
                        .tint(RetroPalette.amber)
                        .frame(width: 76, height: 34)
                } else {
                    RetroCapsuleLabel(title: String(localized: "RETRY"), systemImage: "arrow.clockwise", tint: RetroPalette.amber)
                }
            }
            .buttonStyle(CartridgePressStyle())
            .disabled(storeManager.isLoading)
        }
    }

    private func errorBanner(_ message: String) -> some View {
        banner(
            icon: "exclamationmark.triangle.fill",
            tint: RetroPalette.alert,
            title: String(localized: "SOMETHING WENT WRONG"),
            message: message
        ) {
            Button {
                storeManager.errorMessage = nil
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(RetroPalette.alert)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(RetroPalette.alert.opacity(0.1)))
                    .contentShape(Circle())
            }
            .buttonStyle(CartridgePressStyle())
            .accessibilityLabel("Dismiss error")
        }
    }

    private func banner<Accessory: View>(
        icon: String,
        tint: Color,
        title: String,
        message: String,
        @ViewBuilder accessory: () -> Accessory
    ) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .heavy, design: .monospaced))
                    .tracking(1.5)
                    .foregroundStyle(tint)
                Text(message)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.65))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            accessory()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(tint.opacity(0.07)))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(tint.opacity(0.3), lineWidth: 1))
    }

    // MARK: - Products

    private func productCard(_ productID: String) -> some View {
        let product = storeManager.product(for: productID)
        let isPro = productID == ProductIdentifiers.lifetimePro
        let tint = isPro ? Color(hex: "#FFD54F") : Color(hex: "#B266FF")
        let isHighlighted = appState.storeHighlight == productID

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 16) {
                ProductCartridgeBadge(
                    tint: tint,
                    symbol: isPro ? "crown.fill" : "paintpalette.fill"
                )
                .frame(width: 58)

                VStack(alignment: .leading, spacing: 6) {
                    // Product names are English in every language, so they're
                    // uppercased by English rules ("LIFETIME", not "LİFETİME").
                    Text((product?.displayName ?? ProductIdentifiers.fallbackDisplayName(for: productID)).uppercased())
                        .font(.system(size: 16, weight: .black, design: .monospaced))
                        .tracking(1.5)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    if isHighlighted {
                        Label("UNLOCKS WHAT YOU TAPPED", systemImage: "arrow.down.circle.fill")
                            .font(.system(size: 10, weight: .heavy, design: .monospaced))
                            .tracking(1)
                            .foregroundStyle(tint)
                            .labelStyle(.titleAndIcon)
                    }

                    Text(ProductIdentifiers.summary(for: productID))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.55))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                buyButton(productID: productID, product: product, tint: tint)
            }

            unlocks(productID: productID, isPro: isPro, tint: tint)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [tint.opacity(0.1), Color.white.opacity(0.02)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(tint.opacity(isHighlighted ? 0.9 : 0.28), lineWidth: isHighlighted ? 2 : 1)
        )
        .shadow(color: isHighlighted ? tint.opacity(0.3) : .clear, radius: 14)
    }

    /// What a product unlocks, listed from the items' own gating. Pro lists
    /// only what it adds to the Collector Pack.
    private func unlocks(productID: String, isPro: Bool, tint: Color) -> some View {
        let collector = ProductIdentifiers.retroCollectorPack
        let cartridges = ProductIdentifiers.cartridges(unlockedBy: productID)
            .filter { !isPro || !ProductIdentifiers.unlocks(collector, itemRequiring: $0.info.requiredProductID) }
        let skins = ProductIdentifiers.skins(unlockedBy: productID)
            .filter { !isPro || !ProductIdentifiers.unlocks(collector, itemRequiring: $0.requiredProductID) }
        let soundPacks = isPro ? [] : ProductIdentifiers.soundPacks(unlockedBy: productID)
        let screenModes = ProductIdentifiers.screenModes(unlockedBy: productID)

        return VStack(alignment: .leading, spacing: 12) {
            if isPro {
                perk("EVERYTHING IN THE COLLECTOR PACK")
            }

            if !cartridges.isEmpty {
                section("CARTRIDGES", tint: tint) {
                    ForEach(cartridges) { game in
                        VStack(spacing: 6) {
                            CartridgeView(game: game)
                                .frame(width: 52)
                            itemName(game.rawValue)
                        }
                        .frame(width: 84)
                    }
                }
            }

            if !skins.isEmpty {
                section("SKINS", tint: tint) {
                    ForEach(skins) { skin in
                        VStack(spacing: 6) {
                            ConsoleSkinPreview(theme: SkinManager.theme(for: skin))
                                .frame(height: 64)
                            itemName(skin.rawValue)
                        }
                        .frame(width: 84)
                    }
                }
            }

            if !soundPacks.isEmpty {
                section("SOUND PACKS", tint: tint) {
                    ForEach(soundPacks) { pack in
                        RetroCapsuleLabel(title: pack.title.localizedUppercase, systemImage: "speaker.wave.2.fill", tint: tint)
                    }
                }
            }

            if !screenModes.isEmpty {
                section("SCREEN MODES", tint: tint) {
                    ForEach(screenModes) { mode in
                        RetroCapsuleLabel(title: mode.title.localizedUppercase, systemImage: "tv", tint: tint)
                    }
                    if ProductIdentifiers.unlocksScreenTuning(productID) {
                        RetroCapsuleLabel(title: String(localized: "TUNING"), systemImage: "slider.horizontal.3", tint: tint)
                    }
                }
            }

            if isPro {
                VStack(alignment: .leading, spacing: 6) {
                    perk("ALL FUTURE SKINS & CARTRIDGES")
                    perk("ONE-TIME PURCHASE")
                }
            }
        }
    }

    /// A titled row of unlocked items that scrolls when it doesn't fit.
    private func section<Items: View>(_ title: LocalizedStringKey, tint: Color, @ViewBuilder items: () -> Items) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                .tracking(2.5)
                .foregroundStyle(tint.opacity(0.85))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 10) {
                    items()
                }
            }
        }
    }

    private func itemName(_ name: String) -> some View {
        Text(name.uppercased())
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundStyle(.white.opacity(0.6))
            .lineLimit(2)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func perk(_ text: LocalizedStringKey) -> some View {
        Label(text, systemImage: "plus")
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundStyle(.white.opacity(0.7))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }

    @ViewBuilder
    private func buyButton(productID: String, product: Product?, tint: Color) -> some View {
        let isOwned = storeManager.isPurchased(productID)
        let isIncluded = !isOwned && productID == ProductIdentifiers.retroCollectorPack && storeManager.hasLifetimePro
        let isPurchasing = storeManager.purchasingProductID == productID
        let price = product?.displayPrice ?? ProductIdentifiers.fallbackDisplayPrice(for: productID)

        if isOwned {
            RetroCapsuleLabel(title: String(localized: "OWNED"), systemImage: "checkmark", tint: RetroPalette.phosphor)
                .accessibilityLabel("Purchased")
        } else if isIncluded {
            RetroCapsuleLabel(title: String(localized: "IN PRO"), systemImage: "checkmark", tint: RetroPalette.phosphor)
                .accessibilityLabel("Included with Lifetime Pro")
        } else if isPurchasing {
            ProgressView()
                .tint(.black)
                .frame(width: 96, height: 36)
                .background(Capsule().fill(RetroPalette.phosphor))
                .accessibilityLabel("Purchasing")
        } else if let product {
            Button {
                hapticManager.playHaptic(.buttonPress)
                Task { await storeManager.purchase(product) }
            } label: {
                RetroCapsuleLabel(title: String(localized: "BUY \(price)"), tint: RetroPalette.phosphor, filled: true)
                    .frame(minWidth: 96)
            }
            .buttonStyle(CartridgePressStyle())
            .disabled(storeManager.purchasingProductID != nil)
            .opacity(storeManager.purchasingProductID != nil ? 0.5 : 1)
            .accessibilityLabel("Buy \(product.displayName) for \(price)")
        } else if !storeManager.hasAttemptedProductLoad || storeManager.isLoading {
            // Still asking the App Store: show the catalog price with a spinner.
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                    .tint(.white)
                Text(price)
                    .font(.system(size: 12, weight: .heavy, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .frame(minWidth: 96, minHeight: 36)
        } else {
            // App Store unreachable: show the catalog price, not purchasable.
            RetroCapsuleLabel(title: price, tint: .white.opacity(0.4))
                .frame(minWidth: 96)
                .accessibilityLabel("\(price), unavailable")
        }
    }

    // MARK: - Restore

    private var restoreSection: some View {
        VStack(spacing: 10) {
            Button {
                Task { await restore() }
            } label: {
                HStack(spacing: 8) {
                    if storeManager.isRestoring {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 12, weight: .heavy))
                    }
                    Text("RESTORE PURCHASES")
                        .font(.system(size: 12, weight: .heavy, design: .monospaced))
                        .tracking(2)
                }
                .foregroundStyle(.white.opacity(0.8))
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.white.opacity(0.06)))
                .overlay(Capsule().stroke(Color.white.opacity(0.14), lineWidth: 1))
            }
            .buttonStyle(CartridgePressStyle())
            .disabled(storeManager.isRestoring)

            Text(restoreNote ?? String(localized: "One-time purchases, billed through the App Store."))
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .tracking(0.5)
                .foregroundStyle(restoreNote == nil ? .white.opacity(0.35) : RetroPalette.phosphor.opacity(0.9))
                .multilineTextAlignment(.center)
                .contentTransition(.opacity)
        }
        .frame(maxWidth: .infinity)
    }

    private func restore() async {
        restoreNote = nil
        await storeManager.restorePurchases()
        guard storeManager.errorMessage == nil else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            restoreNote = storeManager.purchasedProductIDs.isEmpty
                ? String(localized: "NO PREVIOUS PURCHASES FOUND")
                : String(localized: "PURCHASES RESTORED")
        }
    }
}

/// A small cartridge silhouette tinted for a product.
private struct ProductCartridgeBadge: View {
    let tint: Color
    let symbol: String

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width

            ZStack {
                CartridgeShape(notch: w * 0.16)
                    .fill(LinearGradient(colors: [Color(white: 0.34), Color(white: 0.22)], startPoint: .top, endPoint: .bottom))
                    .overlay(CartridgeShape(notch: w * 0.16).stroke(Color.white.opacity(0.18), lineWidth: 1))

                RoundedRectangle(cornerRadius: w * 0.08, style: .continuous)
                    .fill(LinearGradient(colors: [tint.opacity(0.85), tint], startPoint: .top, endPoint: .bottom))
                    .frame(width: w * 0.76, height: w * 0.62)
                    .overlay(
                        Image(systemName: symbol)
                            .font(.system(size: w * 0.3, weight: .bold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.3), radius: 1, y: 1)
                    )
                    .offset(y: w * 0.08)
            }
            .shadow(color: tint.opacity(0.3), radius: 10)
        }
        .aspectRatio(CartridgeView.aspectRatio, contentMode: .fit)
        .accessibilityHidden(true)
    }
}
