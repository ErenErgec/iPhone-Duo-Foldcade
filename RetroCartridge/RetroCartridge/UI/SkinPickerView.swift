//
// SkinPickerView.swift
// RetroCartridge
//
// In-hierarchy overlay listing every console skin as a miniature console.
// Tapping an unlocked skin equips it immediately; tapping a locked one opens
// the store on top. Hosted by `FullScreenLayout` (never as a sheet).
//

import SwiftUI

struct SkinPickerView: View {
    @Environment(AppState.self) private var appState
    @Environment(StoreManager.self) private var storeManager
    @Environment(HapticManager.self) private var hapticManager
    @Environment(AudioManager.self) private var audioManager

    private let columns = 2

    var body: some View {
        OverlayPanel(
            title: "CONSOLE SKINS",
            subtitle: "CHOOSE YOUR SHELL",
            onClose: close
        ) {
            VStack(spacing: 20) {
                Grid(horizontalSpacing: 16, verticalSpacing: 16) {
                    ForEach(rows, id: \.self) { row in
                        GridRow {
                            ForEach(row) { skin in
                                skinCard(skin)
                            }
                        }
                    }
                }

                if ConsoleSkinType.allCases.contains(where: { !storeManager.isUnlocked($0) }) {
                    upsell
                }
            }
        }
    }

    private var rows: [[ConsoleSkinType]] {
        let all = ConsoleSkinType.allCases
        return stride(from: 0, to: all.count, by: columns).map {
            Array(all[$0..<min($0 + columns, all.count)])
        }
    }

    // MARK: - Actions

    private func close() {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
            appState.isSkinSelectorVisible = false
        }
    }

    private func select(_ skin: ConsoleSkinType) {
        hapticManager.playHaptic(.buttonPress)

        guard storeManager.isUnlocked(skin) else {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                appState.isStoreVisible = true
            }
            return
        }

        guard skin != appState.selectedSkin else { return }
        audioManager.playCartridgeClick()
        withAnimation(.easeInOut(duration: 0.25)) {
            appState.selectedSkin = skin
        }
    }

    // MARK: - Pieces

    private func skinCard(_ skin: ConsoleSkinType) -> some View {
        let isSelected = skin == appState.selectedSkin
        let isUnlocked = storeManager.isUnlocked(skin)

        return Button {
            select(skin)
        } label: {
            VStack(spacing: 12) {
                ConsoleSkinPreview(theme: SkinManager.theme(for: skin))
                    .frame(height: 150)
                    .saturation(isUnlocked ? 1 : 0.55)
                    .overlay {
                        if !isUnlocked {
                            lockBadge
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)

                VStack(spacing: 5) {
                    Text(skin.rawValue.uppercased())
                        .font(.system(size: 13, weight: .heavy, design: .monospaced))
                        .tracking(1.5)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                    status(isSelected: isSelected, isUnlocked: isUnlocked)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(isSelected ? 0.07 : 0.035))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        isSelected ? RetroPalette.phosphor : Color.white.opacity(0.08),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(color: isSelected ? RetroPalette.phosphor.opacity(0.25) : .clear, radius: 14)
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(CartridgePressStyle())
        .accessibilityLabel(skin.rawValue)
        .accessibilityValue(isSelected ? "Equipped" : (isUnlocked ? "Unlocked" : "Locked, part of the Collector Pack"))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private func status(isSelected: Bool, isUnlocked: Bool) -> some View {
        Group {
            if isSelected {
                Label("EQUIPPED", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(RetroPalette.phosphor)
            } else if isUnlocked {
                Label("TAP TO EQUIP", systemImage: "hand.tap.fill")
                    .foregroundStyle(.white.opacity(0.45))
            } else {
                Label("COLLECTOR PACK", systemImage: "lock.fill")
                    .foregroundStyle(RetroPalette.amber)
            }
        }
        .font(.system(size: 11, weight: .bold, design: .monospaced))
        .tracking(1)
        .labelStyle(.titleAndIcon)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }

    private var lockBadge: some View {
        Image(systemName: "lock.fill")
            .font(.system(size: 20, weight: .heavy))
            .foregroundStyle(.white)
            .frame(width: 48, height: 48)
            .background(Circle().fill(Color.black.opacity(0.7)))
            .overlay(Circle().stroke(RetroPalette.amber.opacity(0.7), lineWidth: 1.5))
            .shadow(color: .black.opacity(0.5), radius: 6, y: 3)
    }

    private var upsell: some View {
        Button {
            hapticManager.playHaptic(.buttonPress)
            withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                appState.isStoreVisible = true
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(RetroPalette.amber)
                Text("UNLOCK \(ProductIdentifiers.skins(unlockedBy: ProductIdentifiers.retroCollectorPack).count) SKINS WITH THE COLLECTOR PACK")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                RetroCapsuleLabel(title: "STORE", systemImage: "bag.fill", tint: RetroPalette.phosphor, filled: true)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(RetroPalette.amber.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(RetroPalette.amber.opacity(0.25), lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(CartridgePressStyle())
    }
}
