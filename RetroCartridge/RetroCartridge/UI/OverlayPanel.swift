//
// OverlayPanel.swift
// RetroCartridge
//
// Chrome shared by the in-hierarchy overlays (skin picker, screen settings,
// records, label designer, store).
//
// These are in-hierarchy panels rather than sheets, so they keep the console's
// retro look and sit inside whichever display layout hosts them.
//

import SwiftUI

/// Shared colors for the overlay screens.
enum RetroPalette {
    /// CRT phosphor green, as used by the game screen.
    static let phosphor = Color(hex: "#9CFFB8")
    /// Warning amber for connection problems.
    static let amber = Color(hex: "#FFC857")
    /// Error red, matching the Brick Breaker cartridge.
    static let alert = Color(hex: "#FF6B6B")
    /// Panel surface.
    static let panelTop = Color(hex: "#1C2023")
    static let panelBottom = Color(hex: "#0F1113")
}

extension AnyTransition {
    /// Panels rise slightly and fade in; they fall back and fade out.
    static var overlayPanel: AnyTransition {
        .opacity
            .combined(with: .offset(y: 36))
            .combined(with: .scale(scale: 0.97))
    }
}

/// Dimmed backdrop behind an overlay panel. Tapping it dismisses the panel.
struct OverlayBackdrop: View {
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        // Nearly opaque with Reduce Transparency, so nothing shows through
        Color.black.opacity(reduceTransparency ? 0.92 : 0.62)
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture(perform: onDismiss)
            .accessibilityLabel("Close")
            .accessibilityAddTraits(.isButton)
    }
}

/// A dark, rounded console-accessory panel with a title bar and a close
/// button. Content that doesn't fit vertically scrolls.
struct OverlayPanel<Content: View>: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let onClose: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            header

            Rectangle()
                .fill(Color.white.opacity(0.07))
                .frame(height: 1)

            ViewThatFits(in: .vertical) {
                content
                    .padding(22)
                ScrollView {
                    content
                        .padding(22)
                }
                .scrollIndicators(.hidden)
            }
        }
        .frame(maxWidth: 580)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [RetroPalette.panelTop, RetroPalette.panelBottom],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.16), .white.opacity(0.03)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.6), radius: 30, y: 16)
        .padding(.horizontal, 24)
        .padding(.vertical, 28)
        .avoidingOcclusion()
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape, onClose)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(RetroPalette.phosphor)
                        .frame(width: 7, height: 7)
                        .shadow(color: RetroPalette.phosphor.opacity(0.8), radius: 4)
                    Text(title)
                        .retroFont(20, weight: .black, maxScale: 1.5, wraps: false)
                        .tracking(3)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                Text(subtitle)
                    .retroFont(11, weight: .semibold)
                    .tracking(3)
                    .foregroundStyle(.white.opacity(0.45))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer(minLength: 0)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white.opacity(0.08)))
                    .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
                    .contentShape(Circle())
            }
            .buttonStyle(CartridgePressStyle())
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
    }
}

/// A capsule label used for statuses and small actions in the overlays.
struct RetroCapsuleLabel: View {
    let title: String
    var systemImage: String? = nil
    var tint: Color = .white
    var filled: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .retroFont(11, weight: .heavy, design: .default)
            }
            Text(title)
                .retroFont(12, weight: .heavy)
                .tracking(2)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(filled ? Color.black.opacity(0.85) : tint)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(
            Capsule().fill(filled ? AnyShapeStyle(tint) : AnyShapeStyle(tint.opacity(0.08)))
        )
        .overlay(Capsule().stroke(tint.opacity(filled ? 0 : 0.45), lineWidth: 1))
    }
}

// MARK: - Cards

extension View {
    /// Chrome for a selectable card in an overlay grid (skins, screens).
    func overlayCard(isSelected: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)

        return self
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(shape.fill(Color.white.opacity(isSelected ? 0.07 : 0.035)))
            .overlay(
                shape.stroke(
                    isSelected ? RetroPalette.phosphor : Color.white.opacity(0.08),
                    lineWidth: isSelected ? 2 : 1
                )
            )
            .shadow(color: isSelected ? RetroPalette.phosphor.opacity(0.25) : .clear, radius: 14)
            .contentShape(shape)
    }
}

/// Padlock badge drawn over locked items in the overlays.
struct OverlayLockBadge: View {
    var body: some View {
        Image(systemName: "lock.fill")
            .font(.system(size: 20, weight: .heavy))
            .foregroundStyle(.white)
            .frame(width: 48, height: 48)
            .background(Circle().fill(Color.black.opacity(0.7)))
            .overlay(Circle().stroke(RetroPalette.amber.opacity(0.7), lineWidth: 1.5))
            .shadow(color: .black.opacity(0.5), radius: 6, y: 3)
    }
}

// MARK: - Library overlays

/// Hosts the skin picker, screen settings, records, label designer, store and
/// intro as in-hierarchy overlays.
/// The store stacks above the others, and each backdrop tap closes only the
/// top panel.
struct LibraryOverlays: View {
    @Environment(AppState.self) private var appState
    
    /// When false, both overlays stay hidden, e.g. over a running console.
    var isEnabled: Bool = true
    
    static let animation = Animation.spring(response: 0.38, dampingFraction: 0.86)
    
    var body: some View {
        let showsSkinPicker = isEnabled && appState.isSkinSelectorVisible
        let showsScreenSettings = isEnabled && appState.isScreenSettingsVisible
        let showsRecords = isEnabled && appState.isRecordsVisible
        let showsLabelDesigner = isEnabled && appState.isLabelDesignerVisible
        let showsStore = isEnabled && appState.isStoreVisible
        let showsIntro = isEnabled && appState.isIntroVisible
        
        ZStack {
            if showsSkinPicker {
                OverlayBackdrop { close(\.isSkinSelectorVisible) }
                    .transition(.opacity)
                    .zIndex(10)
                SkinPickerView()
                    .transition(.overlayPanel)
                    .zIndex(11)
            }
            
            if showsScreenSettings {
                OverlayBackdrop { close(\.isScreenSettingsVisible) }
                    .transition(.opacity)
                    .zIndex(10)
                ScreenSettingsView()
                    .transition(.overlayPanel)
                    .zIndex(11)
            }
            
            if showsRecords {
                OverlayBackdrop { close(\.isRecordsVisible) }
                    .transition(.opacity)
                    .zIndex(10)
                RecordsView()
                    .transition(.overlayPanel)
                    .zIndex(11)
            }
            
            if showsLabelDesigner {
                OverlayBackdrop { close(\.isLabelDesignerVisible) }
                    .transition(.opacity)
                    .zIndex(10)
                LabelDesignerView()
                    .transition(.overlayPanel)
                    .zIndex(11)
            }
            
            if showsStore {
                OverlayBackdrop { close(\.isStoreVisible) }
                    .transition(.opacity)
                    .zIndex(12)
                StoreView()
                    .transition(.overlayPanel)
                    .zIndex(13)
            }

            if showsIntro {
                OverlayBackdrop {
                    withAnimation(Self.animation) { appState.finishIntro() }
                }
                .transition(.opacity)
                .zIndex(14)
                IntroView()
                    .transition(.overlayPanel)
                    .zIndex(15)
            }
        }
        .animation(Self.animation, value: showsSkinPicker)
        .animation(Self.animation, value: showsScreenSettings)
        .animation(Self.animation, value: showsRecords)
        .animation(Self.animation, value: showsLabelDesigner)
        .animation(Self.animation, value: showsStore)
        .animation(Self.animation, value: showsIntro)
    }
    
    private func close(_ flag: ReferenceWritableKeyPath<AppState, Bool>) {
        withAnimation(Self.animation) {
            appState[keyPath: flag] = false
        }
    }
}
